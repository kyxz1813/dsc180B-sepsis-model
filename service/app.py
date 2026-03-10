import os
from typing import Any, Dict, List, Optional

import joblib
import pandas as pd
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
import numpy as np

ARTIFACT_DIR = os.getenv("ARTIFACT_DIR", "artifacts")
MODEL_PATH = os.path.join(ARTIFACT_DIR, "sepsis_rf_pipeline.joblib")
COLS_PATH = os.path.join(ARTIFACT_DIR, "feature_cols.joblib")

app = FastAPI(title="Sepsis Early Warning Model", version="1.0.0")

# ---- load artifacts once at startup ----
try:
    model = joblib.load(MODEL_PATH)
except Exception as e:
    raise RuntimeError(f"Failed to load model at {MODEL_PATH}: {e}")

try:
    feature_cols: List[str] = joblib.load(COLS_PATH)
except Exception as e:
    raise RuntimeError(f"Failed to load feature cols at {COLS_PATH}: {e}")


class PredictRequest(BaseModel):
    records: List[Dict[str, Any]] = Field(..., min_length=1)
    return_warnings: bool = False


@app.get("/")
def root():
    return {
        "message": "Sepsis API is running",
        "health": "/health",
        "docs": "/docs",
        "schema": "/schema",
        "predict": "/predict",
    }


@app.get("/health")
def health():
    return {"status": "ok", "n_features": len(feature_cols)}


@app.get("/schema")
def schema():
    # teammates can copy this list to build payloads
    return {"required_columns": feature_cols}


def _coerce_numeric_columns(df: pd.DataFrame) -> pd.DataFrame:
    """
    Convert numeric-looking strings to numbers while keeping categorical cols as strings.
    """
    CAT_COLS = {"gender", "race", "first_careunit", "temperature_site", "intime"}

    for c in df.columns:
        if c not in CAT_COLS:
            df[c] = pd.to_numeric(df[c], errors="coerce")

    return df


@app.post("/predict")
def predict(req: PredictRequest):
    try:
        df_raw = pd.DataFrame(req.records)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid records format: {e}")

    # --- 1) Extract subgroup columns BEFORE reindex drops them ---
    # change these keys if your payload uses different names
    SUBGROUP_KEYS = ["latent_class", "subgroup"]
    subgroup_out = {}
    for k in SUBGROUP_KEYS:
        if k in df_raw.columns:
            # keep as-is (could be str/int/float)
            subgroup_out[k] = df_raw[k].tolist()

    extra_cols = sorted(set(df_raw.columns) - set(feature_cols))
    missing_cols = sorted(set(feature_cols) - set(df_raw.columns))

    # --- 2) Align to model schema ---
    df = df_raw.reindex(columns=feature_cols, fill_value=np.nan)

    # clean dtypes
    df = _coerce_numeric_columns(df)

    try:
        proba = model.predict_proba(df)[:, 1]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Model inference failed: {e}")

    out = {
        "predictions": proba.tolist(),
        "subgroups": subgroup_out,   # <<<<<< add subgroup(s) back
    }

    if getattr(req, "return_warnings", False):
        out["warnings"] = {
            "missing_input_columns_filled_with_nan": missing_cols[:50],
            "extra_input_columns_ignored": extra_cols[:50],
            "missing_count": len(missing_cols),
            "extra_count": len(extra_cols),
            "note": "Missing cols become NaN and are imputed in the pipeline.",
        }

    return out
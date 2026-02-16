-- Materialized View: mv_measurements
-- Purpose: Pre-compute all measurements from chartevents, labevents, and outputevents
-- for the ICD-9 ICU cohort to speed up queries

DROP MATERIALIZED VIEW IF EXISTS mimiciv_derived.mv_measurements CASCADE;

CREATE MATERIALIZED VIEW mimiciv_derived.mv_measurements AS

-- 1. Chartevents (vital signs and ICU charted measurements)
-- Item IDs: 22xxxx (vital signs, blood pressure, etc.)
SELECT
    ce.subject_id,
    ce.hadm_id,
    ce.stay_id,
    ce.charttime,
    ce.itemid,
    ce.valuenum AS value,
    ce.valueuom,
    'chartevents' AS source,
    di.label,
    di.category,
    di.unitname
FROM mimiciv_icu.chartevents ce
INNER JOIN mimiciv_derived.mv_first_icu_stay first_stay
    ON ce.stay_id = first_stay.stay_id
INNER JOIN mimiciv_icu.d_items di
    ON ce.itemid = di.itemid
WHERE ce.valuenum IS NOT NULL
  AND ce.itemid IN (
    -- Vital signs
    220045,  -- Heart Rate
    220179, 220050, 225309,  -- SBP
    220180, 220051, 225310,  -- DBP
    220052, 220181, 225312,  -- MBP
    220210, 224690,  -- Respiratory Rate
    223761, 223762,  -- Temperature
    224642,  -- Temperature Site
    220277,  -- SpO2
    225664, 220621, 226537,  -- Glucose
    -- Vasopressors
    221289,  -- Epinephrine
    221662,  -- Dopamine
    221906,  -- Norepinephrine
    221653   -- Dobutamine
  )

UNION ALL

-- 2. Labevents (lab measurements)
-- Item IDs: 50xxx, 51xxx (coagulation, chemistry, CBC, blood gas, etc.)
SELECT
    le.subject_id,
    le.hadm_id,
    icu.stay_id,
    le.charttime,
    le.itemid,
    le.valuenum AS value,
    le.valueuom,
    'labevents' AS source,
    di.label,
    di.category,
    NULL AS unitname
FROM mimiciv_hosp.labevents le
INNER JOIN mimiciv_derived.mv_first_icu_stay first_stay
    ON le.hadm_id = first_stay.hadm_id
INNER JOIN mimiciv_icu.icustays icu
    ON le.hadm_id = icu.hadm_id
    AND icu.stay_id = first_stay.stay_id
INNER JOIN mimiciv_hosp.d_labitems di
    ON le.itemid = di.itemid
WHERE le.valuenum IS NOT NULL
  AND le.itemid IN (
    -- Coagulation
    51196,  -- D-dimer
    51214,  -- Fibrinogen
    51297,  -- Thrombin
    51237,  -- INR
    51274,  -- PT
    51275,  -- PTT
    -- Chemistry
    50912,  -- Creatinine
    -- Enzymes
    50885,  -- Bilirubin Total
    50883,  -- Bilirubin Direct
    50884,  -- Bilirubin Indirect
    -- Complete Blood Count
    51300,  -- WBC
    51256,  -- Neutrophils
    51144,  -- Bands
    51244,  -- Lymphocytes
    51265,  -- Platelet
    -- Blood Gas
    50820,  -- pH
    50818,  -- PCO2
    50821,  -- PO2
    50802,  -- Base Excess
    50803   -- Bicarbonate
  )

UNION ALL

-- 3. Outputevents (urine output)
-- Item IDs: 226xxx, 227xxx
SELECT
    oe.subject_id,
    oe.hadm_id,
    oe.stay_id,
    oe.charttime,
    oe.itemid,
    oe.value::numeric AS value,
    oe.valueuom,
    'outputevents' AS source,
    di.label,
    di.category,
    di.unitname
FROM mimiciv_icu.outputevents oe
INNER JOIN mimiciv_derived.mv_first_icu_stay first_stay
    ON oe.stay_id = first_stay.stay_id
INNER JOIN mimiciv_icu.d_items di
    ON oe.itemid = di.itemid
WHERE oe.value IS NOT NULL
  AND oe.itemid IN (
    226559,  -- Foley
    226560,  -- Void
    226561,  -- Condom Cath
    226584,  -- Ileoconduit
    226563,  -- Suprapubic
    226564,  -- R Nephrostomy
    226565,  -- L Nephrostomy
    226567,  -- Straight Cath
    226557,  -- R Ureteral Stent
    226558,  -- L Ureteral Stent
    227488,  -- GU Irrigant Volume In (negative)
    227489   -- GU Irrigant / Urine Volume Out
  );

-- Create indexes for faster queries
CREATE INDEX idx_mv_measurements_stay_id ON mimiciv_derived.mv_measurements (stay_id);
CREATE INDEX idx_mv_measurements_hadm_id ON mimiciv_derived.mv_measurements (hadm_id);
CREATE INDEX idx_mv_measurements_itemid ON mimiciv_derived.mv_measurements (itemid);
CREATE INDEX idx_mv_measurements_charttime ON mimiciv_derived.mv_measurements (charttime);
CREATE INDEX idx_mv_measurements_source ON mimiciv_derived.mv_measurements (source);

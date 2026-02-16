# DSC180B Sepsis Prediction Model

This repository contains the code and data processing pipelines for the sepsis early warning model built for **UCSD DSC180B**.  
The goal is to predict sepsis onset within a forward-looking window at the ICU-hour level using routinely collected ICU vitals.

---

## Project Overview

Early detection of sepsis can significantly improve outcomes in critical care. This project builds a machine learning classifier that:

- Predicts whether a patient will develop sepsis within the next 1–4 hours
- Uses hourly aggregated vital sign measurements
- Models the task at the ICU-hour level
- Ensures no information leakage by splitting data at the ICU stay level

We use a **Random Forest** classifier as a strong baseline for clinical tabular data, handling non-linear patterns and moderate missingness.

---

### 1. Data Sources and Cohort Construction

We derive two main tables:

1. **Stay-level table**  
   Contains:
   - `subject_id`, `hadm_id`, `stay_id`
   - Sepsis label and onset timestamps

2. **Vitals table (long format)**  
   Hourly vital measurements aligned by:
   ```python
   (subject_id, hadm_id, stay_id, hour)

---
2. Feature Engineering

Vitals are aggregated per hour using:

Mean

Min / Max

Standard deviation

Count

Median

Each feature is named:

{concept}__{stat}


For example:

HeartRate__mean
SBP__min


The final modeling table merges:

Hourly skeleton

Stay-level metadata

Pivoted vitals feature matrix

--- 

## 3. Label Definition

At hour `t0`, the model predicts whether sepsis onset will occur within the next **1–4 hours**.

### Time Definition

t0 = intime + hour

### Onset Timestamp Selection

The sepsis onset time is selected using:

- `sofa_time` (if available)
- Otherwise `suspected_infection_time`

### Binary Label

The label is defined as:

1 if sepsis == 1 AND onset_time ∈ (t0, t0 + 4 hours]
0 otherwise


In other words, a positive label indicates that sepsis onset occurs strictly after the current hour and within the next 4 hours.

### Leakage Prevention

To prevent information leakage:

- All rows at or after the onset time are removed.
- The model only uses information available prior to sepsis onset.

---

## 4. Model and Training

We train a machine learning pipeline:

MedianImputer → RandomForestClassifier


### Hyperparameters

- Number of trees: `500`
- Minimum leaf size: `5`
- Class imbalance handling: `class_weight="balanced_subsample"`

The model is trained using only features available up to time `t0`, ensuring a strictly forward-looking prediction setup.



-- Materialized View: mv_management_view_data
-- Purpose: Provides management-level patient data for the Unit Overview/Triage board
-- Joins ICU cohort data with detailed ICU stay information
DROP MATERIALIZED VIEW IF EXISTS mimiciv_derived.mv_management_view_data CASCADE;
CREATE MATERIALIZED VIEW mimiciv_derived.mv_management_view_data AS
SELECT DISTINCT
  -- identifiers (for linking/navigation, not all shown in UI)
  id.subject_id,
  id.hadm_id,
  id.stay_id,

  -- demographics
  id.gender,
  id.admission_age,
  id.race,

  -- ICU timing
  id.icu_intime,
  id.icu_outtime,
  id.los_icu,

  -- outcome flag (optional; can hide in UI)
  id.hospital_expire_flag

FROM mimiciv_derived.mv_icd9_icu_cohort_data i
INNER JOIN mimiciv_derived.icustay_detail id
  ON id.subject_id = i.subject_id;

-- Create index for faster lookups
CREATE INDEX idx_mv_management_subject_id ON mimiciv_derived.mv_management_view_data (subject_id);
CREATE INDEX idx_mv_management_stay_id ON mimiciv_derived.mv_management_view_data (stay_id);

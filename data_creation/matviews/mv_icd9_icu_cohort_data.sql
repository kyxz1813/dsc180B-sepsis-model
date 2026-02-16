DROP MATERIALIZED VIEW IF EXISTS mimiciv_derived.mv_icd9_icu_cohort_data CASCADE;
CREATE MATERIALIZED VIEW mimiciv_derived.mv_icd9_icu_cohort_data AS
SELECT
    diag.subject_id,
    diag.hadm_id,
    first_stay.stay_id,
    diag.seq_num,
    diag.icd_code,
    diag.icd_version,
    dict.long_title,
    adm.admittime,
    adm.dischtime,
    adm.hospital_expire_flag
FROM mimiciv_hosp.diagnoses_icd diag
JOIN mimiciv_derived.mv_icd9_patients p_filter
    ON diag.subject_id = p_filter.subject_id
JOIN mimiciv_derived.mv_first_icu_stay first_stay
    ON diag.hadm_id = first_stay.hadm_id
LEFT JOIN mimiciv_hosp.d_icd_diagnoses dict
    ON diag.icd_code = dict.icd_code
    AND diag.icd_version = dict.icd_version
LEFT JOIN mimiciv_hosp.admissions adm
    ON diag.hadm_id = adm.hadm_id;

CREATE INDEX idx_mv_final_hadm ON mimiciv_derived.mv_icd9_icu_cohort_data (hadm_id);
CREATE INDEX idx_mv_final_icd ON mimiciv_derived.mv_icd9_icu_cohort_data (icd_code);
CREATE INDEX idx_mv_final_subject ON mimiciv_derived.mv_icd9_icu_cohort_data (subject_id);
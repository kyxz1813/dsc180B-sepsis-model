
DROP MATERIALIZED VIEW IF EXISTS mimiciv_derived.mv_icd9_patients CASCADE;

CREATE MATERIALIZED VIEW mimiciv_derived.mv_icd9_patients AS
SELECT subject_id
FROM mimiciv_hosp.diagnoses_icd
GROUP BY subject_id
HAVING max(icd_version) = 9;

CREATE UNIQUE INDEX idx_mv_icd9_patients_subject 
ON mimiciv_derived.mv_icd9_patients (subject_id);
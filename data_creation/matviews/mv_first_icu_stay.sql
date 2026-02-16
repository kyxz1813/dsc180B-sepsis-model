DROP MATERIALIZED VIEW IF EXISTS mimiciv_derived.mv_first_icu_stay CASCADE;
CREATE MATERIALIZED VIEW mimiciv_derived.mv_first_icu_stay AS
SELECT subject_id, hadm_id, stay_id
FROM mimiciv_derived.icustay_detail
WHERE first_hosp_stay = 't'
  AND first_icu_stay = 't';
CREATE UNIQUE INDEX idx_mv_first_icu_stay_stay ON mimiciv_derived.mv_first_icu_stay(subject_id);
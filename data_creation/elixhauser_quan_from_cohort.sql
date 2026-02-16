-- =====================================================================
-- Elixhauser Comorbidities (Quan ICD-9 enhanced coding)
-- Adapted to read from: mimiciv_derived.mv_icd9_icu_cohort_data
--
-- INPUT TABLE REQUIREMENTS (must exist):
--   mimiciv_derived.mv_icd9_icu_cohort_data with columns:
--     hadm_id, seq_num, icd_code, icd_version
--
-- OUTPUT:
--   public.elixhauser_quan  (one row per hadm_id in the input table)
--
-- Notes:
--  * This is ICD-9 logic (Quan/Elixhauser). We filter icd_version = 9.
--  * We exclude primary diagnosis: seq_num != 1 (matches original script).
-- =====================================================================

DROP TABLE IF EXISTS public.elixhauser_quan;

CREATE TABLE public.elixhauser_quan AS
WITH eliflg AS
(
  SELECT
      icd.hadm_id
    , icd.seq_num
    , icd.icd_code AS icd9_code

    , CASE
        WHEN icd.icd_code IN ('39891','40201','40211','40291','40401','40403','40411','40413','40491','40493') THEN 1
        WHEN SUBSTR(icd.icd_code, 1, 4) IN ('4254','4255','4257','4258','4259') THEN 1
        WHEN SUBSTR(icd.icd_code, 1, 3) IN ('428') THEN 1
        ELSE 0
      END AS chf       /* Congestive heart failure */

    , CASE
        WHEN icd.icd_code IN ('42613','42610','42612','99601','99604') THEN 1
        WHEN SUBSTR(icd.icd_code, 1, 4) IN ('4260','4267','4269','4270','4271','4272','4273','4274','4276','4278','4279','7850','V450','V533') THEN 1
        ELSE 0
      END AS arrhy     /* Cardiac arrhythmias */

    , CASE
        WHEN SUBSTR(icd.icd_code, 1, 4) IN ('0932','7463','7464','7465','7466','V422','V433') THEN 1
        WHEN SUBSTR(icd.icd_code, 1, 3) IN ('394','395','396','397','424') THEN 1
        ELSE 0
      END AS valve     /* Valvular disease */

    , CASE
        WHEN SUBSTR(icd.icd_code, 1, 4) IN ('4150','4151','4170','4178','4179') THEN 1
        WHEN SUBSTR(icd.icd_code, 1, 3) IN ('416') THEN 1
        ELSE 0
      END AS pulmcirc  /* Pulmonary circulation disorder */

    , CASE
        WHEN SUBSTR(icd.icd_code, 1, 4) IN ('0930','4373','4431','4432','4438','4439','4471','5571','5579','V434') THEN 1
        WHEN SUBSTR(icd.icd_code, 1, 3) IN ('440','441') THEN 1
        ELSE 0
      END AS perivasc  /* Peripheral vascular disorder */

    , CASE
        WHEN SUBSTR(icd.icd_code, 1, 3) IN ('401') THEN 1
        ELSE 0
      END AS htn       /* Hypertension, uncomplicated */

    , CASE
        WHEN SUBSTR(icd.icd_code, 1, 3) IN ('402','403','404','405') THEN 1
        ELSE 0
      END AS htncx     /* Hypertension, complicated */

    , CASE
        WHEN SUBSTR(icd.icd_code, 1, 4) IN ('3341','3440','3441','3442','3443','3444','3445','3446','3449') THEN 1
        WHEN SUBSTR(icd.icd_code, 1, 3) IN ('342','343') THEN 1
        ELSE 0
      END AS para      /* Paralysis */

    , CASE
        WHEN icd.icd_code IN ('33392') THEN 1
        WHEN SUBSTR(icd.icd_code, 1, 4) IN ('3319','3320','3321','3334','3335','3362','3481','3483','7803','7843') THEN 1
        WHEN SUBSTR(icd.icd_code, 1, 3) IN ('334','335','340','341','345') THEN 1
        ELSE 0
      END AS neuro     /* Other neurological */

    , CASE
        WHEN SUBSTR(icd.icd_code, 1, 4) IN ('4168','4169','5064','5081','5088') THEN 1
        WHEN SUBSTR(icd.icd_code, 1, 3) IN ('490','491','492','493','494','495','496','500','501','502','503','504','505') THEN 1
        ELSE 0
      END AS chrnlung  /* Chronic pulmonary disease */

    , CASE
        WHEN SUBSTR(icd.icd_code, 1, 4) IN ('2500','2501','2502','2503') THEN 1
        ELSE 0
      END AS dm        /* Diabetes w/o chronic complications */

    , CASE
        WHEN SUBSTR(icd.icd_code, 1, 4) IN ('2504','2505','2506','2507','2508','2509') THEN 1
        ELSE 0
      END AS dmcx      /* Diabetes w/ chronic complications */

    , CASE
        WHEN SUBSTR(icd.icd_code, 1, 4) IN ('2409','2461','2468') THEN 1
        WHEN SUBSTR(icd.icd_code, 1, 3) IN ('243','244') THEN 1
        ELSE 0
      END AS hypothy   /* Hypothyroidism */

    , CASE
        WHEN icd.icd_code IN ('40301','40311','40391','40402','40403','40412','40413','40492','40493') THEN 1
        WHEN SUBSTR(icd.icd_code, 1, 4) IN ('5880','V420','V451') THEN 1
        WHEN SUBSTR(icd.icd_code, 1, 3) IN ('585','586','V56') THEN 1
        ELSE 0
      END AS renlfail  /* Renal failure */

    , CASE
        WHEN icd.icd_code IN ('07022','07023','07032','07033','07044','07054') THEN 1
        WHEN SUBSTR(icd.icd_code, 1, 4) IN ('0706','0709','4560','4561','4562','5722','5723','5724','5728','5733','5734','5738','5739','V427') THEN 1
        WHEN SUBSTR(icd.icd_code, 1, 3) IN ('570','571') THEN 1
        ELSE 0
      END AS liver     /* Liver disease */

    , CASE
        WHEN SUBSTR(icd.icd_code, 1, 4) IN ('5317','5319','5327','5329','5337','5339','5347','5349') THEN 1
        ELSE 0
      END AS ulcer     /* Chronic peptic ulcer disease */

    , CASE
        WHEN SUBSTR(icd.icd_code, 1, 3) IN ('042','043','044') THEN 1
        ELSE 0
      END AS aids      /* HIV and AIDS */

    , CASE
        WHEN SUBSTR(icd.icd_code, 1, 4) IN ('2030','2386') THEN 1
        WHEN SUBSTR(icd.icd_code, 1, 3) IN ('200','201','202') THEN 1
        ELSE 0
      END AS lymph     /* Lymphoma */

    , CASE
        WHEN SUBSTR(icd.icd_code, 1, 3) IN ('196','197','198','199') THEN 1
        ELSE 0
      END AS mets      /* Metastatic cancer */

    , CASE
        WHEN SUBSTR(icd.icd_code, 1, 3) IN
        (
           '140','141','142','143','144','145','146','147','148','149','150','151','152'
          ,'153','154','155','156','157','158','159','160','161','162','163','164','165'
          ,'166','167','168','169','170','171','172','174','175','176','177','178','179'
          ,'180','181','182','183','184','185','186','187','188','189','190','191','192'
          ,'193','194','195'
        ) THEN 1
        ELSE 0
      END AS tumor     /* Solid tumor without metastasis */

    , CASE
        WHEN icd.icd_code IN ('72889','72930') THEN 1
        WHEN SUBSTR(icd.icd_code, 1, 4) IN ('7010','7100','7101','7102','7103','7104','7108','7109','7112','7193','7285') THEN 1
        WHEN SUBSTR(icd.icd_code, 1, 3) IN ('446','714','720','725') THEN 1
        ELSE 0
      END AS arth      /* Rheumatoid arthritis/collagen vascular diseases */

    , CASE
        WHEN SUBSTR(icd.icd_code, 1, 4) IN ('2871','2873','2874','2875') THEN 1
        WHEN SUBSTR(icd.icd_code, 1, 3) IN ('286') THEN 1
        ELSE 0
      END AS coag      /* Coagulation deficiency */

    , CASE
        WHEN SUBSTR(icd.icd_code, 1, 4) IN ('2780') THEN 1
        ELSE 0
      END AS obese     /* Obesity */

    , CASE
        WHEN SUBSTR(icd.icd_code, 1, 4) IN ('7832','7994') THEN 1
        WHEN SUBSTR(icd.icd_code, 1, 3) IN ('260','261','262','263') THEN 1
        ELSE 0
      END AS wghtloss  /* Weight loss */

    , CASE
        WHEN SUBSTR(icd.icd_code, 1, 4) IN ('2536') THEN 1
        WHEN SUBSTR(icd.icd_code, 1, 3) IN ('276') THEN 1
        ELSE 0
      END AS lytes     /* Fluid and electrolyte disorders */

    , CASE
        WHEN SUBSTR(icd.icd_code, 1, 4) IN ('2800') THEN 1
        ELSE 0
      END AS bldloss   /* Blood loss anemia */

    , CASE
        WHEN SUBSTR(icd.icd_code, 1, 4) IN ('2801','2808','2809') THEN 1
        WHEN SUBSTR(icd.icd_code, 1, 3) IN ('281') THEN 1
        ELSE 0
      END AS anemdef   /* Deficiency anemias */

    , CASE
        WHEN SUBSTR(icd.icd_code, 1, 4) IN ('2652','2911','2912','2913','2915','2918','2919','3030','3039','3050','3575','4255','5353','5710','5711','5712','5713','V113') THEN 1
        WHEN SUBSTR(icd.icd_code, 1, 3) IN ('980') THEN 1
        ELSE 0
      END AS alcohol   /* Alcohol abuse */

    , CASE
        WHEN icd.icd_code IN ('V6542') THEN 1
        WHEN SUBSTR(icd.icd_code, 1, 4) IN ('3052','3053','3054','3055','3056','3057','3058','3059') THEN 1
        WHEN SUBSTR(icd.icd_code, 1, 3) IN ('292','304') THEN 1
        ELSE 0
      END AS drug      /* Drug abuse */

    , CASE
        WHEN icd.icd_code IN ('29604','29614','29644','29654') THEN 1
        WHEN SUBSTR(icd.icd_code, 1, 4) IN ('2938') THEN 1
        WHEN SUBSTR(icd.icd_code, 1, 3) IN ('295','297','298') THEN 1
        ELSE 0
      END AS psych     /* Psychoses */

    , CASE
        WHEN SUBSTR(icd.icd_code, 1, 4) IN ('2962','2963','2965','3004') THEN 1
        WHEN SUBSTR(icd.icd_code, 1, 3) IN ('309','311') THEN 1
        ELSE 0
      END AS depress   /* Depression */

  FROM mimiciv_derived.mv_icd9_icu_cohort_data icd
  WHERE icd.seq_num != 1
    AND icd.icd_version = 9
    AND icd.icd_code IS NOT NULL
)
-- Collapse ICD9-code flags into hadm_id-level flags
, eligrp AS
(
  SELECT
      hadm_id
    , MAX(chf)      AS chf
    , MAX(arrhy)    AS arrhy
    , MAX(valve)    AS valve
    , MAX(pulmcirc) AS pulmcirc
    , MAX(perivasc) AS perivasc
    , MAX(htn)      AS htn
    , MAX(htncx)    AS htncx
    , MAX(para)     AS para
    , MAX(neuro)    AS neuro
    , MAX(chrnlung) AS chrnlung
    , MAX(dm)       AS dm
    , MAX(dmcx)     AS dmcx
    , MAX(hypothy)  AS hypothy
    , MAX(renlfail) AS renlfail
    , MAX(liver)    AS liver
    , MAX(ulcer)    AS ulcer
    , MAX(aids)     AS aids
    , MAX(lymph)    AS lymph
    , MAX(mets)     AS mets
    , MAX(tumor)    AS tumor
    , MAX(arth)     AS arth
    , MAX(coag)     AS coag
    , MAX(obese)    AS obese
    , MAX(wghtloss) AS wghtloss
    , MAX(lytes)    AS lytes
    , MAX(bldloss)  AS bldloss
    , MAX(anemdef)  AS anemdef
    , MAX(alcohol)  AS alcohol
    , MAX(drug)     AS drug
    , MAX(psych)    AS psych
    , MAX(depress)  AS depress
  FROM eliflg
  GROUP BY hadm_id
)
-- Build an "admissions-like" set from the input table so this script is self-contained
, hadm_universe AS
(
  SELECT DISTINCT hadm_id
  FROM mimiciv_derived.mv_icd9_icu_cohort_data
  WHERE hadm_id IS NOT NULL
)
SELECT
    adm.hadm_id
  , COALESCE(chf,0)      AS congestive_heart_failure
  , COALESCE(arrhy,0)    AS cardiac_arrhythmias
  , COALESCE(valve,0)    AS valvular_disease
  , COALESCE(pulmcirc,0) AS pulmonary_circulation
  , COALESCE(perivasc,0) AS peripheral_vascular

  -- Combine uncomplicated/complicated HTN into one "hypertension"
  , CASE
      WHEN COALESCE(htn,0) = 1 THEN 1
      WHEN COALESCE(htncx,0) = 1 THEN 1
      ELSE 0
    END AS hypertension

  , COALESCE(para,0)     AS paralysis
  , COALESCE(neuro,0)    AS other_neurological
  , COALESCE(chrnlung,0) AS chronic_pulmonary

  -- Only keep uncomplicated diabetes if complicated is not present
  , CASE
      WHEN COALESCE(dmcx,0) = 1 THEN 0
      WHEN COALESCE(dm,0) = 1 THEN 1
      ELSE 0
    END AS diabetes_uncomplicated
  , COALESCE(dmcx,0)     AS diabetes_complicated

  , COALESCE(hypothy,0)  AS hypothyroidism
  , COALESCE(renlfail,0) AS renal_failure
  , COALESCE(liver,0)    AS liver_disease
  , COALESCE(ulcer,0)    AS peptic_ulcer
  , COALESCE(aids,0)     AS aids
  , COALESCE(lymph,0)    AS lymphoma
  , COALESCE(mets,0)     AS metastatic_cancer

  -- Only keep solid tumor if metastatic cancer is not present
  , CASE
      WHEN COALESCE(mets,0) = 1 THEN 0
      WHEN COALESCE(tumor,0) = 1 THEN 1
      ELSE 0
    END AS solid_tumor

  , COALESCE(arth,0)     AS rheumatoid_arthritis
  , COALESCE(coag,0)     AS coagulopathy
  , COALESCE(obese,0)    AS obesity
  , COALESCE(wghtloss,0) AS weight_loss
  , COALESCE(lytes,0)    AS fluid_electrolyte
  , COALESCE(bldloss,0)  AS blood_loss_anemia
  , COALESCE(anemdef,0)  AS deficiency_anemias
  , COALESCE(alcohol,0)  AS alcohol_abuse
  , COALESCE(drug,0)     AS drug_abuse
  , COALESCE(psych,0)    AS psychoses
  , COALESCE(depress,0)  AS depression

FROM hadm_universe adm
LEFT JOIN eligrp eli
  ON adm.hadm_id = eli.hadm_id
ORDER BY adm.hadm_id;

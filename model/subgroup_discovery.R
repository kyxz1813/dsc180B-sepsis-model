# =========================================
# LCA on MIMIC-IV (Zador replication-style)
# =========================================

# Packages
pkgs <- c("tidyverse", "poLCA")
to_install <- setdiff(pkgs, rownames(installed.packages()))
if (length(to_install)) install.packages(to_install)
invisible(lapply(pkgs, library, character.only = TRUE))

# ---- Load data ----
df <- read.csv(
  "/Users/samuelmahjouri/Desktop/MAHJOURI-FAM/ME/WORK_SCHOOL_MUSIC/SCHOOL/DSC/DSC_180B/lca_input_6class.csv",
  check.names = FALSE
)

# ---- Basic checks ----
stopifnot(!anyDuplicated(df$hadm_id))
stopifnot(all(df$elective_flag %in% c(0, 1)))

# Ensure age_grp is categorical (poLCA wants integers starting at 1)
df <- df %>%
  mutate(
    age_grp = factor(age_grp, levels = c("18-39","40-59","60-79","80+")),
    age_grp_num = as.integer(age_grp),       # 1..4
    elective_num = elective_flag + 1L        # 1..2
  )

# Identify comorbidity columns (0/1)
comorb_cols <- c(
  "congestive_heart_failure","cardiac_arrhythmias","valvular_disease","pulmonary_circulation",
  "peripheral_vascular","hypertension","paralysis","other_neurological","chronic_pulmonary",
  "diabetes_uncomplicated","diabetes_complicated","hypothyroidism","renal_failure","liver_disease",
  "peptic_ulcer","aids","lymphoma","metastatic_cancer","solid_tumor","rheumatoid_arthritis",
  "coagulopathy","obesity","weight_loss","fluid_electrolyte","blood_loss_anemia",
  "deficiency_anemias","alcohol_abuse","drug_abuse","psychoses","depression"
)

# Convert 0/1 -> 1/2 for poLCA manifest variables
df[comorb_cols] <- lapply(df[comorb_cols], function(x) as.integer(x) + 1L)

# ---- LCA formula ----
# Manifest vars: age_grp_num + elective_num + comorbidities
manifest_vars <- c("age_grp_num", "elective_num", comorb_cols)
f <- as.formula(paste0("cbind(", paste(manifest_vars, collapse = ","), ") ~ 1"))
print(f)

# ---- Fit K=6 (with multiple random starts) ----
set.seed(180)
K <- 6
nrep <- 50
maxiter <- 5000

lca_fit <- poLCA(
  f,
  data = df,
  nclass = K,
  nrep = nrep,
  maxiter = maxiter,
  verbose = TRUE,
  calc.se = TRUE
)

saveRDS(lca_fit,
        "/Users/samuelmahjouri/Desktop/MAHJOURI-FAM/ME/WORK_SCHOOL_MUSIC/SCHOOL/DSC/DSC_180B/lca_fit_k6.rds"
)

# ---- Add outputs back to df ----
df$out_class <- lca_fit$predclass
# posterior class probs: columns correspond to classes 1..K
post <- as.data.frame(lca_fit$posterior)
colnames(post) <- paste0("p_class", 1:K)

out <- bind_cols(
  df %>% select(hadm_id, sex, age_grp, elective_flag),
  post,
  tibble(latent_class = df$out_class)
)

write.csv(
  out,
  "/Users/samuelmahjouri/Desktop/MAHJOURI-FAM/ME/WORK_SCHOOL_MUSIC/SCHOOL/DSC/DSC_180B/lca_membership_k6.csv",
  row.names = FALSE
)

# ---- Quick class sizes ----
print(table(out$latent_class))

# ---- Quick comorbidity prevalence by class (for labeling) ----
# Convert back to 0/1 for interpretability
df01 <- df
df01[comorb_cols] <- lapply(df01[comorb_cols], function(x) x - 1L)

class_prev <- df01 %>%
  mutate(latent_class = out$latent_class) %>%
  group_by(latent_class) %>%
  summarise(across(all_of(comorb_cols), mean), .groups = "drop")

print(class_prev)

Ks <- 4:8
results <- data.frame(
  K = integer(),
  logLik = numeric(),
  AIC = numeric(),
  BIC = numeric(),
  min_class_prop = numeric()
)

set.seed(180)

for (K in Ks) {
  fit <- poLCA(
    f,
    data = df,
    nclass = K,
    nrep = 20,        # fewer reps is fine for comparison
    maxiter = 3000,
    verbose = FALSE
  )
  
  class_props <- fit$P
  
  results <- rbind(
    results,
    data.frame(
      K = K,
      logLik = fit$llik,
      AIC = fit$aic,
      BIC = fit$bic,
      min_class_prop = min(class_props)
    )
  )
}

results


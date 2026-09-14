#!/usr/bin/env Rscript
# Seed tools/homes.csv: the home chapter of every row in tools/features.csv,
# following PLAN.md §5. Rows already present in homes.csv keep their (possibly
# hand-edited) home; only new rows get a rule-based home. Rows no rule matches
# get home "" and are reported, so nothing is silently dropped.
#
# Usage: Rscript tools/assign-homes.R

features <- read.csv("tools/features.csv", stringsAsFactors = FALSE)

ch <- c(
  "index", "01-installation", "02-complete-analysis", "03-data", "04-model-files",
  "05-first-fit", "06-estimation-methods", "07-diagnostics", "08-vpc",
  "09-model-selection", "10-uncertainty", "11-simulation", "12-tables-figures",
  "13-reproducibility", "14-structural-models", "15-absorption", "16-variability",
  "17-covariates", "18-dosing", "19-censoring", "20-pkpd", "21-binary",
  "22-time-to-event", "23-adaptive-dosing", "24-experimental", "25-reference"
)
home_of <- function(n) { h <- ch[startsWith(ch, sprintf("%02d-", n))]; stopifnot(length(h) == 1); h }

export_home <- c(
  ferx_example = 2,
  ferx_get_columns = 3, ferx_apply_selection = 3,
  ferx_model = 4, ferx_model_edit = 4, ferx_model_show = 4, ferx_model_inspect = 4,
  ferx_model_validate = 4, ferx_model_get_section = 4, ferx_model_set_section = 4,
  ferx_inits_from_nca = 5, ferx_check_init = 5, ferx_fit = 5, ferx_coef = 5, ferx_se = 5,
  ferx_get_warnings = 5, check_diagnostics = 5,
  ferx_fit_async = 6, ferx_collect = 6, ferx_stop = 6, ferx_trace = 6, ferx_runlog = 6,
  ferx_runlog_iters = 6, ferx_conddist = 6,
  ferx_calc_npde = 7, ferx_xpose = 7,
  ferx_simulate = 8,
  ferx_bic = 9, check_strictness = 9, ferx_search_config = 9, ferx_search_space = 9,
  ferx_search_coverage = 9, ferx_search_results = 9, ferx_modelsearch = 9,
  ferx_covsearch = 9, ferx_ruvsearch = 9, ferx_globalsearch = 9,
  ferx_covariance = 10, ferx_sir = 10, ferx_bootstrap = 10, ferx_bootstrap_summarize = 10,
  ferx_predict = 11, ferx_simulate_with_uncertainty = 11,
  ferx_save_fit = 13, ferx_load_fit = 13,
  ferx_cov_screen = 17, ferx_gam_screen = 17, ferx_allometry = 17, ferx_model_to_frem = 17,
  ferx_predict_survival = 22,
  ferx_simulate_adaptive = 23
)

# ferx_fit / ferx_simulate arguments that belong with a topic, not the parent.
argument_home <- c(
  "ferx_fit:bloq_method" = 19, "ferx_fit:threads" = 6, "ferx_fit:mu_referencing" = 16,
  "ferx_fit:scale_params" = 16, "ferx_fit:sir" = 10, "ferx_fit:gradient" = 6,
  "ferx_fit:optimizer_trace" = 6, "ferx_fit:fd_hessian_step" = 10, "ferx_fit:settings" = 6,
  "ferx_fit:output" = 13, "ferx_fit:include_data" = 13, "ferx_fit:ignore" = 3,
  "ferx_fit:accept" = 3, "ferx_fit:ignore_ids" = 3, "ferx_fit:method" = 6,
  "ferx_simulate:horizon" = 22, "ferx_simulate:match" = 11
)

s3_class_home <- c(
  ferx_job = 6, ferx_bootstrap = 10, ferx_allometry = 17, ferx_conddist = 6,
  ferx_covsearch = 9, ferx_modelsearch = 9, ferx_ruvsearch = 9, ferx_data = 3,
  ferx_globalsearch = 9, ferx_inits = 5, ferx_model = 4,
  ferx_search_config = 9, ferx_search_space = 9,
  ferx_summary = 5
)

setting_home <- function(k) {
  if (grepl("^ode_", k)) return(14)
  if (grepl("^(sir_|covariance_|analytic_cov_hessian$|cov_inner_tol$|fd_hessian_step$)", k)) return(10)
  if (grepl("^(iov_)", k)) return(16)
  if (k %in% c("mu_referencing", "scale_params", "parameter_scaling")) return(16)
  if (grepl("^npde_", k)) return(7)
  if (grepl("^frem_", k)) return(17)
  if (grepl("^nn_", k)) return(24)
  if (k %in% c("ignore", "accept", "ignore_subjects")) return(3)
  if (k %in% c("inits_from_nca")) return(5)
  if (grepl("^vi_", k)) return(25)  # vi method is not accepted by ferx_fit() (PLAN §3)
  6  # run control, optimizers, inner loop, multistart, SAEM, IMP/IMPMAP, Bayes, AGQ, GN
}

block_home <- c(
  parameters = 4, individual_parameters = 4, structural_model = 4, error_model = 4,
  fit_options = 4, data = 3, data_selection = 3, odes = 14, initial_conditions = 14,
  scaling = 14, covariates = 17, covariate_model = 17, covariate_nn = 24, diffusion = 24,
  derived = 12, output = 12, event_model = 22, binary_model = 21, adaptive_dosing = 23,
  simulation = 11, mixture = 16, markov_model = 25
)

example_home <- c(
  warfarin = 2, two_cpt_oral_cov = 3, warfarin_data_selection = 3, two_cpt_oral_base = 4,
  warfarin_saem = 6, mm_multistart = 6, two_cpt_oral_derived = 12,
  setNames(rep(14, 15), c("one_cpt_iv", "one_cpt_iv_ode", "two_cpt_iv", "two_cpt_iv_ode",
    "three_cpt_iv", "three_cpt_iv_ode", "three_cpt_oral", "three_cpt_oral_ode", "warfarin_ode",
    "two_cpt_oral_cov_ode", "two_cpt_oral_cov_ode_template", "warfarin_ode_time", "mm_oral",
    "one_cpt_iv_pooled", "warfarin_scaled")),
  setNames(rep(15, 18), c("warfarin_ode_lagtime", "per_route_lag_absorption", "transit_savic",
    "transit_2cpt", "one_cpt_transit", "two_cpt_transit", "igd_inverse_gaussian", "one_cpt_ig",
    "two_cpt_ig", "biphasic_igd_absorption", "weibull_absorption", "zero_order_absorption",
    "parallel_absorption", "mixed_absorption", "sequential_absorption", "bioavailability",
    "bioavailability_ode", "warfarin_logit_f")),
  setNames(rep(16, 6), c("warfarin_block_omega", "warfarin_additive_eta", "warfarin_ltbs",
    "warfarin_iov", "warfarin_iov_saem", "one_cpt_transit_iov")),
  warfarin_if = 17, two_cpt_oral_global = 9,
  setNames(rep(18, 5), c("warfarin_ss", "warfarin_addl", "ss_absorption", "infusion_absorption",
    "warfarin_derived")),
  warfarin_bloq = 19,
  emax_pkpd = 20, emax_timecourse = 20, warfarin_derived_pkpd = 20,
  binary_logistic = 21,
  setNames(rep(22, 5), c("tte_exponential", "tte_weibull", "tte_gompertz", "tte_competing_risks",
    "pktte_joint")),
  adaptive_tdm = 23, adaptive_vanco_loading = 23,
  warfarin_sde = 24, warfarin_dcm = 24
)

column_home <- c(TENTRY = 22, FREMTYPE = 17)

# Fit warning categories (ferx-core docs/warnings.qmd groups) -> the chapter whose
# "Warnings you may see here" list explains them.
warning_home <- c(
  convergence = 5, general = 5,
  optimizer_health = 6, gradient_fallback = 6, mu_referencing = 6, optimizer_config = 6,
  multi_start = 6, cancelled = 6, threads = 6, flat_parameter = 6, init_outside_bounds = 6,
  parameter_at_runaway_guard = 6, importance_sampling = 6,
  dw_autocorrelation = 7, eta_normality = 7, eps_shrinkage = 7, eta_shrinkage = 7,
  boundary_estimate = 7, inflated_rse = 7, high_correlation = 7, condition_number = 7,
  covariance_step = 10, covariance_failed = 10, covariance_regularized = 10, sir = 10,
  data_quality = 3, ode_solver = 14, flip_flop = 15, absorption_twin_declined = 15,
  omega_structure = 16, bloq_method = 19, simulation = 22, experimental = 24,
  vi_bad_basin = 25  # vi is not accepted by ferx_fit() (PLAN §3)
)

rule <- function(kind, name, parent, detail) {
  n <- switch(kind,
    export = export_home[name],
    argument = {
      key <- paste0(parent, ":", name)
      if (key %in% names(argument_home)) argument_home[key] else export_home[parent]
    },
    s3method = if (detail == "ferx_fit") c(plot = 6, print = 5, summary = 5)[parent] else s3_class_home[detail],
    setting = setting_home(name),
    dsl_block = block_home[name],
    data_column = if (name %in% names(column_home)) column_home[name] else 3,
    example = example_home[name],
    searchfile = 9,
    warning_code = warning_home[name],
    fit_slot = 25,
    NA
  )
  if (length(n) == 0 || is.na(n)) "" else home_of(unname(n))
}

new <- features[c("kind", "name", "parent")]
new$home <- mapply(rule, features$kind, features$name, features$parent, features$detail)

if (file.exists("tools/homes.csv")) {
  old <- read.csv("tools/homes.csv", stringsAsFactors = FALSE)
  key <- function(d) paste(d$kind, d$name, d$parent, sep = "\r")
  old_home <- old$home[match(key(new), key(old))]
  use_old <- !is.na(old_home) & nzchar(old_home)
  new$home[use_old] <- old_home[use_old]
}

write.csv(new, "tools/homes.csv", row.names = FALSE)
un <- new[!nzchar(new$home), ]
message(sprintf("homes.csv: %d rows, %d unassigned", nrow(new), nrow(un)))
if (nrow(un)) print(un, row.names = FALSE)
print(table(new$home))

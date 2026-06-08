functions {
#include functions/utils.stan
#include functions/combine_effects.stan
#include functions/effects_priors_lp.stan
#include functions/arima_kernel.stan
#include functions/gaussian_process.stan
#include functions/regression.stan
#include functions/log_expected_latent_from_r.stan
#include functions/log_expected_obs_from_latent.stan
#include functions/primarycensored.stan
#include functions/primarycensored_pmf.stan
#include functions/hazard.stan
#include functions/expected_obs.stan
#include functions/combine_logit_hazards.stan
#include functions/expected_obs_from.stan
#include functions/filt_obs_indexes.stan
#include functions/obs_lpmf.stan
#include functions/obs_rng.stan
#include functions/allocate_observed_obs.stan
#include functions/apply_missing_reference_effects.stan
#include functions/log_expected_by_report.stan
#include functions/delay_lpmf.stan
}

data {
  // Indexes and lookups
  int n; // total number of observations (obs)
  int t; // total number of time points 
  int s; // total number of snapshots
  int g; // total number of groups
  array[g] int groups; // array of group ids
  array[s] int st; // time index of each snapshot (snapshot time)
  array[s] int sg; // group index of each snapshot (snapshot group)
  array[t, g] int ts; // snapshot index by time and group
  array[s] int sl; // number of reported obs per snapshot (snapshot length)
  array[s] int csl; // cumulative version of sl
  array[s] int lsl; // number of reported obs per snapshot (in the likelihood)
  array[s] int clsl; // cumulative version of sl
  array[s] int nsl; // number of reported obs per snapshot (non-consectuive)
  array[s] int cnsl; // cumulative version of nsl
  int dmax; // maximum possible reporting delay
  array[s] int sdmax; // maximum delay by snapshot (snapshot dmax)
  array[s] int csdmax; // cumulative version of sdmax
 
  // Observations
  array[n] int flat_obs; // obs stored as a flat vector
  array[n] int flat_obs_lookup; // How do observed obs relate to all obs
  array[t, g] int latest_obs; // latest obs by time and group

  // Expectation model
  // ---- Growth rate submodule ----
  int expr_r_seed; // number of time points with seeded/initial latent cases
  int expr_gt_n; // maximum generation time
  int expr_t; // number of time points with modeled growth rate per group
  int expr_ft; // number of time points with latent cases (expr_r_seed + expr_t)
  // PMF of the generation time distribution (reversed and on log scale)
  vector[expr_gt_n] expr_lrgt;
  // Uncertain generation time: 0 = fixed PMF (use expr_lrgt), else a
  // distribution id (1 exp, 2 lognormal, 3 gamma) whose
  // parameters are sampled and discretised in-model.
  int<lower=0, upper=3> expr_gt_dist;
  array[2, 1] real expr_gt_mean_p;
  array[2, 1] real expr_gt_sd_p;
  // Model for growth rate process. Currently, 0 = none
  int expr_obs;
  int expr_fnindex;
  int expr_fintercept; // Should an intercept be included
  int expr_fncol;
  int expr_rncol;
  matrix[expr_fnindex, expr_fncol] expr_fdesign;
  matrix[expr_fncol, expr_rncol + 1] expr_rdesign;
  array[g] int expr_g; // starting time points for growth of each group
  // Priors for growth rate and initial log latent cases
  array[2, g * expr_r_seed] real expr_lelatent_int_p; 
  array[2, 1] real expr_r_int_p;
  array[2, 1] real expr_beta_sd_p;
  // ARIMA(p, d, q) latent residual on growth rate
  int<lower=0, upper=1> expr_arima_present;
  int<lower=0> expr_arima_T;
  int<lower=0> expr_arima_G;
  int<lower=0> expr_arima_p;
  int<lower=0> expr_arima_d;
  int<lower=0> expr_arima_q;
  int<lower=0> expr_arima_n_obs;
  array[expr_arima_n_obs] int<lower=1> expr_arima_flat_idx;
  array[2, 1] real expr_arima_sigma_p;
  array[2, 1] real expr_arima_pacf_p;
  // Gaussian process latent term on growth rate
  int<lower=0, upper=1> expr_gp_present;
  int<lower=0> expr_gp_T;
  int<lower=0> expr_gp_G;
  int<lower=0> expr_gp_M;
  int<lower=0> expr_gp_type;
  real<lower=0> expr_gp_nu;
  int<lower=0> expr_gp_d;
  real<lower=0> expr_gp_L;
  int<lower=0> expr_gp_n_obs;
  matrix[expr_gp_T - expr_gp_d,
    expr_gp_type == 1 ? 2 * expr_gp_M : expr_gp_M] expr_gp_PHI;
  array[expr_gp_n_obs] int<lower=1> expr_gp_flat_idx;
  array[2, 1] real expr_gp_rho_p;
  array[2, 1] real expr_gp_alpha_p;
  // ---- Latent case submodule ----
  int expl_lrd_n; // maximum latent delay (from latent case to obs at ref time)
  // Partial PMF of the latent delay distribution as a convolution matrix
  matrix[expr_ft,  expr_ft] expl_lrd;
  // Uncertain latent reporting delay: 0 = fixed PMF (use expl_lrd), else a
  // distribution id (1 exp, 2 lognormal, 3 gamma) whose
  // parameters are sampled and discretised then convolved in-model.
  int<lower=0, upper=3> expl_lrd_dist;
  array[2, 1] real expl_lrd_mean_p;
  array[2, 1] real expl_lrd_sd_p;
  // For an uncertain delay, maps each nonzero of the convolution matrix (CSR
  // row-major order, matching the precomputed sparse pattern) to the PMF index
  // supplying its value. Length 1 placeholder when the delay is fixed.
  int expl_lrd_w_n;
  array[expl_lrd_w_n] int<lower=1> expl_lrd_w_idx;
  // Model for latent-to-obs proportion. Currently, 0 = none
  // --> proportion of latent cases that will become observations
  // --> e.g.: infection fatality rate for death data
  int expl_obs;
  int expl_fnindex;
  int expl_fncol;
  int expl_rncol;
  matrix[expl_fnindex, expl_fncol] expl_fdesign;
  matrix[expl_fncol, expl_rncol + 1] expl_rdesign;
  array[2, 1] real expl_beta_sd_p;
  // ARIMA latent residual on log latent-to-obs proportion
  int<lower=0, upper=1> expl_arima_present;
  int<lower=0> expl_arima_T;
  int<lower=0> expl_arima_G;
  int<lower=0> expl_arima_p;
  int<lower=0> expl_arima_d;
  int<lower=0> expl_arima_q;
  int<lower=0> expl_arima_n_obs;
  array[expl_arima_n_obs] int<lower=1> expl_arima_flat_idx;
  array[2, 1] real expl_arima_sigma_p;
  array[2, 1] real expl_arima_pacf_p;
  // Gaussian process latent term on log latent-to-obs proportion
  int<lower=0, upper=1> expl_gp_present;
  int<lower=0> expl_gp_T;
  int<lower=0> expl_gp_G;
  int<lower=0> expl_gp_M;
  int<lower=0> expl_gp_type;
  real<lower=0> expl_gp_nu;
  int<lower=0> expl_gp_d;
  real<lower=0> expl_gp_L;
  int<lower=0> expl_gp_n_obs;
  matrix[expl_gp_T - expl_gp_d,
    expl_gp_type == 1 ? 2 * expl_gp_M : expl_gp_M] expl_gp_PHI;
  array[expl_gp_n_obs] int<lower=1> expl_gp_flat_idx;
  array[2, 1] real expl_gp_rho_p;
  array[2, 1] real expl_gp_alpha_p;

  // Reference time model
  // Parametric reference model
  int model_refp;
  int refp_fnrow;
  array[s] int refp_findex;
  int refp_fncol;
  matrix[refp_fnrow, refp_fncol] refp_fdesign;
  int refp_rncol;
  matrix[refp_fncol, refp_rncol + 1] refp_rdesign;
  array[2, 1] real refp_mean_int_p;
  array[2, 1] real refp_sd_int_p;
  array[2, 1] real refp_mean_beta_sd_p;
  array[2, 1] real refp_sd_beta_sd_p;
  // ARIMA latent residual on the parametric reference. Shocks and
  // kernel are shared between mean and sd; each quantity has its own
  // scale (sigma) so they can grow time-varying structure
  // independently. Joint-deduplicated at (covariate row x ARIMA time
  // x ARIMA group) so the per-tuple PMF call pays only for distinct
  // combinations.
  int<lower=0, upper=1> refp_arima_present;
  int<lower=0> refp_arima_T;
  int<lower=0> refp_arima_G;
  int<lower=0> refp_arima_p;
  int<lower=0> refp_arima_d;
  int<lower=0> refp_arima_q;
  int<lower=0> refp_arima_n_obs;
  array[refp_arima_n_obs] int<lower=1> refp_arima_flat_idx;
  array[2, 1] real refp_arima_sigma_p;     // mean scale prior
  array[2, 1] real refp_arima_pacf_p;
  array[2, 1] real refp_arima_sd_sigma_p;  // sd scale prior
  // Gaussian process latent term on the parametric reference. Basis,
  // length scale and spectral coefficients are shared between mean and
  // sd; each quantity has its own magnitude (alpha) so they can grow
  // time-varying structure independently.
  int<lower=0, upper=1> refp_gp_present;
  int<lower=0> refp_gp_T;
  int<lower=0> refp_gp_G;
  int<lower=0> refp_gp_M;
  int<lower=0> refp_gp_type;
  real<lower=0> refp_gp_nu;
  int<lower=0> refp_gp_d;
  real<lower=0> refp_gp_L;
  int<lower=0> refp_gp_n_obs;
  matrix[refp_gp_T - refp_gp_d,
    refp_gp_type == 1 ? 2 * refp_gp_M : refp_gp_M] refp_gp_PHI;
  array[refp_gp_n_obs] int<lower=1> refp_gp_flat_idx;
  array[2, 1] real refp_gp_rho_p;
  array[2, 1] real refp_gp_alpha_p;     // mean magnitude prior
  array[2, 1] real refp_gp_sd_alpha_p;  // sd magnitude prior
  // Non-parametric reference model
  int model_refnp;
  int refnp_fnindex;
  int refnp_fintercept; // Should an intercept be included
  int refnp_fncol;
  int refnp_rncol;
  matrix[refnp_fnindex, refnp_fncol] refnp_fdesign;
  matrix[refnp_fncol, refnp_rncol + 1] refnp_rdesign;
  array[2, 1] real refnp_int_p;
  array[2, 1] real refnp_beta_sd_p;
  // ARIMA latent residual on non-parametric reference logit hazards
  int<lower=0, upper=1> refnp_arima_present;
  int<lower=0> refnp_arima_T;
  int<lower=0> refnp_arima_G;
  int<lower=0> refnp_arima_p;
  int<lower=0> refnp_arima_d;
  int<lower=0> refnp_arima_q;
  int<lower=0> refnp_arima_n_obs;
  array[refnp_arima_n_obs] int<lower=1> refnp_arima_flat_idx;
  array[2, 1] real refnp_arima_sigma_p;
  array[2, 1] real refnp_arima_pacf_p;
  // Gaussian process latent term on non-parametric reference logit hazards
  int<lower=0, upper=1> refnp_gp_present;
  int<lower=0> refnp_gp_T;
  int<lower=0> refnp_gp_G;
  int<lower=0> refnp_gp_M;
  int<lower=0> refnp_gp_type;
  real<lower=0> refnp_gp_nu;
  int<lower=0> refnp_gp_d;
  real<lower=0> refnp_gp_L;
  int<lower=0> refnp_gp_n_obs;
  matrix[refnp_gp_T - refnp_gp_d,
    refnp_gp_type == 1 ? 2 * refnp_gp_M : refnp_gp_M]
    refnp_gp_PHI;
  array[refnp_gp_n_obs] int<lower=1> refnp_gp_flat_idx;
  array[2, 1] real refnp_gp_rho_p;
  array[2, 1] real refnp_gp_alpha_p;

  // Reporting time model
  int model_rep;
  int rep_t; // total number of reporting times (t + dmax - 1)
  int rep_fnrow;
  array[g, rep_t] int rep_findex;
  int rep_fncol;
  matrix[rep_fnrow, rep_fncol] rep_fdesign;
  int rep_rncol;
  matrix[rep_fncol, rep_rncol + 1] rep_rdesign;
  array[2, 1] real rep_beta_sd_p;
  // ARIMA latent residual on report-time logit hazards (joint sparse
  // dedup as for refp).
  int<lower=0, upper=1> rep_arima_present;
  int<lower=0> rep_arima_T;
  int<lower=0> rep_arima_G;
  int<lower=0> rep_arima_p;
  int<lower=0> rep_arima_d;
  int<lower=0> rep_arima_q;
  int<lower=0> rep_arima_n_obs;
  array[rep_arima_n_obs] int<lower=1> rep_arima_flat_idx;
  array[2, 1] real rep_arima_sigma_p;
  array[2, 1] real rep_arima_pacf_p;
  // Gaussian process latent term on report-time logit hazards (joint
  // sparse dedup as for refp).
  int<lower=0, upper=1> rep_gp_present;
  int<lower=0> rep_gp_T;
  int<lower=0> rep_gp_G;
  int<lower=0> rep_gp_M;
  int<lower=0> rep_gp_type;
  real<lower=0> rep_gp_nu;
  int<lower=0> rep_gp_d;
  real<lower=0> rep_gp_L;
  int<lower=0> rep_gp_n_obs;
  matrix[rep_gp_T - rep_gp_d,
    rep_gp_type == 1 ? 2 * rep_gp_M : rep_gp_M] rep_gp_PHI;
  array[rep_gp_n_obs] int<lower=1> rep_gp_flat_idx;
  array[2, 1] real rep_gp_rho_p;
  array[2, 1] real rep_gp_alpha_p;
  // Reporting probability aggregation: precomputed indices for log_sum_exp
  int rep_agg_p;
  array[rep_agg_p ? g : 0, rep_agg_p ? t : 0, rep_agg_p ? dmax : 0] int rep_agg_n_selected;
  array[rep_agg_p ? g : 0, rep_agg_p ? t : 0, rep_agg_p ? dmax : 0, rep_agg_p ? dmax : 0] int rep_agg_selected_idx;

  // Missing reference date model
  int model_miss;
  int miss_obs;
  int miss_fnindex;
  int miss_fncol;
  int miss_rncol;
  matrix[miss_fnindex, miss_fncol] miss_fdesign;
  matrix[miss_fncol, model_miss ? miss_rncol + 1 : 0] miss_rdesign;
  // Observations reported without a reference date (by reporting time)
  // --> Since the first dmax-1 obs are not used here, the reporting time
  // --> starts at dmax, not at 1
  array[miss_obs] int missing_reference;
  // Lookup for the obs index by reference date of entries in missing_reference:
  // --> If observations from entry i of missing_reference had a reporting
  // --> delay of d, their index in the flat vector of obs by reference date
  // --> (e.g. flat_obs) would be: obs_by_report[i, d]
  array[miss_obs, dmax] int obs_by_report;
  // Observations by group (and cumulative) for missing_reference and
  // obs_by_report
  array[miss_obs ? g : 0] int miss_st;
  array[miss_obs ? g : 0] int miss_cst;
  array[2, 1] real miss_int_p;
  array[2, 1] real miss_beta_sd_p;
  // ARIMA latent residual on missing-reference logit proportion
  int<lower=0, upper=1> miss_arima_present;
  int<lower=0> miss_arima_T;
  int<lower=0> miss_arima_G;
  int<lower=0> miss_arima_p;
  int<lower=0> miss_arima_d;
  int<lower=0> miss_arima_q;
  int<lower=0> miss_arima_n_obs;
  array[miss_arima_n_obs] int<lower=1> miss_arima_flat_idx;
  array[2, 1] real miss_arima_sigma_p;
  array[2, 1] real miss_arima_pacf_p;
  // Gaussian process latent term on missing-reference logit proportion
  int<lower=0, upper=1> miss_gp_present;
  int<lower=0> miss_gp_T;
  int<lower=0> miss_gp_G;
  int<lower=0> miss_gp_M;
  int<lower=0> miss_gp_type;
  real<lower=0> miss_gp_nu;
  int<lower=0> miss_gp_d;
  real<lower=0> miss_gp_L;
  int<lower=0> miss_gp_n_obs;
  matrix[miss_gp_T - miss_gp_d,
    miss_gp_type == 1 ? 2 * miss_gp_M : miss_gp_M] miss_gp_PHI;
  array[miss_gp_n_obs] int<lower=1> miss_gp_flat_idx;
  array[2, 1] real miss_gp_rho_p;
  array[2, 1] real miss_gp_alpha_p;

  // Observation model
  int model_obs; // control parameter for the observation model
  array[2, 1] real sqrt_phi_p; // 1/sqrt (overdispersion)

  // Control parameters
  int debug; // should debug information be shown?
  int likelihood; // should the likelihood be included?
  // type of aggregation scheme (0 = snaps, 1 = groups)
  int likelihood_aggregation;
  // should the likelihood calculation be parallelised (0 = no; 1 = yes)?
  int parallelise_likelihood;
  int pp; // should posterior predictions be produced?
  int cast; // should a nowcast be produced?
  int ologlik; // should the pointwise log likelihood be calculated?

  // Switch to use sparse or dense matrices
  int sparse_design;
}

transformed data{
  // if no reporting time effects use native probability for reference date
  // effects, i.e. do not convert to logit hazard
  int ref_as_p = (model_rep > 0 || model_refp == 0) ? 0 : 1;
  // Type of likelihood aggregation to use
  int ll_aggregation = likelihood_aggregation + model_miss;
  // Construct sparse matrix components
  #include /chunks/sparse_design.stan
}

parameters {
  // Expectation model
  // ---- Growth rate submodule ----
  matrix<offset = to_matrix(expr_lelatent_int_p[1], expr_r_seed, g), multiplier = to_matrix(expr_lelatent_int_p[2], expr_r_seed, g)>[expr_r_seed, g] expr_lelatent_int; // initial observations by group (log)
  array[expr_fintercept ? 1 : 0] real<offset = expr_r_int_p[1, 1], multiplier = expr_r_int_p[2, 1]> expr_r_int; // growth rate intercept
  vector[expr_fncol] expr_beta;
  vector<lower=0>[expr_rncol] expr_beta_sd;
  // Growth rate ARIMA term parameters
  matrix[expr_arima_T, expr_arima_G] expr_arima_z;
  vector<lower=-1, upper=1>[expr_arima_p] expr_arima_pacf;
  vector[expr_arima_q] expr_arima_theta;
  array[expr_arima_present ? 1 : 0] real<lower=0> expr_arima_sigma;
  // Growth rate Gaussian process parameters
  matrix[expr_gp_type == 1 ? 2 * expr_gp_M : expr_gp_M, expr_gp_G] expr_gp_eta;
  array[expr_gp_present ? 1 : 0] real<lower=0> expr_gp_rho;
  array[expr_gp_present ? 1 : 0] real<lower=0> expr_gp_alpha;
  // Uncertain generation time parameters (sampled and discretised in-model).
  // Centred on the prior via offset/multiplier (as for the parametric
  // reference mean) for better conditioning and to keep proposals near the
  // prior, avoiding overflow of exp(mu) in the discretisation.
  array[expr_gt_dist ? 1 : 0] real<
    offset = expr_gt_mean_p[1, 1], multiplier = expr_gt_mean_p[2, 1]
  > expr_gt_mean;
  array[expr_gt_dist > 1 ? 1 : 0] real<lower=1e-3> expr_gt_sd;
  // ---- Latent case submodule ----
  // Uncertain latent reporting delay parameters (centred on the prior, see
  // the generation time parameters above).
  array[expl_lrd_dist ? 1 : 0] real<
    offset = expl_lrd_mean_p[1, 1], multiplier = expl_lrd_mean_p[2, 1]
  > expl_lrd_mean;
  array[expl_lrd_dist > 1 ? 1 : 0] real<lower=1e-3> expl_lrd_sd;
  vector[expl_fncol] expl_beta;
  vector<lower=0>[expl_rncol] expl_beta_sd;
  // Latent-to-obs proportion ARIMA term parameters
  matrix[expl_arima_T, expl_arima_G] expl_arima_z;
  vector<lower=-1, upper=1>[expl_arima_p] expl_arima_pacf;
  vector[expl_arima_q] expl_arima_theta;
  array[expl_arima_present ? 1 : 0] real<lower=0> expl_arima_sigma;
  // Latent-to-obs proportion Gaussian process parameters
  matrix[expl_gp_type == 1 ? 2 * expl_gp_M : expl_gp_M, expl_gp_G] expl_gp_eta;
  array[expl_gp_present ? 1 : 0] real<lower=0> expl_gp_rho;
  array[expl_gp_present ? 1 : 0] real<lower=0> expl_gp_alpha;

  // Reference model
  // Parametric reference model
  array[model_refp ? 1 : 0] real<offset = refp_mean_int_p[1,1], multiplier = refp_mean_int_p[2,1]> refp_mean_int;
  array[model_refp > 1 ? 1 : 0]real<lower=1e-3, upper=2*dmax> refp_sd_int; 
  vector[model_refp ? refp_fncol : 0] refp_mean_beta;
  vector[model_refp > 1 ? refp_fncol : 0] refp_sd_beta;
  vector<lower=0>[refp_rncol] refp_mean_beta_sd;
  vector<lower=0>[model_refp ? refp_rncol : 0] refp_sd_beta_sd;
  // Parametric reference ARIMA term parameters. Shocks and kernel
  // shared between mean and sd; per-quantity scales independent.
  matrix[refp_arima_T, refp_arima_G] refp_arima_z;
  vector<lower=-1, upper=1>[refp_arima_p] refp_arima_pacf;
  vector[refp_arima_q] refp_arima_theta;
  array[refp_arima_present ? 1 : 0] real<lower=0> refp_arima_sigma;
  array[refp_arima_present && model_refp > 1 ? 1 : 0]
    real<lower=0> refp_arima_sd_sigma;
  // Parametric reference Gaussian process parameters. Basis / length
  // scale / spectral coefficients shared between mean and sd; per-
  // quantity magnitudes (alpha) independent.
  matrix[refp_gp_type == 1 ? 2 * refp_gp_M : refp_gp_M, refp_gp_G] refp_gp_eta;
  array[refp_gp_present ? 1 : 0] real<lower=0> refp_gp_rho;
  array[refp_gp_present ? 1 : 0] real<lower=0> refp_gp_alpha;
  array[refp_gp_present && model_refp > 1 ? 1 : 0]
    real<lower=0> refp_gp_sd_alpha;
  // Non-parametric reference model
  array[model_refnp && refnp_fintercept ? 1 : 0] real refnp_int;
  vector[model_refnp ? refnp_fncol : 0] refnp_beta;
  vector<lower=0>[refnp_rncol] refnp_beta_sd;
  // Non-parametric reference ARIMA term parameters
  matrix[refnp_arima_T, refnp_arima_G] refnp_arima_z;
  vector<lower=-1, upper=1>[refnp_arima_p] refnp_arima_pacf;
  vector[refnp_arima_q] refnp_arima_theta;
  array[refnp_arima_present ? 1 : 0] real<lower=0> refnp_arima_sigma;
  // Non-parametric reference Gaussian process parameters
  matrix[refnp_gp_type == 1 ? 2 * refnp_gp_M : refnp_gp_M, refnp_gp_G]
    refnp_gp_eta;
  array[refnp_gp_present ? 1 : 0] real<lower=0> refnp_gp_rho;
  array[refnp_gp_present ? 1 : 0] real<lower=0> refnp_gp_alpha;

  // Report model
  vector[rep_fncol] rep_beta;
  vector<lower=0>[rep_rncol] rep_beta_sd;
  // Report-time ARIMA term parameters
  matrix[rep_arima_T, rep_arima_G] rep_arima_z;
  vector<lower=-1, upper=1>[rep_arima_p] rep_arima_pacf;
  vector[rep_arima_q] rep_arima_theta;
  array[rep_arima_present ? 1 : 0] real<lower=0> rep_arima_sigma;
  // Report-time Gaussian process parameters
  matrix[rep_gp_type == 1 ? 2 * rep_gp_M : rep_gp_M, rep_gp_G] rep_gp_eta;
  array[rep_gp_present ? 1 : 0] real<lower=0> rep_gp_rho;
  array[rep_gp_present ? 1 : 0] real<lower=0> rep_gp_alpha;

  // Missing reference date model
  array[model_miss] real miss_int;
  vector[miss_fncol] miss_beta;
  vector<lower=0>[miss_rncol] miss_beta_sd;
  // Missing-reference ARIMA term parameters
  matrix[miss_arima_T, miss_arima_G] miss_arima_z;
  vector<lower=-1, upper=1>[miss_arima_p] miss_arima_pacf;
  vector[miss_arima_q] miss_arima_theta;
  array[miss_arima_present ? 1 : 0] real<lower=0> miss_arima_sigma;
  // Missing-reference Gaussian process parameters
  matrix[miss_gp_type == 1 ? 2 * miss_gp_M : miss_gp_M, miss_gp_G] miss_gp_eta;
  array[miss_gp_present ? 1 : 0] real<lower=0> miss_gp_rho;
  array[miss_gp_present ? 1 : 0] real<lower=0> miss_gp_alpha;

  // Observation model
  array[model_obs > 0 ? 1 : 0] real<lower=0> sqrt_phi; // overdispersion
}

transformed parameters{
  // Expectation model
  vector[expr_t * g] r; // growth rate of observations (log)
  array[g] vector[expr_ft]  exp_llatent; // expected latent cases (log)
  vector[expl_obs ? expl_fnindex : 0] expl_prop; // latent-to-obs proportion
  array[g] vector[t]  exp_lobs; // expected obs by reference date (log)
  
  // Reference model
  // Parametric reference model
  vector[refp_fnrow] refp_mean;
  vector[refp_fnrow] refp_sd;
  matrix[dmax, refp_fnrow] refp_lh; // sparse report logit hazards
  // Non-parametric reference model
  vector[model_refnp > 0 ? refnp_fnindex : 0] refnp_lh; 
  
  // Report model
  vector[rep_fnrow] srdlh; // sparse reporting time logit hazards
  
  // Missing reference date model
  vector[miss_fnindex] miss_ref_lprop;

  // Observation model
  array[model_obs > 0 ? 1 : 0] real phi; // Transformed overdispersion

  // Expectation model
  profile("transformed_expected_final_observations") {
  // Explicit local block (NOT a profile block, which would be stripped by
  // remove_profiling() leaving these declarations at top level). The
  // generation time log PMF (reversed) and latent reporting delay convolution
  // weights are local so they are not saved to draws: the default fixed-PMF
  // posterior output stays byte-identical and the fixed-seed sampler is not
  // perturbed. For a fixed PMF these are taken straight from transformed data;
  // for an uncertain PMF they are rebuilt per sample. The sparsity pattern
  // (column indices / row pointers) is identical in both cases, so only the
  // real-valued weights vary and the integer parts are reused from
  // `expl_lrd_sparse`.
  {
  vector[expr_gt_n] expr_lrgt_use;
  vector[num_elements(expl_lrd_sparse.1)] expl_lrd_w;
  // Reuse the parametric reference discretisation
  // (discretised_pcens_logit_hazard with ref_as_p = 1 returns a log PMF) to
  // rebuild distributions in-model.
  if (expr_gt_dist) {
    real gt_sigma = expr_gt_dist > 1 ? expr_gt_sd[1] : 0;
    vector[expr_gt_n] gt_lpmf = discretised_pcens_logit_hazard(
      expr_gt_mean[1], gt_sigma, expr_gt_n, expr_gt_dist, 1
    );
    // log_expected_latent_from_r expects the reversed log PMF.
    expr_lrgt_use = reverse(gt_lpmf);
  } else {
    expr_lrgt_use = expr_lrgt;
  }
  if (expl_lrd_dist) {
    real lrd_sigma = expl_lrd_dist > 1 ? expl_lrd_sd[1] : 0;
    vector[expl_lrd_n] lrd_pmf = exp(discretised_pcens_logit_hazard(
      expl_lrd_mean[1], lrd_sigma, expl_lrd_n, expl_lrd_dist, 1
    ));
    // Fill the CSR weights from the sampled PMF using the precomputed
    // pattern-to-PMF index map (value-stable, so the nonzero count matches
    // expl_lrd_sparse even if the PMF tail underflows to zero).
    expl_lrd_w = lrd_pmf[expl_lrd_w_idx];
  } else {
    expl_lrd_w = expl_lrd_sparse.1;
  }
  // Get log growth rates and map to expected latent cases
  r = regression_predictor(
    expr_r_int, expr_beta, expr_fnindex, expr_fncol, expr_fdesign,
    expr_sparse, expr_beta_sd, expr_rdesign, expr_fintercept, sparse_design,
    expr_arima_present, expr_arima_T, expr_arima_G,
    expr_arima_p, expr_arima_d, expr_arima_q, expr_arima_n_obs,
    expr_arima_z, expr_arima_pacf, expr_arima_theta, expr_arima_sigma,
    expr_arima_flat_idx,
    expr_gp_present, expr_gp_T, expr_gp_G, expr_gp_M, expr_gp_L,
    expr_gp_type, expr_gp_nu, expr_gp_d, expr_gp_PHI, expr_gp_eta,
    expr_gp_rho, expr_gp_alpha, expr_gp_flat_idx
  );
  exp_llatent = log_expected_latent_from_r(
    expr_lelatent_int, r, expr_g, expr_t, expr_r_seed, expr_gt_n,
    expr_lrgt_use, expr_ft, g
  );
  // Get latent-to-obs proportions and map expected latent cases to expected observations
  if (expl_obs) {
    expl_prop = regression_predictor(
      {0}, expl_beta, expl_fnindex, expl_fncol, expl_fdesign,
      expl_sparse, expl_beta_sd, expl_rdesign, 1, sparse_design,
      expl_arima_present, expl_arima_T, expl_arima_G,
      expl_arima_p, expl_arima_d, expl_arima_q, expl_arima_n_obs,
      expl_arima_z, expl_arima_pacf, expl_arima_theta, expl_arima_sigma,
      expl_arima_flat_idx,
      expl_gp_present, expl_gp_T, expl_gp_G, expl_gp_M, expl_gp_L,
      expl_gp_type, expl_gp_nu, expl_gp_d, expl_gp_PHI, expl_gp_eta,
      expl_gp_rho, expl_gp_alpha, expl_gp_flat_idx
    );
    exp_lobs = log_expected_obs_from_latent(
      exp_llatent, expl_lrd_n, expl_lrd_w, expl_lrd_sparse.2,
      expl_lrd_sparse.3, t, g, expl_prop
    );
  } else {
    exp_lobs = exp_llatent; // assume latent cases and obs are identical
  }
  } // close local block scoping expr_lrgt_use / expl_lrd_w
  }

  // Reference model
  // Parametric reference model
  profile("transformed_delay_parametric_reference_time_total") {
  if (model_refp) {
    // calculate sparse reference date effects (with ARIMA on the mean
    // applied per joint-deduplicated tuple)
    profile("transformed_delay_reference_time_effects") {
    refp_mean = regression_predictor(
      refp_mean_int, refp_mean_beta, refp_fnrow, refp_fncol, refp_fdesign,
      refp_sparse, refp_mean_beta_sd, refp_rdesign, 1, sparse_design,
      refp_arima_present, refp_arima_T, refp_arima_G,
      refp_arima_p, refp_arima_d, refp_arima_q, refp_arima_n_obs,
      refp_arima_z, refp_arima_pacf, refp_arima_theta, refp_arima_sigma,
      refp_arima_flat_idx,
      refp_gp_present, refp_gp_T, refp_gp_G, refp_gp_M, refp_gp_L,
      refp_gp_type, refp_gp_nu, refp_gp_d, refp_gp_PHI, refp_gp_eta,
      refp_gp_rho, refp_gp_alpha, refp_gp_flat_idx
    );
    // Default the (unused) sd to 1 for single-parameter distributions such as
    // the exponential (model_refp == 1) so the discretisation functions below
    // always receive a defined value.
    refp_sd = rep_vector(1.0, refp_fnrow);
    if (model_refp > 1) {
      refp_sd = regression_predictor(
        {log(refp_sd_int[1])}, refp_sd_beta, refp_fnrow, refp_fncol,
        refp_fdesign, refp_sparse, refp_sd_beta_sd, refp_rdesign, 1,
        sparse_design,
        refp_arima_present, refp_arima_T, refp_arima_G,
        refp_arima_p, refp_arima_d, refp_arima_q, refp_arima_n_obs,
        refp_arima_z, refp_arima_pacf, refp_arima_theta,
        refp_arima_sd_sigma,
        refp_arima_flat_idx,
        refp_gp_present, refp_gp_T, refp_gp_G, refp_gp_M, refp_gp_L,
        refp_gp_type, refp_gp_nu, refp_gp_d, refp_gp_PHI, refp_gp_eta,
        refp_gp_rho, refp_gp_sd_alpha, refp_gp_flat_idx
      );
      refp_sd = exp(refp_sd);
    }
    }
    // calculate parametric reference date logit hazards (unless no reporting
    // effects). The parametric reference delay is discretised with the
    // primarycensored double interval censoring approach for every supported
    // distribution (lognormal, gamma, exponential).
    profile("transformed_delay_reference_time_hazards") {
    for (i in 1:refp_fnrow) {
      refp_lh[, i] = discretised_pcens_logit_hazard(
        refp_mean[i], refp_sd[i], dmax, model_refp, ref_as_p
      );
    }
    }
  }
  }
  if (model_refnp) {
    // calculate non-parametric reference date logit hazards
    profile("transformed_delay_non_parametric_reference_time_hazards") {
    refnp_lh = regression_predictor(
      refnp_int, refnp_beta, refnp_fnindex, refnp_fncol, refnp_fdesign,
      refnp_sparse, refnp_beta_sd, refnp_rdesign, refnp_fintercept,
      sparse_design,
      refnp_arima_present, refnp_arima_T, refnp_arima_G,
      refnp_arima_p, refnp_arima_d, refnp_arima_q, refnp_arima_n_obs,
      refnp_arima_z, refnp_arima_pacf, refnp_arima_theta, refnp_arima_sigma,
      refnp_arima_flat_idx,
      refnp_gp_present, refnp_gp_T, refnp_gp_G, refnp_gp_M, refnp_gp_L,
      refnp_gp_type, refnp_gp_nu, refnp_gp_d, refnp_gp_PHI, refnp_gp_eta,
      refnp_gp_rho, refnp_gp_alpha, refnp_gp_flat_idx
    );
    }
  }

  // Report model
  profile("transformed_delay_reporting_time_effects") {
  srdlh = regression_predictor(
    {0}, rep_beta, rep_fnrow, rep_fncol, rep_fdesign,
    rep_sparse, rep_beta_sd, rep_rdesign, 1, sparse_design,
    rep_arima_present, rep_arima_T, rep_arima_G,
    rep_arima_p, rep_arima_d, rep_arima_q, rep_arima_n_obs,
    rep_arima_z, rep_arima_pacf, rep_arima_theta, rep_arima_sigma,
    rep_arima_flat_idx,
    rep_gp_present, rep_gp_T, rep_gp_G, rep_gp_M, rep_gp_L,
    rep_gp_type, rep_gp_nu, rep_gp_d, rep_gp_PHI, rep_gp_eta,
    rep_gp_rho, rep_gp_alpha, rep_gp_flat_idx
  );
  }

  // Missing reference model
  if (model_miss) {
    miss_ref_lprop = log_inv_logit(regression_predictor(
      miss_int, miss_beta, miss_fnindex, miss_fncol, miss_fdesign,
      miss_sparse, miss_beta_sd, miss_rdesign, 1, sparse_design,
      miss_arima_present, miss_arima_T, miss_arima_G,
      miss_arima_p, miss_arima_d, miss_arima_q, miss_arima_n_obs,
      miss_arima_z, miss_arima_pacf, miss_arima_theta, miss_arima_sigma,
      miss_arima_flat_idx,
      miss_gp_present, miss_gp_T, miss_gp_G, miss_gp_M, miss_gp_L,
      miss_gp_type, miss_gp_nu, miss_gp_d, miss_gp_PHI, miss_gp_eta,
      miss_gp_rho, miss_gp_alpha, miss_gp_flat_idx
    ));
  }
  // Observation model
  if (model_obs) {
    profile("transformed_delay_missing_effects") {
    phi = inv_square(sqrt_phi);
  }
  } 
  // debug issues in truncated data if/when they appear
  if (debug) {
#include /chunks/debug.stan
  }
} 
  
model {
  profile("model_priors") {
  // Expectation model
  // ---- Growth rate submodule ----
  // intercept/initial latent cases (log)
  to_vector(expr_lelatent_int) ~ normal(
    expr_lelatent_int_p[1], expr_lelatent_int_p[2]
  );
  // intercept of growth rate
  if (expr_fintercept) {
    expr_r_int[expr_fintercept]  ~ normal(expr_r_int_p[1], expr_r_int_p[2]); 
  }
  
  // growth rate effect + ARIMA priors
  regression_priors_lp(
    expr_beta, expr_beta_sd, expr_beta_sd_p, expr_fncol, expr_rncol,
    expr_arima_present, expr_arima_p, expr_arima_q,
    expr_arima_z, expr_arima_pacf, expr_arima_theta,
    expr_arima_sigma, expr_arima_sigma_p, expr_arima_pacf_p
  );
  gp_priors_lp(
    expr_gp_present, expr_gp_eta, expr_gp_rho, expr_gp_alpha,
    expr_gp_rho_p, expr_gp_alpha_p
  );
  // Uncertain generation time parameter priors
  if (expr_gt_dist) {
    expr_gt_mean ~ normal(expr_gt_mean_p[1], expr_gt_mean_p[2]);
    if (expr_gt_dist > 1) {
      expr_gt_sd ~ normal(expr_gt_sd_p[1], expr_gt_sd_p[2]);
    }
  }
  // Uncertain latent reporting delay parameter priors
  if (expl_lrd_dist) {
    expl_lrd_mean ~ normal(expl_lrd_mean_p[1], expl_lrd_mean_p[2]);
    if (expl_lrd_dist > 1) {
      expl_lrd_sd ~ normal(expl_lrd_sd_p[1], expl_lrd_sd_p[2]);
    }
  }
  // ---- Latent case submodule ----
  // latent-to-obs proportion effect + ARIMA priors
  regression_priors_lp(
    expl_beta, expl_beta_sd, expl_beta_sd_p, expl_fncol, expl_rncol,
    expl_arima_present, expl_arima_p, expl_arima_q,
    expl_arima_z, expl_arima_pacf, expl_arima_theta,
    expl_arima_sigma, expl_arima_sigma_p, expl_arima_pacf_p
  );
  gp_priors_lp(
    expl_gp_present, expl_gp_eta, expl_gp_rho, expl_gp_alpha,
    expl_gp_rho_p, expl_gp_alpha_p
  );
  
  // Reference model
  // Parametric reference model
  if (model_refp) {
    refp_mean_int ~ normal(refp_mean_int_p[1], refp_mean_int_p[2]);
    if (model_refp > 1) {
      refp_sd_int ~ normal(refp_sd_int_p[1], refp_sd_int_p[2]);
    }
    regression_priors_lp(
      refp_mean_beta, refp_mean_beta_sd, refp_mean_beta_sd_p,
      refp_fncol, refp_rncol,
      refp_arima_present, refp_arima_p, refp_arima_q,
      refp_arima_z, refp_arima_pacf, refp_arima_theta,
      refp_arima_sigma, refp_arima_sigma_p, refp_arima_pacf_p
    );
    gp_priors_lp(
      refp_gp_present, refp_gp_eta, refp_gp_rho, refp_gp_alpha,
      refp_gp_rho_p, refp_gp_alpha_p
    );
    if (model_refp > 1) {
      effect_priors_lp(
        refp_sd_beta, refp_sd_beta_sd, refp_sd_beta_sd_p, refp_fncol,
        refp_rncol
      );
    }
    // Per-quantity sd scale for the shared ARIMA latent. Shocks /
    // kernel are already drawn / priored by the mean-side
    // regression_priors_lp() above, so only the second scale needs a
    // prior here.
    if (refp_arima_present && model_refp > 1) {
      refp_arima_sd_sigma[1] ~ normal(
        refp_arima_sd_sigma_p[1, 1], refp_arima_sd_sigma_p[2, 1]
      ) T[0, ];
    }
    // Per-quantity sd magnitude for the shared GP latent. The basis,
    // length scale and spectral coefficients are already priored by the
    // mean-side gp_priors_lp() above, so only the sd magnitude needs a
    // prior here.
    if (refp_gp_present && model_refp > 1) {
      refp_gp_sd_alpha[1] ~ normal(
        refp_gp_sd_alpha_p[1, 1], refp_gp_sd_alpha_p[2, 1]
      ) T[0, ];
    }
  }
  // Non-parametric reference model
  if (model_refnp) {
    if (refnp_fintercept) {
      refnp_int[refnp_fintercept] ~ normal(refnp_int_p[1], refnp_int_p[2]);
    }
    regression_priors_lp(
      refnp_beta, refnp_beta_sd, refnp_beta_sd_p, refnp_fncol, refnp_rncol,
      refnp_arima_present, refnp_arima_p, refnp_arima_q,
      refnp_arima_z, refnp_arima_pacf, refnp_arima_theta,
      refnp_arima_sigma, refnp_arima_sigma_p, refnp_arima_pacf_p
    );
    gp_priors_lp(
      refnp_gp_present, refnp_gp_eta, refnp_gp_rho, refnp_gp_alpha,
      refnp_gp_rho_p, refnp_gp_alpha_p
    );
  }

  // Report model
  regression_priors_lp(
    rep_beta, rep_beta_sd, rep_beta_sd_p, rep_fncol, rep_rncol,
    rep_arima_present, rep_arima_p, rep_arima_q,
    rep_arima_z, rep_arima_pacf, rep_arima_theta,
    rep_arima_sigma, rep_arima_sigma_p, rep_arima_pacf_p
  );
  gp_priors_lp(
    rep_gp_present, rep_gp_eta, rep_gp_rho, rep_gp_alpha,
    rep_gp_rho_p, rep_gp_alpha_p
  );

  // Missing reference date model
  if (model_miss) {
    miss_int ~ normal(miss_int_p[1], miss_int_p[2]);
    regression_priors_lp(
      miss_beta, miss_beta_sd, miss_beta_sd_p, miss_fncol, miss_rncol,
      miss_arima_present, miss_arima_p, miss_arima_q,
      miss_arima_z, miss_arima_pacf, miss_arima_theta,
      miss_arima_sigma, miss_arima_sigma_p, miss_arima_pacf_p
    );
    gp_priors_lp(
      miss_gp_present, miss_gp_eta, miss_gp_rho, miss_gp_alpha,
      miss_gp_rho_p, miss_gp_alpha_p
    );
  }
  
  // Observation model
  // overdispersion (1/sqrt)
  if (model_obs) {   
    sqrt_phi[1] ~ normal(sqrt_phi_p[1], sqrt_phi_p[2]) T[0,]; 
  }
  
  }

  // Log-Likelihood either by snapshot or group depending on settings/model
  if (likelihood) {
    profile("model_likelihood") {
    if (parallelise_likelihood) {
      if (ll_aggregation) {
        target += reduce_sum(
          delay_group_lupmf, groups, 1, flat_obs, lsl, clsl, nsl, cnsl,
          flat_obs_lookup, exp_lobs, t, sg, ts, st, rep_findex, srdlh, refp_lh,
          refp_findex, model_refp, rep_fncol, ref_as_p, phi, model_obs, model_miss, miss_obs, missing_reference,
          obs_by_report, miss_ref_lprop, sdmax, csdmax, miss_st, miss_cst,
          refnp_lh, model_refnp, rep_agg_p, rep_agg_n_selected,
          rep_agg_selected_idx
        );
      } else {
        target += reduce_sum(
          delay_snap_lupmf, st, 1, flat_obs, lsl, clsl, nsl, cnsl,
          flat_obs_lookup, exp_lobs, sg, st, rep_findex, srdlh, refp_lh,
          refp_findex, model_refp, rep_fncol, ref_as_p, phi, model_obs, refnp_lh,
          model_refnp, sdmax, csdmax, rep_agg_p, rep_agg_n_selected,
          rep_agg_selected_idx
        );
      }
    } else {
      groups ~ delay_group(
        1, g, flat_obs, lsl, clsl, nsl, cnsl, flat_obs_lookup, exp_lobs, t, sg,
        ts, st, rep_findex, srdlh, refp_lh, refp_findex, model_refp, rep_fncol,
        ref_as_p, phi, model_obs, model_miss, miss_obs, missing_reference,
        obs_by_report, miss_ref_lprop, sdmax, csdmax, miss_st, miss_cst,
        refnp_lh, model_refnp, rep_agg_p, rep_agg_n_selected,
        rep_agg_selected_idx
      );
    }
  }
  }
}


generated quantities {
  array[pp ? sum(sl) : 0] int pp_obs;
  array[pp ? miss_obs : 0] int pp_miss_ref;
  vector[ologlik ? s : 0] log_lik;
  array[cast ? min(dmax, t) : 0, cast ? g : 0] int pp_inf_obs;
  profile("generated_total") {
  if (cast) {
    vector[csdmax[s]] log_exp_obs_all;
    vector[miss_obs]  log_exp_miss_ref;
    vector[miss_obs ? csdmax[s] : 0] log_exp_miss_by_ref;
    vector[csl[s]] log_exp_obs;
    vector[clsl[s]] log_exp_obs_lik;
    array[csdmax[s]] int pp_obs_all;
    array[csl[s]] int pp_obs_tmp;
    array[clsl[s]] int pp_obs_lik;

    // Posterior predictions for observations
    profile("generated_obs") {
    log_exp_obs_all = expected_obs_from_snaps(
      1, s,  exp_lobs, rep_findex, srdlh, refp_lh, refp_findex, model_refp,
      rep_fncol, ref_as_p, sdmax, csdmax, sg, st, csdmax[s], refnp_lh,
      model_refnp, sdmax, csdmax, rep_agg_p, rep_agg_n_selected,
      rep_agg_selected_idx
    );
    
    if (model_miss) {
      // Allocate proportion that are not reported
      log_exp_miss_by_ref = apply_missing_reference_effects(
        1, s, log_exp_obs_all, sdmax, csdmax, miss_ref_lprop
      );
      log_exp_miss_ref = log_expected_by_report(
        log_exp_miss_by_ref, obs_by_report
      );
      // Allocate proportion that are reported
      log_exp_obs_all = apply_missing_reference_effects(
        1, s, log_exp_obs_all, sdmax, csdmax, log1m_exp(miss_ref_lprop)
      );
    }
    // Allocate to just those actually observed
    log_exp_obs = allocate_observed_obs(
      1, s, log_exp_obs_all, sl, csl, sdmax, csdmax
    );
    // Allocate to just those observed (non-consecutivly)
    log_exp_obs_lik = allocate_observed_obs(
      1, s, log_exp_obs, lsl, clsl, sl, csl
    );
    // Draw from observation model for observed counts with report and reference
    pp_obs_all = obs_rng(log_exp_obs_all, phi, model_obs);
    // Allocate to just those actually observed
    pp_obs_tmp = allocate_observed_obs(
      1, s, pp_obs_all, sl, csl, sdmax, csdmax
    );
    // Allocate to just those in the likelihod
    pp_obs_lik = allocate_observed_obs(
      1, s, pp_obs_tmp, lsl, clsl, sl, csl
    );
    } 

    // Likelihood by snapshot (rather than by observation)
    profile("generated_loglik") {
    if (ologlik) {
      // Declare once outside loop to avoid repeated allocation
      array[3] int l;
      for (i in 1:s) {
        l = filt_obs_indexes(i, i, cnsl, nsl);
        log_lik[i] = 0;
        for (j in 1:nsl[i]) {
          log_lik[i] += obs_lpmf(
            flat_obs[l[1] + j - 1]  | log_exp_obs[l[1] + j - 1],
            phi, model_obs
          );
        }
      }
      // Add log lik component for missing reference model
      for (i in 1:miss_obs) {
        log_lik[dmax + i - 1] += obs_lpmf(
          missing_reference[i] | log_exp_miss_ref[i], phi, model_obs
        );
      }
    }
    }
    // Posterior prediction for final reported data (i.e at t + dmax + 1)
    // Organise into a grouped and time structured array
    profile("generated_obs") {
    // Declare once outside loops to avoid repeated allocation
    array[3] int f;
    array[3] int l;
    array[3] int nl;
    for (k in 1:g) {
      int start_t = max(t - dmax, 0);
      int nowcast_t = min(dmax, t);
      for (i in 1:nowcast_t) {
        // Where am I?
        int i_start = ts[start_t + i, k];
        f = filt_obs_indexes(i_start, i_start, csdmax, sdmax);
        l = filt_obs_indexes(i_start, i_start, csl, sl);
        nl = filt_obs_indexes(i_start, i_start, cnsl, nsl);
        // Add all estimated reported observations
        pp_inf_obs[i, k] = sum(segment(pp_obs_all, f[1], f[3]));

        if (nl[3]) {
          // Index lookup to start from where we currently are
          array[nl[3]] int filt_obs_lookup = segment(
            flat_obs_lookup, nl[1], nl[3]
          );
  
          // Minus estimates for those that are already reported
          pp_inf_obs[i, k] -= sum(pp_obs_lik[filt_obs_lookup]);
          // Add observations that have been reported
          pp_inf_obs[i, k] += sum(segment(flat_obs, nl[1], nl[3]));
        }
      }
    }
    if (pp) {
      // If posterior predictions for all observations are needed copy
      // from a temporary object to a permanent one
      pp_obs = pp_obs_tmp;
      // Posterior predictions for observations missing reference dates
      if (miss_obs) {
        pp_miss_ref = obs_rng(log_exp_miss_ref, phi, model_obs);
      }
    }
    }
  }
  }
}

/**
 * Single entry points for the regression layer.
 *
 * `regression_predictor()` composes `combine_effects()` (fixed +
 * partially-pooled random effects via the design matrices) with
 * `apply_arima_residual()` (parameter-dependent ARIMA(p, d, q) latent
 * residual) and `apply_gp_term()` (Hilbert-space approximate Gaussian
 * process). Each module that owns a per-observation predictor calls
 * this once instead of calling the layers separately, so every module
 * routed through it gains the ARIMA and GP latent terms for free.
 *
 * `regression_priors_lp()` is the matching one-shot priors helper:
 * effect priors plus ARIMA priors (shocks, MA coefficients, latent
 * standard deviation; partial autocorrelations get an implicit
 * uniform prior via their parameter bounds). GP priors are supplied by
 * the separate `gp_priors_lp()` helper so the long argument list stays
 * manageable.
 *
 * Both layers are inert when their term is absent: when
 * `arima_present == 0` and `gp_present == 0`, `regression_predictor()`
 * returns the bare `combine_effects()` result; each `apply_*` call
 * short-circuits on its own presence flag.
 *
 * Every per-observation module routes through these helpers: `expr`,
 * `expl`, `refnp`, and `miss` apply the latent terms directly at the
 * observation level, while the sparse-row modules `refp` and `rep`
 * supply a `flat_idx` built from the joint (covariate row x time x
 * group) deduplication so the same gather works at sparse-row
 * granularity. The ARIMA and GP terms share this scheme. See
 * `vignettes/arima.Rmd` and `vignettes/gaussian-process.Rmd`.
 */
/**
 * Intercept centring offset for a fixed-effects design.
 *
 * Returns `dot(means_fixed, scaled_beta)`, the mean of the fixed-effect
 * contribution `X * scaled_beta` over the observations (with `means_fixed`
 * the observation-weighted column means of the design). Subtracting this
 * from the linear predictor centres the design so the intercept becomes
 * the predictor mean rather than its value at the covariate origin,
 * decorrelating the intercept from the slopes. brms centres the
 * population-level design matrix the same way; it then places the prior on
 * the centred intercept, whereas here the original-scale intercept is
 * recovered via `int_raw = int - offset` (an additive shift, so the change
 * of variables has unit Jacobian) and the user's prior is placed on the
 * recovered `int_raw`. A very tight intercept prior therefore reintroduces
 * a little of the intercept/slope coupling, but the user's stated prior is
 * honoured on the original-scale intercept.
 *
 * Returns 0 when there are no fixed effects (`neffs == 0`).
 */
real intercept_centring_offset(vector means_fixed, vector beta,
                               vector beta_sd, matrix rdesign, int neffs) {
  if (neffs == 0) return 0.0;
  vector[1 + num_elements(beta_sd)] ext_beta_sd = append_row(1.0, beta_sd);
  vector[neffs] scaled_beta = beta .* (rdesign * ext_beta_sd);
  return dot_product(means_fixed, scaled_beta);
}

/**
 * Bundle a module's design and latent centring offsets.
 *
 * Returns `(design, latent)`, where `design` is the fixed-effect design
 * offset (see `intercept_centring_offset`) and `latent` is the summed
 * grand-mean offsets of the integrated ARIMA and GP latents (see
 * `arima_latent_mean_offset` and `gp_latent_mean_offset`). A module
 * recovers its original-scale intercept as `int_c - design - latent` and
 * subtracts only `design` from the centred predictor (the latent is
 * already grand-mean centred in `apply_arima_residual` / `apply_gp_term`).
 * All shifts are additive, so the recovery has unit Jacobian. This keeps
 * the per-module recovery to a single call rather than three.
 */
tuple(real, real) centring_offsets(
  vector means_fixed, vector beta, vector beta_sd, matrix rdesign, int neffs,
  int centre,
  int arima_present, int arima_T, int arima_G,
  int arima_p, int arima_d, int arima_q,
  matrix arima_z, vector arima_pacf, vector arima_theta,
  array[] real arima_sigma,
  int gp_present, int gp_T, int gp_G, int gp_M, real gp_L,
  int gp_type, real gp_nu, int gp_d, matrix gp_PHI, matrix gp_eta,
  array[] real gp_rho, array[] real gp_alpha
) {
  real design = intercept_centring_offset(
    means_fixed, beta, beta_sd, rdesign, neffs
  );
  real latent = arima_latent_mean_offset(
    arima_present, centre, arima_T, arima_G, arima_p, arima_d, arima_q,
    arima_z, arima_pacf, arima_theta, arima_sigma
  ) + gp_latent_mean_offset(
    gp_present, centre, gp_T, gp_G, gp_M, gp_L, gp_type, gp_nu, gp_d,
    gp_PHI, gp_eta, gp_rho, gp_alpha
  );
  return (design, latent);
}

vector regression_predictor(
  array[] real intercept, vector beta, int nobs, int neffs,
  matrix fdesign,
  tuple(vector, array[] int, array[] int) sparse,
  vector beta_sd, matrix rdesign,
  int add_intercept, int sparse_design, int centre,
  int arima_present, int arima_T, int arima_G,
  int arima_p, int arima_d, int arima_q, int arima_n_obs,
  matrix arima_z, vector arima_pacf, vector arima_theta,
  array[] real arima_sigma,
  array[] int arima_flat_idx,
  int gp_present, int gp_T, int gp_G, int gp_M, real gp_L,
  int gp_type, real gp_nu, int gp_d, matrix gp_PHI, matrix gp_eta,
  array[] real gp_rho, array[] real gp_alpha,
  array[] int gp_flat_idx
) {
  // Short-circuit when neither latent term is present: return
  // combine_effects() directly so we skip materialising the
  // intermediate `base` vector and the apply_* call frames on every
  // gradient evaluation. Behaviour is identical when a term is present.
  // Design centring (the `- offset` shift) is a constant applied by the
  // caller, so it does not enter here.
  if (!arima_present && !gp_present) {
    return combine_effects(
      intercept, beta, nobs, neffs, fdesign, sparse, beta_sd, rdesign,
      add_intercept, sparse_design
    );
  }
  vector[nobs] base = combine_effects(
    intercept, beta, nobs, neffs, fdesign, sparse, beta_sd, rdesign,
    add_intercept, sparse_design
  );
  // `centre` is the free-intercept flag: an integrated residual is only
  // mean-centred when a free intercept exists to absorb the level it gives
  // up. ARIMA and GP compose additively; each `apply_*` is inert on its
  // own presence flag, so passing both through is safe when only one is set.
  base = apply_arima_residual(
    base, arima_n_obs, arima_present, centre, arima_T, arima_G,
    arima_p, arima_d, arima_q,
    arima_z, arima_pacf, arima_theta, arima_sigma,
    arima_flat_idx
  );
  return apply_gp_term(
    base, gp_present, centre, gp_T, gp_G, gp_M, gp_L, gp_type, gp_nu, gp_d,
    gp_PHI, gp_eta, gp_rho, gp_alpha, gp_flat_idx
  );
}

void regression_priors_lp(
  vector beta, vector beta_sd, array[,] real beta_sd_p,
  int fixed, int random,
  int arima_present, int arima_p, int arima_q,
  matrix arima_z, vector arima_pacf, vector arima_theta,
  array[] real arima_sigma, array[,] real arima_sigma_p,
  array[,] real arima_pacf_p
) {
  effect_priors_lp(beta, beta_sd, beta_sd_p, fixed, random);
  if (arima_present) {
    to_vector(arima_z) ~ std_normal();
    // Partial autocorrelations are Uniform(-1, 1) by default via their
    // parameter bounds. A positive prior sd switches to a Normal(mean, sd)
    // truncated to (-1, 1); the truncation constant is fixed by the bounds
    // and so is dropped. A non-positive sd leaves the Uniform default.
    if (arima_p > 0 && arima_pacf_p[2, 1] > 0) {
      arima_pacf ~ normal(arima_pacf_p[1, 1], arima_pacf_p[2, 1]);
    }
    if (arima_q > 0) {
      arima_theta ~ std_normal();
    }
    arima_sigma[1] ~ normal(
      arima_sigma_p[1, 1], arima_sigma_p[2, 1]
    ) T[0, ];
  }
}

/**
 * Priors for an approximate Gaussian process latent term.
 *
 * The spectral coefficients `eta` get a unit-normal (non-centred)
 * prior. The length scale `rho` gets a log-normal prior and the
 * magnitude `alpha` a half-normal prior, with each prior (mean, sd)
 * supplied as data. Inert when `gp_present == 0`.
 */
void gp_priors_lp(
  int gp_present, matrix gp_eta,
  array[] real gp_rho, array[] real gp_alpha,
  array[,] real gp_rho_p, array[,] real gp_alpha_p
) {
  if (gp_present) {
    to_vector(gp_eta) ~ std_normal();
    gp_rho[1] ~ lognormal(gp_rho_p[1, 1], gp_rho_p[2, 1]);
    gp_alpha[1] ~ normal(gp_alpha_p[1, 1], gp_alpha_p[2, 1]) T[0, ];
  }
}

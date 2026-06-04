/**
 * Single entry points for the regression layer.
 *
 * `regression_predictor()` composes `combine_effects()` (fixed +
 * partially-pooled random effects via the design matrices) with
 * `apply_arima_residual()` (parameter-dependent ARIMA(p, d, q) latent
 * residual). Each module that owns a per-observation predictor calls
 * this once instead of calling the two layers separately.
 *
 * `regression_priors_lp()` is the matching one-shot priors helper:
 * effect priors plus ARIMA priors (shocks, MA coefficients, latent
 * standard deviation; partial autocorrelations get an implicit
 * uniform prior via their parameter bounds).
 *
 * Both functions are inert with respect to the ARIMA term when
 * `arima_present == 0`: in that case `regression_predictor()` returns
 * the bare `combine_effects()` result, and `regression_priors_lp()`
 * skips the ARIMA prior block.
 *
 * Every per-observation module routes through these helpers: `expr`,
 * `expl`, `refnp`, and `miss` apply the ARIMA residual directly at the
 * observation level, while the sparse-row modules `refp` and `rep`
 * supply a `flat_idx` built from the joint (covariate row x ARIMA time
 * x ARIMA group) deduplication so the same gather works at sparse-row
 * granularity. See `vignettes/arima.Rmd` for the joint scheme.
 */
/**
 * Intercept centring offset for a fixed-effects design.
 *
 * Returns `dot(means_fixed, scaled_beta)`, the mean of the fixed-effect
 * contribution `X * scaled_beta` over the observations (with `means_fixed`
 * the observation-weighted column means of the design). Subtracting this
 * from the linear predictor centres the design so the intercept becomes
 * the predictor mean rather than its value at the covariate origin,
 * decorrelating the intercept from the slopes. This is the device brms
 * applies by default to the population-level design matrix. The same
 * offset recovers the original-scale intercept via `int_raw = int - offset`
 * (an additive shift, so the change of variables has unit Jacobian).
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
  array[] int arima_flat_idx
) {
  // Short-circuit the no-ARIMA path (arima_present == 0): return
  // combine_effects() directly so we skip materialising the
  // intermediate `base` vector and the apply_arima_residual() call
  // frame on every gradient evaluation. Behaviour is identical when an
  // ARIMA term is present. Design centring (the `- offset` shift) is a
  // constant and is applied by the caller, so it does not enter here.
  if (!arima_present) {
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
  // mean-centred when a free intercept exists to absorb the level it
  // gives up. Intercept-less modules keep the raw series so no signal is
  // lost.
  return apply_arima_residual(
    base, arima_n_obs, arima_present, centre, arima_T, arima_G,
    arima_p, arima_d, arima_q,
    arima_z, arima_pacf, arima_theta, arima_sigma,
    arima_flat_idx
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

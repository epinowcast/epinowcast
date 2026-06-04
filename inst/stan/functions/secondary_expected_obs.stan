/**
 * Expected secondary observations from the primary expectation
 *
 * For each group, convolves the expected primary observations with the
 * secondary delay, applies the per-reference-date scaling, and combines the
 * convolved and scaled terms into the secondary target (incidence or
 * prevalence) via `calculate_secondary()`.
 *
 * The delay is supplied as a sparse convolution matrix (extracted with
 * `csr_extract` on the R-side `convolution_matrix()` output). Scaling is a
 * log-scale per-reference-date predictor shared across groups.
 *
 * @param exp_lobs Array of log expected primary observations by group.
 *
 * @param sec_delay_n Length of the secondary delay (1 for no delay).
 *
 * @param w, v, u Sparse convolution matrix components from `csr_extract`.
 *
 * @param sec_lscale Log-scale scaling predictor by reference date (length t).
 *
 * @param sec_obs Observed secondary counts by group (flattened), used to seed
 *   the cumulative target.
 *
 * @param t Number of reference dates per group.
 *
 * @param g Number of groups.
 *
 * @param cumulative, historic, primary_hist_additive, current,
 *   primary_current_additive Secondary target switches (see
 *   `calculate_secondary()`).
 *
 * @param predict Number of time points to predict for cumulative seeding.
 *
 * @return Array of log expected secondary observations by group.
 */
array[] vector secondary_expected_obs(
  array[] vector exp_lobs, int sec_delay_n, vector w, array[] int v,
  array[] int u, vector sec_lscale, array[,] int sec_obs, int t, int g,
  int cumulative, int historic, int primary_hist_additive, int current,
  int primary_current_additive, int predict
) {
  array[g] vector[t] exp_lsec;
  vector[t] scale = exp(sec_lscale);
  for (k in 1:g) {
    vector[t] primary = exp(exp_lobs[k]);
    vector[t] conv;
    if (sec_delay_n == 1) {
      conv = primary;
    } else {
      conv = csr_matrix_times_vector(t, t, w, v, u, primary);
    }
    vector[t] scaled = scale .* primary;
    vector[t] sec = calculate_secondary(
      scaled, scale .* conv, sec_obs[k], cumulative, historic,
      primary_hist_additive, current, primary_current_additive, predict
    );
    exp_lsec[k] = log(sec);
  }
  return exp_lsec;
}

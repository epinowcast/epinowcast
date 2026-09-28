// Pure Stan reference for renewal_depletion(), used only by the tests.
// Mirrors the `gt_n > 1` branch of log_expected_latent_from_r() in
// inst/stan/functions/log_expected_latent_from_r.stan for a single group,
// generalised over the seed/generation-time length (always equal to
// `r_seed` = `gt_n` in that function) so it can be called standalone. Kept
// byte-for-byte equivalent to the model code: any change there must be
// mirrored here, and test-stan_renewal_depletion.R checks the two agree.

/**
 * The renewal loop, with optional susceptible depletion, in pure Stan.
 * Same arguments and return value as renewal_depletion().
 */
vector renewal_depletion_stan(vector seed, vector R, vector rgt, real pop,
                              int use_pop, real pop_floor) {
  int n0 = num_elements(seed);
  int r_t = num_elements(R);
  int t = n0 + r_t;
  vector[t] exp_obs;
  exp_obs[1:n0] = seed;
  if (use_pop) {
    real cum_cases = sum(seed);
    for (i in 1:r_t) {
      real infectiousness = dot_product(segment(exp_obs, i, n0), rgt);
      real remaining_susceptible = fmax(0, pop - cum_cases);
      real denom = fmax(pop_floor, remaining_susceptible);
      real adj = 1 - exp(-R[i] * infectiousness / denom);
      exp_obs[n0 + i] = fmax(1e-8, remaining_susceptible * adj);
      cum_cases += exp_obs[n0 + i];
    }
  } else {
    for (i in 1:r_t) {
      exp_obs[n0 + i] = R[i] * dot_product(segment(exp_obs, i, n0), rgt);
    }
  }
  return exp_obs;
}

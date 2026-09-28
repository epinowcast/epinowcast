/**
 * Renewal equation with optional susceptible depletion (pure Stan)
 *
 * Reference implementation of `renewal_depletion()`, which the package
 * calls through a C++ implementation
 * (inst/include/epinowcast/renewal_depletion.hpp) when the C++ adjoint
 * path is enabled (see `epinowcast.use_cpp` in `enw_model()`). Used as
 * the fallback implementation when the C++ path is disabled, and by the
 * tests to check that implementation's values and gradients. Kept
 * byte-for-byte equivalent to the loop it replaced in
 * log_expected_latent_from_r.stan.
 *
 * @param seed Seeding latent values, length n0.
 *
 * @param r Reproduction numbers / growth multipliers, length r_t.
 *
 * @param rgt Generation-time weight vector, length n0.
 *
 * @param pop Initial susceptible population. Ignored when `use_pop ==
 * 0`.
 *
 * @param use_pop Susceptible-depletion switch (0 off, 1 on).
 *
 * @param pop_floor Minimum susceptible population, floored on the
 * transmission-rate denominator only. Only used when `use_pop == 1`.
 *
 * @return Vector of length `n0 + r_t`: seed followed by the post-seed
 * latent series.
 */
vector renewal_depletion_stan(vector seed, vector r, vector rgt, real pop,
                              int use_pop, real pop_floor) {
  int n0 = num_elements(seed);
  int r_t = num_elements(r);
  int t = n0 + r_t;
  vector[t] exp_obs;
  exp_obs[1:n0] = seed;
  if (use_pop) {
    real cum_cases = sum(seed);
    for (i in 1:r_t) {
      real infectiousness = dot_product(segment(exp_obs, i, n0), rgt);
      real remaining_susceptible = fmax(0, pop - cum_cases);
      real denom = fmax(pop_floor, remaining_susceptible);
      real adj = 1 - exp(-r[i] * infectiousness / denom);
      exp_obs[n0 + i] = fmax(1e-8, remaining_susceptible * adj);
      cum_cases += exp_obs[n0 + i];
    }
  } else {
    for (i in 1:r_t) {
      exp_obs[n0 + i] = r[i] * dot_product(segment(exp_obs, i, n0), rgt);
    }
  }
  return exp_obs;
}

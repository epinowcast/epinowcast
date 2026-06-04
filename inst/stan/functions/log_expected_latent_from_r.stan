/**
 * Extract log growth rates for a specific group
 *
 * @param r Vector of all group growth rates concatenated.
 * @param r_g Array of indices marking the start of each group in r.
 * @param k Group index (1-indexed).
 * @param r_t Number of time periods.
 *
 * @return Vector of log growth rates for group k.
 */
vector extract_group_rates(vector r, array[] int r_g, int k, int r_t) {
  return segment(r, r_g[k] + 1, r_t);
}

/**
 * Iteratively compute expected latent values using the renewal equation
 * 
 * This function calculates expected latent values over time for different
 * groups using the renewal equation. It's designed to handle scenarios where
 * the generation time is represented either as a constant (leading to
 * exponential growth) or as a vector (requiring a dot product calculation).
 * The function operates on the natural scale for stability and then transforms 
 * the results back to the log scale when the generation time is a vector.
 * 
 * @param lexp_latent_int Matrix of initial log expected latent values.
 *
 * @param r Vector representing growth rate or the log of the effective 
 * reproduction number.
 *
 * @param r_g Array of indices marking the start of each group in the rate
 * vector.
 * @param r_t Number of time periods for rate adjustments.
 *
 * @param r_seed Seed time period for rate-based adjustments.
 *
 * @param gt_n Length of the generation time vector (1 for constant generation
 * time).
 *
 * @param lrgt Log of the generation time vector or scalar.
 *
 * @param t Total number of time periods.
 *
 * @param g Number of groups.
 *
 * @param pop Vector of initial susceptible population sizes (one per group).
 * Ignored when `use_pop == 0`. Otherwise transmission is scaled by the
 * remaining susceptible fraction and the susceptible pool is depleted by
 * modelled new latent cases each step.
 *
 * @param use_pop Susceptible-depletion adjustment switch. 0 = no adjustment
 * (default, unadjusted renewal equation); > 0 = apply the susceptible-depletion
 * adjustment. When enabled the adjusted bounded-exponential recursion is run
 * for the whole post-seed series so the susceptible pool stays internally
 * consistent (see note). The specific positive value carries the user-facing
 * `population_period` choice but does not change the recursion.
 *
 * @param pop_floor Minimum susceptible population used as a numerical-stability
 * floor, preventing instability as the susceptible pool approaches zero. Only
 * used when `use_pop > 0`.
 *
 * @return An array of vectors containing log-transformed expected latent
 * values for each group and time period.
 *
 * @note The function performs the following operations:
 *       1. For each group:
 *          a. Extracts a segment of rates specific to the current group.
 *          b. If 'gt_n' is 1 (constant generation time), directly applies a
 *             cumulative sum on the log scale to model exponential growth.
 *          c. If 'gt_n' > 1 (vector generation time):
 *             i. Converts the log rate and log initial latent values to the
 *                natural scale.
 *             ii. Uses a dot product with the generation time vector for each
 *                 time point, following the renewal equation.
 *             iii. Optionally scales transmission by the remaining susceptible
 *                  fraction (susceptible depletion) when `use_pop > 0`.
 *             iv. Converts the resulting expected values back to the log
 *                  scale, as this approach is expected to be more numerically
 *                  stable than performing the renewal equation directly in log
 *                  space.
 *
 * When `use_pop > 0` the adjusted bounded-exponential recursion is applied to
 * every post-seed time point (not just a forecast window). This keeps the
 * cumulative-case / susceptible-pool trajectory internally consistent: gating
 * the adjustment on only part of the series would let larger unadjusted
 * in-data incidence over-deplete the pool, biasing the reproduction number
 * downwards in the remainder. The per-group `pop[k]` is each group's own
 * initial susceptible population (groups are treated independently).
 *
 * Two numerical floors are used and are distinct:
 *   - `pop_floor` is the user-facing minimum susceptible population (see the
 *     `population_floor` argument of `enw_expectation()`); it bounds the
 *     denominator of the susceptible fraction.
 *   - a small fixed `1e-8` floor is applied to the adjusted new cases. This is
 *     load-bearing: as the pool nears exhaustion the bounded-exponential term
 *     can return (numerically) zero, and the subsequent `log()` would be
 *     `-inf`; the floor pins incidence at a tiny positive value so the
 *     log-scale latent series stays finite. It is not user-configurable and is
 *     unrelated to `pop_floor`.
 *
 * The susceptible-depletion adjustment is adapted from EpiNow2
 * (epiforecasts/EpiNow2, MIT licence, (c) 2020 EpiForecasts), specifically the
 * `generate_infections()` renewal step in
 * `inst/stan/functions/infections.stan`. It assumes a single well-mixed
 * population per group with no waning of immunity and no births or deaths, so
 * the susceptible pool is only ever depleted by modelled new latent cases.
 */
array[] vector log_expected_latent_from_r(
  matrix lexp_latent_int, vector r, array[] int r_g, int r_t,
  int r_seed, int gt_n, vector lrgt, int t, int g,
  vector pop, int use_pop, real pop_floor
) {
  array[g] vector[t] exp_lobs;

  if (gt_n == 1) {
    // Exponential growth: cumulative sum on log scale
    vector[r_t] local_r;
    for (k in 1:g) {
      local_r = extract_group_rates(r, r_g, k, r_t);
      exp_lobs[k][1] = lexp_latent_int[1, k];
      exp_lobs[k][(r_seed + 1):t] = exp_lobs[k][1] + cumulative_sum(local_r);
    }
  } else {
    // Renewal equation: work on natural scale for numerical stability
    vector[gt_n] rgt = exp(lrgt);
    vector[t] exp_obs;
    vector[r_t] local_R;
    for (k in 1:g) {
      // Extract and exponentiate growth rates in one step
      local_R = exp(extract_group_rates(r, r_g, k, r_t));
      exp_obs[1:r_seed] = exp(lexp_latent_int[1:r_seed, k]);
      if (use_pop) {
        // Cumulative latent cases (including seeded cases) consumed from the
        // susceptible pool. Adapted from EpiNow2's generate_infections(). The
        // adjusted recursion is applied throughout so the pool trajectory is
        // internally consistent (see function note).
        real cum_cases = sum(exp_obs[1:r_seed]);
        for (i in 1:r_t) {
          // Infectiousness: convolution of recent cases with generation time
          real infectiousness = dot_product(
            segment(exp_obs, r_seed + i - gt_n, gt_n), rgt
          );
          // Scale transmission by the remaining susceptible fraction and
          // deplete the pool by the modelled new cases. `pop_floor` bounds the
          // denominator; the fixed 1e-8 floor keeps the subsequent log()
          // finite near pool exhaustion (see note).
          real susceptible = fmax(pop_floor, pop[k] - cum_cases);
          real adj = 1 - exp(-local_R[i] * infectiousness / susceptible);
          exp_obs[r_seed + i] = fmax(1e-8, susceptible * adj);
          cum_cases += exp_obs[r_seed + i];
        }
      } else {
        // Convolve recent cases with generation time to get new cases
        for (i in 1:r_t) {
          exp_obs[r_seed + i] = local_R[i] * dot_product(
            segment(exp_obs, r_seed + i - gt_n, gt_n), rgt
          );
        }
      }
      exp_lobs[k] = log(exp_obs);
    }
  }
  return(exp_lobs);
}

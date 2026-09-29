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
 * @param pop Initial susceptible population per group. Ignored when
 * `use_pop == 0`.
 *
 * @param use_pop Susceptible-depletion switch (0 = off, 1 = on). When on,
 * transmission is scaled by the remaining susceptible fraction over the whole
 * post-seed series.
 *
 * @param pop_floor Minimum susceptible population, floored on the
 * transmission-rate denominator only. Matches EpiNow2's `rt_opts(pop_floor)`.
 * Only used when `use_pop > 0`.
 *
 * @param mixing A `g x g` mixing matrix redistributing each group's
 * generation-time-weighted incidence pressure across groups before `R_t` is
 * applied, `Lambda[k] = sum_h mixing[k, h] * lambda[h]` where `lambda[h]` is
 * group `h`'s own convolved history. Ignored when `use_mixing == 0`. Row `k`
 * says where group `k`'s force of infection comes from; the identity matrix
 * leaves groups uncoupled.
 *
 * @param use_mixing Cross-group mixing switch (0 = off, 1 = on). Only used on
 * the renewal path (`gt_n > 1`); `use_mixing == 0` runs the independent-groups
 * loop, with no cross-group term.
 *
 * @return An array of vectors of log-transformed expected latent values by
 * group and time.
 *
 * @note For each group: when `gt_n == 1` exponential growth is computed as a
 * cumulative sum on the log scale; when `gt_n > 1` the renewal equation is
 * applied on the natural scale (more stable) and logged afterwards.
 *
 * When `use_pop > 0`, new cases are capped by the remaining susceptibles
 * (`fmax(0, pop - cum_cases)`) so depletion cannot exceed the pool, and a
 * small `1e-8` floor keeps the subsequent `log()` finite near exhaustion.
 * With `use_mixing == 0` groups are independent well-mixed populations with
 * no waning or vital dynamics. Adapted from EpiNow2's `generate_infections()`
 * (epiforecasts/EpiNow2, MIT licence).
 *
 * When `use_mixing > 0`, mixing is applied to each group's convolved
 * incidence pressure before `R_t` and before any susceptible-depletion
 * adjustment, so a group's depletion still tracks its own pool while its
 * force of infection can be driven by other groups' histories.
 */
array[] vector log_expected_latent_from_r(
  matrix lexp_latent_int, vector r, array[] int r_g, int r_t,
  int r_seed, int gt_n, vector lrgt, int t, int g,
  vector pop, int use_pop, real pop_floor,
  matrix mixing, int use_mixing
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
  } else if (use_mixing) {
    // Renewal equation with cross-group mixing: all groups are advanced
    // together, time loop outermost, because each group's force of infection
    // at time i depends on every group's convolved history at i.
    vector[gt_n] rgt = exp(lrgt);
    array[g] vector[t] exp_obs;
    array[g] vector[r_t] local_R;
    vector[g] cum_cases = rep_vector(0, g);
    for (k in 1:g) {
      local_R[k] = exp(extract_group_rates(r, r_g, k, r_t));
      exp_obs[k][1:r_seed] = exp(lexp_latent_int[1:r_seed, k]);
      if (use_pop) {
        cum_cases[k] = sum(exp_obs[k][1:r_seed]);
      }
    }
    for (i in 1:r_t) {
      vector[g] lambda;
      for (h in 1:g) {
        // Each group's own generation-time-weighted incidence pressure,
        // before mixing redistributes it.
        lambda[h] = dot_product(
          segment(exp_obs[h], r_seed + i - gt_n, gt_n), rgt
        );
      }
      vector[g] mixed = mixing * lambda;
      for (k in 1:g) {
        if (use_pop) {
          real remaining_susceptible = fmax(0, pop[k] - cum_cases[k]);
          real denom = fmax(pop_floor, remaining_susceptible);
          real adj = 1 - exp(-local_R[k][i] * mixed[k] / denom);
          exp_obs[k][r_seed + i] = fmax(1e-8, remaining_susceptible * adj);
          cum_cases[k] += exp_obs[k][r_seed + i];
        } else {
          exp_obs[k][r_seed + i] = local_R[k][i] * mixed[k];
        }
      }
    }
    for (k in 1:g) {
      exp_lobs[k] = log(exp_obs[k]);
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
        // Cumulative cases consumed from the pool (incl. seeds).
        real cum_cases = sum(exp_obs[1:r_seed]);
        for (i in 1:r_t) {
          real infectiousness = dot_product(
            segment(exp_obs, r_seed + i - gt_n, gt_n), rgt
          );
          // Scale by remaining susceptible fraction; cap new cases by the pool.
          real remaining_susceptible = fmax(0, pop[k] - cum_cases);
          real denom = fmax(pop_floor, remaining_susceptible);
          real adj = 1 - exp(-local_R[i] * infectiousness / denom);
          exp_obs[r_seed + i] = fmax(1e-8, remaining_susceptible * adj);
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

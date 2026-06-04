/**
 * Vendored primary event censored distribution functions
 *
 * These Stan functions are vendored from the primarycensored R package
 * (version 1.5.0), part of the epinowcast organisation, available at
 * https://github.com/epinowcast/primarycensored and documented at
 * https://primarycensored.epinowcast.org.
 *
 * They implement the double interval censoring discretisation described in
 * Park et al. and the primarycensored documentation: a continuous delay
 * distribution is convolved with a uniform primary event window and then
 * interval censored on the secondary (reporting) side, with optional right
 * truncation. This is a more exact alternative to the uniform-interval
 * approximation used by discretised_logit_hazard().
 *
 * primarycensored is distributed under the MIT licence (Copyright (c) 2024
 * primarycensored authors). The licence text is reproduced in
 * inst/stan/functions/LICENSE.primarycensored. Both primarycensored and
 * epinowcast are MIT licensed and maintained by the epinowcast organisation.
 *
 * Sourced files (concatenated, unmodified except for this header):
 *   - primarycensored.stan
 *   - primarycensored_ode.stan
 *   - primarycensored_analytical_cdf.stan
 *   - expgrowth.stan
 *
 * Distribution identifiers follow primarycensored's pcd_stan_dist_id()
 * convention (1: lognormal, 2: gamma, 3: weibull, 4: exponential, ...), which
 * differs from epinowcast's internal model_refp ids. Translation is handled by
 * the discretised_pcens_* wrapper in primarycensored_pmf.stan.
 */

// ===== primarycensored.stan =====
/**
  * Primary event censored distribution functions
  */

/**
  * Compute the log normalizer for truncation: log(F(D) - F(L))
  * @ingroup truncation_helpers
  *
  * @param log_cdf_D Log CDF at upper truncation point D
  * @param log_cdf_L Log CDF at lower truncation point L (negative_infinity if
  *   L = -inf, i.e. no lower truncation)
  * @param L Lower truncation point (-inf indicates no lower truncation)
  *
  * @return Log normalizer for truncation
  */
real primarycensored_log_normalizer(real log_cdf_D, real log_cdf_L, real L) {
  if (!is_inf(L)) {
    return log_diff_exp(log_cdf_D, log_cdf_L);
  } else {
    return log_cdf_D;
  }
}

/**
  * Apply truncation normalization to a log CDF value
  * @ingroup truncation_helpers
  *
  * Computes log((F(x) - F(L)) / (F(D) - F(L)))
  *
  * @param log_cdf Log CDF value to normalize
  * @param log_cdf_L Log CDF at lower truncation point L (negative_infinity if
  *   L = -inf, i.e. no lower truncation)
  * @param log_normalizer Log normalizer from primarycensored_log_normalizer
  * @param L Lower truncation point (-inf indicates no lower truncation)
  *
  * @return Normalized log CDF value
  */
real primarycensored_apply_truncation(real log_cdf, real log_cdf_L,
                                      real log_normalizer, real L) {
  if (!is_inf(L)) {
    return log_diff_exp(log_cdf, log_cdf_L) - log_normalizer;
  } else {
    return log_cdf - log_normalizer;
  }
}

/**
  * Compute log CDFs at both truncation bounds L and D
  * @ingroup truncation_helpers
  *
  * @param L Lower truncation point (-inf indicates no lower truncation)
  * @param D Upper truncation point (+inf indicates no upper truncation)
  * @param dist_id Distribution identifier
  * @param params Array of distribution parameters
  * @param pwindow Primary event window
  * @param primary_id Primary distribution identifier
  * @param primary_params Primary distribution parameters
  *
  * @return 2-element vector: [log_cdf_L, log_cdf_D]
  *
  * @note F(L) for finite L is computed via primarycensored_lcdf with internal
  *   bounds `[0, +inf]` for distributions with non-negative support and
  *   `[-inf, +inf]` for distributions with support on the reals, controlled
  *   by `dist_has_positive_support(dist_id)`. The positive-support branch
  *   lets the `d <= L` early-exit short-circuit `F(L) = 0` for `L <= 0`,
  *   while the real-support branch evaluates the underlying CDF directly so
  *   F(L) is non-zero for negative L.
  */
vector primarycensored_truncation_bounds(
  data real L, data real D,
  data int dist_id, array[] real params, data real pwindow,
  data int primary_id, array[] real primary_params
) {
  vector[2] result;
  // Internal lower bound for the un-truncated distribution: 0 lets the
  // `d <= L` early-exit in primarycensored_lcdf return -inf for delays below
  // the natural support of positive-support distributions; -inf disables that
  // short-circuit so distributions with support on the reals are integrated.
  // Expression is inlined (rather than bound to a local) so Stan's data-flow
  // checker recognises it as data-only.

  // Get CDF at lower truncation point L
  if (is_inf(L)) {
    result[1] = negative_infinity();
  } else {
    result[1] = primarycensored_lcdf(
      L | dist_id, params, pwindow,
      dist_has_positive_support(dist_id) ? 0.0 : negative_infinity(),
      positive_infinity(), primary_id, primary_params
    );
  }

  // Get CDF at upper truncation point D
  if (is_inf(D)) {
    result[2] = 0;
  } else {
    result[2] = primarycensored_lcdf(
      D | dist_id, params, pwindow,
      dist_has_positive_support(dist_id) ? 0.0 : negative_infinity(),
      positive_infinity(), primary_id, primary_params
    );
  }

  return result;
}

/**
  * Compute the primary event censored CDF for a single delay
  * @ingroup primary_censored_single
  *
  * @param d Delay
  * @param dist_id Distribution identifier
  * @param params Array of distribution parameters
  * @param pwindow Primary event window
  * @param L Minimum delay (lower truncation point)
  * @param D Maximum delay (upper truncation point)
  * @param primary_id Primary distribution identifier
  * @param primary_params Primary distribution parameters
  *
  * @return Primary event censored CDF, normalized over [L, D] if truncation
  * is applied
  */
real primarycensored_cdf(data real d, data int dist_id, array[] real params,
                               data real pwindow, data real L, data real D,
                               data int primary_id,
                               array[] real primary_params) {
  real result;
  if (d <= L) {
    return 0;
  }

  if (d >= D) {
    return 1;
  }

  // Check if an analytical solution exists
  if (check_for_analytical(dist_id, primary_id)) {
    // Use analytical solution
    result = primarycensored_analytical_cdf(
      d | dist_id, params, pwindow, L, D, primary_id, primary_params
    );
  } else {
    // Use numerical integration for other cases. The integration variable
    // ranges over the primary-event time, so the natural lower bound is
    // d - pwindow. For positive-support delays the integrand `F_delay(t)` is
    // 0 for t <= 0, so an unclipped lower bound just adds a flat zero region
    // for negative t. Distributions with support on the reals also accept the
    // unclipped lower bound directly.
    real lower_bound = d - pwindow;
    int n_params = num_elements(params);
    int n_primary_params = num_elements(primary_params);
    array[n_params + n_primary_params] real theta = append_array(params, primary_params);
    array[4] int ids = {dist_id, primary_id, n_params, n_primary_params};

    vector[1] y0 = rep_vector(0.0, 1);
    result = ode_rk45(primarycensored_ode, y0, lower_bound, {d}, theta, {d, pwindow}, ids)[1, 1];

    // Apply truncation normalization on log scale for numerical stability
    if (!is_inf(D) || !is_inf(L)) {
      real log_result = log(result);
      vector[2] bounds = primarycensored_truncation_bounds(
        L, D, dist_id, params, pwindow, primary_id, primary_params
      );
      real log_cdf_L = bounds[1];
      real log_cdf_D = bounds[2];

      real log_normalizer = primarycensored_log_normalizer(log_cdf_D, log_cdf_L, L);
      log_result = primarycensored_apply_truncation(
        log_result, log_cdf_L, log_normalizer, L
      );
      result = exp(log_result);
    }
  }

  return result;
}

/**
  * Compute the primary event censored log CDF for a single delay
  * @ingroup primary_censored_single
  *
  * @param d Delay
  * @param dist_id Distribution identifier
  * @param params Array of distribution parameters
  * @param pwindow Primary event window
  * @param L Minimum delay (lower truncation point)
  * @param D Maximum delay (upper truncation point)
  * @param primary_id Primary distribution identifier
  * @param primary_params Primary distribution parameters
  *
  * @return Primary event censored log CDF, normalized over [L, D] if truncation
  * is applied
  *
  * @code
  * // Example: Weibull delay distribution with uniform primary distribution
  * real d = 3.0;
  * int dist_id = 3; // Weibull
  * array[2] real params = {2.0, 1.5}; // shape and scale
  * real pwindow = 1.0;
  * real L = 0.0;
  * real D = positive_infinity();
  * int primary_id = 1; // Uniform
  * array[0] real primary_params = rep_array(0.0, 0);
  * real log_cdf = primarycensored_lcdf(
  *   d, dist_id, params, pwindow, L, D, primary_id, primary_params
  * );
  * @endcode
  */
real primarycensored_lcdf(data real d, data int dist_id, array[] real params,
                                data real pwindow, data real L, data real D,
                                data int primary_id,
                                array[] real primary_params) {
  real result;

  if (d <= L) {
    return negative_infinity();
  }

  if (d >= D) {
    return 0;
  }

  // Check if an analytical solution exists. The internal lower bound is 0 for
  // positive-support delays (lets the d <= L early-exit return -inf for d <= 0)
  // and -inf for distributions with support on the reals.
  if (check_for_analytical(dist_id, primary_id)) {
    result = primarycensored_analytical_lcdf(
      d | dist_id, params, pwindow,
      dist_has_positive_support(dist_id) ? 0.0 : negative_infinity(),
      positive_infinity(), primary_id, primary_params
    );
  } else {
    // Use numerical integration
    result = log(primarycensored_cdf(
      d | dist_id, params, pwindow,
      dist_has_positive_support(dist_id) ? 0.0 : negative_infinity(),
      positive_infinity(), primary_id, primary_params
    ));
  }

  // Handle truncation normalization
  if (!is_inf(D) || !is_inf(L)) {
    vector[2] bounds = primarycensored_truncation_bounds(
      L, D, dist_id, params, pwindow, primary_id, primary_params
    );
    real log_cdf_L = bounds[1];
    real log_cdf_D = bounds[2];

    real log_normalizer = primarycensored_log_normalizer(log_cdf_D, log_cdf_L, L);
    result = primarycensored_apply_truncation(result, log_cdf_L, log_normalizer, L);
  }

  return result;
}

/**
  * Compute the primary event censored log PMF for a single delay
  * @ingroup primary_censored_single
  *
  * @param d Delay (integer)
  * @param dist_id Distribution identifier
  * @param params Array of distribution parameters
  * @param pwindow Primary event window
  * @param d_upper Upper bound for the delay interval
  * @param L Minimum delay (lower truncation point)
  * @param D Maximum delay (upper truncation point)
  * @param primary_id Primary distribution identifier
  * @param primary_params Primary distribution parameters
  *
  * @return Primary event censored log PMF, normalized over [L, D] if truncation
  * is applied
  *
  * @code
  * // Example: Weibull delay distribution with uniform primary distribution
  * int d = 3;
  * int dist_id = 3; // Weibull
  * array[2] real params = {2.0, 1.5}; // shape and scale
  * real pwindow = 1.0;
  * real d_upper = 4.0;
  * real L = 0.0;
  * real D = positive_infinity();
  * int primary_id = 1; // Uniform
  * array[0] real primary_params = {};
  * real log_pmf = primarycensored_lpmf(
  *   d, dist_id, params, pwindow, d_upper, L, D, primary_id, primary_params
  * );
  * @endcode
  */
real primarycensored_lpmf(data int d, data int dist_id, array[] real params,
                                data real pwindow, data real d_upper,
                                data real L, data real D, data int primary_id,
                                array[] real primary_params) {
  if (d_upper > D) {
    reject("Upper truncation point is greater than D. It is ", d_upper,
           " and D is ", D, ". Resolve this by increasing D to be greater or equal to d + swindow or decreasing swindow.");
  }
  if (d_upper <= d) {
    reject("Upper truncation point is less than or equal to d. It is ", d_upper,
           " and d is ", d, ". Resolve this by increasing d to be less than d_upper.");
  }
  if (d < L) {
    return negative_infinity();
  }
  real log_cdf_upper = primarycensored_lcdf(
    d_upper | dist_id, params, pwindow,
    dist_has_positive_support(dist_id) ? 0.0 : negative_infinity(),
    positive_infinity(), primary_id, primary_params
  );
  real log_cdf_lower = primarycensored_lcdf(
    d | dist_id, params, pwindow,
    dist_has_positive_support(dist_id) ? 0.0 : negative_infinity(),
    positive_infinity(), primary_id, primary_params
  );

  // Apply truncation normalization: log((F(d_upper) - F(d)) / (F(D) - F(L)))
  if (!is_inf(D) || !is_inf(L)) {
    real log_cdf_D;
    real log_cdf_L;

    // Get CDF at lower truncation point L
    if (is_inf(L)) {
      // No left truncation (L = -inf sentinel)
      log_cdf_L = negative_infinity();
    } else if (d == L) {
      // Reuse already computed CDF at d
      log_cdf_L = log_cdf_lower;
    } else {
      // Compute CDF at L directly
      log_cdf_L = primarycensored_lcdf(
        L | dist_id, params, pwindow,
        dist_has_positive_support(dist_id) ? 0.0 : negative_infinity(),
        positive_infinity(), primary_id, primary_params
      );
    }

    // Get CDF at upper truncation point D
    if (d_upper == D) {
      log_cdf_D = log_cdf_upper;
    } else if (is_inf(D)) {
      log_cdf_D = 0;
    } else {
      log_cdf_D = primarycensored_lcdf(
        D | dist_id, params, pwindow,
        dist_has_positive_support(dist_id) ? 0.0 : negative_infinity(),
        positive_infinity(), primary_id, primary_params
      );
    }

    real log_normalizer = primarycensored_log_normalizer(log_cdf_D, log_cdf_L, L);
    return log_diff_exp(log_cdf_upper, log_cdf_lower) - log_normalizer;
  } else {
    return log_diff_exp(log_cdf_upper, log_cdf_lower);
  }
}

/**
  * Compute the primary event censored PMF for a single delay
  * @ingroup primary_censored_single
  *
  * @param d Delay (integer)
  * @param dist_id Distribution identifier
  * @param params Array of distribution parameters
  * @param pwindow Primary event window
  * @param d_upper Upper bound for the delay interval
  * @param L Minimum delay (lower truncation point)
  * @param D Maximum delay (upper truncation point)
  * @param primary_id Primary distribution identifier
  * @param primary_params Primary distribution parameters
  *
  * @return Primary event censored PMF, normalized over [L, D] if truncation
  * is applied
  *
  * @code
  * // Example: Weibull delay distribution with uniform primary distribution
  * int d = 3;
  * int dist_id = 3; // Weibull
  * array[2] real params = {2.0, 1.5}; // shape and scale
  * real pwindow = 1.0;
  * real swindow = 1.0;
  * real d_upper = d + swindow; // = 4.0
  * real L = 0.0;
  * real D = positive_infinity();
  * int primary_id = 1; // Uniform
  * array[0] real primary_params = {};
  * real pmf = primarycensored_pmf(d, dist_id, params, pwindow, d_upper, L, D, primary_id, primary_params);
  * @endcode
  */
real primarycensored_pmf(data int d, data int dist_id, array[] real params,
                               data real pwindow, data real d_upper,
                               data real L, data real D, data int primary_id,
                               array[] real primary_params) {
  return exp(
    primarycensored_lpmf(
      d | dist_id, params, pwindow, d_upper, L, D, primary_id, primary_params
    )
  );
}

/**
  * Compute the primary event censored log PMF for integer delays up to max_delay
  * @ingroup primary_censored_vectorized
  *
  * @param max_delay Maximum delay to compute PMF for
  * @param L Minimum delay (lower truncation point)
  * @param D Maximum delay (upper truncation point), must be at least max_delay + 1
  * @param dist_id Distribution identifier
  * @param params Array of distribution parameters
  * @param pwindow Primary event window
  * @param primary_id Primary distribution identifier
  * @param primary_params Primary distribution parameters
  *
  * @return Vector of primary event censored log PMFs for delays \[0, 1\] to
  * \[max_delay, max_delay + 1\].
  *
  * This function differs from primarycensored_lpmf in that it:
  * 1. Computes PMFs for all integer delays from \[0, 1\] to \[max_delay,
  *    max_delay + 1\] in one call.
  * 2. Assumes integer delays (swindow = 1)
  * 3. Is more computationally efficient for multiple delay calculation as it
  *    reduces the number of integration calls.
  *
  * @code
  * // Example: Weibull delay distribution with uniform primary distribution
  * int max_delay = 10;
  * real L = 0.0;
  * real D = 15.0;
  * int dist_id = 3; // Weibull
  * array[2] real params = {2.0, 1.5}; // shape and scale
  * real pwindow = 7.0;
  * int primary_id = 1; // Uniform
  * array[0] real primary_params = {};

  * vector[max_delay] log_pmf =
  *   primarycensored_sone_lpmf_vectorized(
  *      max_delay, L, D, dist_id, params, pwindow, primary_id,
  *      primary_params
  *   );
  * @endcode
  */
vector primarycensored_sone_lpmf_vectorized(
  data int max_delay, data real L, data real D, data int dist_id,
  array[] real params, data real pwindow,
  data int primary_id, array[] real primary_params
) {

  int upper_interval = max_delay + 1;
  vector[upper_interval] log_pmfs;
  vector[upper_interval] log_cdfs;
  real log_normalizer;

  // Check if D is at least max_delay + 1
  if (D < upper_interval) {
    reject("D must be at least max_delay + 1");
  }

  // Compute log CDFs (without truncation normalization). The internal lower
  // bound below is 0 for positive-support delays and -inf otherwise; it is
  // inlined rather than bound to a local so Stan's type checker treats it as
  // data-only.
  // Start from max(1, floor(L)) to avoid computing unused CDFs when L > 0;
  // for L <= 0 (including -inf) start at 1 since F(d) = 0 for d <= 0.
  int start_idx = (!is_inf(L) && L > 0) ? max(1, to_int(floor(L))) : 1;
  for (d in start_idx:upper_interval) {
    log_cdfs[d] = primarycensored_lcdf(
      d | dist_id, params, pwindow,
      dist_has_positive_support(dist_id) ? 0.0 : negative_infinity(),
      positive_infinity(), primary_id, primary_params
    );
  }

  // Get CDF at lower truncation point L
  real log_cdf_L;
  if (is_inf(L)) {
    // No left truncation (L = -inf sentinel)
    log_cdf_L = negative_infinity();
  } else if (L >= 1 && L <= upper_interval && floor(L) == L) {
    // L is a positive integer within computed range, reuse cached value
    log_cdf_L = log_cdfs[to_int(L)];
  } else {
    // L is outside computed range or non-integer, compute directly
    log_cdf_L = primarycensored_lcdf(
      L | dist_id, params, pwindow,
      dist_has_positive_support(dist_id) ? 0.0 : negative_infinity(),
      positive_infinity(), primary_id, primary_params
    );
  }

  // Compute log normalizer: log(F(D) - F(L))
  real log_cdf_D;
  if (D > upper_interval) {
    if (is_inf(D)) {
      log_cdf_D = 0; // log(1) = 0 for infinite D
    } else {
      log_cdf_D = primarycensored_lcdf(
        D | dist_id, params, pwindow,
        dist_has_positive_support(dist_id) ? 0.0 : negative_infinity(),
        positive_infinity(), primary_id, primary_params
      );
    }
  } else {
    log_cdf_D = log_cdfs[upper_interval];
  }

  log_normalizer = primarycensored_log_normalizer(log_cdf_D, log_cdf_L, L);

  // Compute log PMFs: log((F(d) - F(d-1)) / (F(D) - F(L)))
  for (d in 1:upper_interval) {
    if (d <= L) {
      // Delay interval [d-1, d) is entirely at or below L
      log_pmfs[d] = negative_infinity();
    } else if (d - 1 < L) {
      // L falls within interval [d-1, d), so compute mass in [L, d)
      log_pmfs[d] = log_diff_exp(log_cdfs[d], log_cdf_L) - log_normalizer;
    } else if (d == 1 && dist_has_positive_support(dist_id)) {
      // First interval [0, 1) with L <= 0 and positive-support delay:
      // F(0) = 0, so PMF = F(1) / normalizer
      log_pmfs[d] = log_cdfs[d] - log_normalizer;
    } else if (d == 1) {
      // First interval [0, 1) with L <= 0 and real-support delay: F(0) is
      // non-zero in general, so compute it explicitly.
      real log_cdf_0 = primarycensored_lcdf(
        0.0 | dist_id, params, pwindow,
        negative_infinity(), positive_infinity(),
        primary_id, primary_params
      );
      log_pmfs[d] = log_diff_exp(log_cdfs[d], log_cdf_0) - log_normalizer;
    } else {
      // Standard case: PMF = (F(d) - F(d-1)) / normalizer
      log_pmfs[d] = log_diff_exp(log_cdfs[d], log_cdfs[d-1]) - log_normalizer;
    }
  }

  return log_pmfs;
}

/**
  * Compute the primary event censored PMF for integer delays up to max_delay
  * @ingroup primary_censored_vectorized
  *
  * @param max_delay Maximum delay to compute PMF for
  * @param L Minimum delay (lower truncation point)
  * @param D Maximum delay (upper truncation point), must be at least max_delay + 1
  * @param dist_id Distribution identifier
  * @param params Array of distribution parameters
  * @param pwindow Primary event window
  * @param primary_id Primary distribution identifier
  * @param primary_params Primary distribution parameters
  *
  * @return Vector of primary event censored PMFs for integer delays 1 to
  * max_delay
  *
  * This function differs from primarycensored_pmf in that it:
  * 1. Computes PMFs for all integer delays from \[0, 1\] to \[max_delay,
  *    max_delay + 1\] in one call.
  * 2. Assumes integer delays (swindow = 1)
  * 3. Is more computationally efficient for multiple delay calculations
  *
  * @code
  * // Example: Weibull delay distribution with uniform primary distribution
  * int max_delay = 10;
  * real L = 0.0;
  * real D = 15.0;
  * int dist_id = 3; // Weibull
  * array[2] real params = {2.0, 1.5}; // shape and scale
  * real pwindow = 7.0;
  * int primary_id = 1; // Uniform
  * array[0] real primary_params = {};
  * vector[max_delay] pmf =
  *   primarycensored_sone_lpmf_vectorized(
  *      max_delay, L, D, dist_id, params, pwindow, primary_id, primary_params
  *   );
  * @endcode
  */
vector primarycensored_sone_pmf_vectorized(
  data int max_delay, data real L, data real D, data int dist_id,
  array[] real params, data real pwindow,
  data int primary_id,
  array[] real primary_params
) {
  return exp(
    primarycensored_sone_lpmf_vectorized(
      max_delay, L, D, dist_id, params, pwindow, primary_id, primary_params
    )
  );
}

// ===== primarycensored_ode.stan =====
/**
  * Compute the log CDF of the delay distribution
  * @ingroup delay_log_cdfs
  *
  * @param delay Time delay
  * @param params Distribution parameters
  * @param dist_id Distribution identifier matching pcd_distributions in R:
  *   1: Lognormal, 2: Gamma, 3: Weibull, 4: Exponential,
  *   9: Beta, 12: Cauchy, 13: Chi-square,
  *   15: Gumbel, 16: Inverse Gamma, 17: Logistic,
  *   18: Normal, 19: Inverse Chi-square,
  *   20: Double Exponential, 21: Pareto,
  *   22: Scaled Inverse Chi-square, 23: Student's t,
  *   24: Uniform, 25: von Mises
  *
  * @return Log CDF of the delay distribution
  *
  * @code
  * // Example: Lognormal distribution
  * real delay = 5.0;
  * array[2] real params = {0.0, 1.0}; // mean and standard deviation on log scale
  * int dist_id = 1; // Lognormal
  * real log_cdf = dist_lcdf(delay, params, dist_id);
  * @endcode
  */
/**
  * Test whether a delay distribution has support only on the non-negative reals
  * @ingroup delay_log_cdfs
  *
  * Used internally to decide whether to short-circuit `dist_lcdf` at
  * `delay <= 0` and whether the ODE / nested CDF calls need to integrate over
  * negative arguments. Returns 1 for distributions with strictly non-negative
  * support, 0 otherwise. IDs match `pcd_distributions$stan_id` in R.
  *
  * @param dist_id Distribution identifier
  * @return 1 if the delay distribution has non-negative support, 0 otherwise.
  */
int dist_has_positive_support(data int dist_id) {
  if (dist_id == 1) return 1;   // Lognormal
  if (dist_id == 2) return 1;   // Gamma
  if (dist_id == 3) return 1;   // Weibull
  if (dist_id == 4) return 1;   // Exponential
  if (dist_id == 9) return 1;   // Beta (support on [0, 1])
  if (dist_id == 13) return 1;  // Chi-square
  if (dist_id == 16) return 1;  // Inverse Gamma
  if (dist_id == 19) return 1;  // Inverse Chi-square
  if (dist_id == 21) return 1;  // Pareto
  if (dist_id == 22) return 1;  // Scaled inverse Chi-square
  return 0;
}

real dist_lcdf(real delay, array[] real params, int dist_id) {
  if (dist_has_positive_support(dist_id) && delay <= 0) {
    return negative_infinity();
  }

  // IDs match pcd_distributions$stan_id in R
  if (dist_id == 1) return lognormal_lcdf(delay | params[1], params[2]);
  else if (dist_id == 2) return gamma_lcdf(delay | params[1], params[2]);
  else if (dist_id == 3) return weibull_lcdf(delay | params[1], params[2]);
  else if (dist_id == 4) return exponential_lcdf(delay | params[1]);
  else if (dist_id == 9) return beta_lcdf(delay | params[1], params[2]);
  else if (dist_id == 12) return cauchy_lcdf(delay | params[1], params[2]);
  else if (dist_id == 13) return chi_square_lcdf(delay | params[1]);
  else if (dist_id == 15) return gumbel_lcdf(delay | params[1], params[2]);
  else if (dist_id == 16) return inv_gamma_lcdf(delay | params[1], params[2]);
  else if (dist_id == 17) return logistic_lcdf(delay | params[1], params[2]);
  else if (dist_id == 18) return normal_lcdf(delay | params[1], params[2]);
  else if (dist_id == 19) return inv_chi_square_lcdf(delay | params[1]);
  else if (dist_id == 20) return double_exponential_lcdf(delay | params[1], params[2]);
  else if (dist_id == 21) return pareto_lcdf(delay | params[1], params[2]);
  else if (dist_id == 22) return scaled_inv_chi_square_lcdf(delay | params[1], params[2]);
  else if (dist_id == 23) return student_t_lcdf(delay | params[1], params[2], params[3]);
  else if (dist_id == 24) return uniform_lcdf(delay | params[1], params[2]);
  else if (dist_id == 25) return von_mises_lcdf(delay | params[1], params[2]);
  else reject("Invalid distribution identifier: ", dist_id);
}

/**
  * Compute the log PDF of the primary distribution
  * @ingroup primary_distribution_log_pdfs
  *
  * @param x Value
  * @param primary_id Primary distribution identifier
  * @param params Distribution parameters
  * @param xmin Minimum value
  * @param xmax Maximum value
  *
  * @return Log PDF of the primary distribution
  *
  * @code
  * // Example: Uniform distribution
  * real x = 0.5;
  * int primary_id = 1; // Uniform
  * array[0] real params = {}; // No additional parameters for uniform
  * real xmin = 0;
  * real xmax = 1;
  * real log_pdf = primary_lpdf(x, primary_id, params, xmin, xmax);
  * @endcode
  */
real primary_lpdf(real x, int primary_id, array[] real params, real xmin, real xmax) {
  // Implement switch for different primary distributions
  if (primary_id == 1) return uniform_lpdf(x | xmin, xmax);
  if (primary_id == 2) return expgrowth_lpdf(x | xmin, xmax, params[1]);
  // Add more primary distributions as needed
  reject("Invalid primary distribution identifier");
}

/**
  * ODE system for the primary censored distribution
  * @ingroup ode
  *
  * @param t Time
  * @param y State variables
  * @param theta Parameters
  * @param x_r Real data
  * @param x_i Integer data
  *
  * @return Derivatives of the state variables
  */
vector primarycensored_ode(real t, vector y, array[] real theta,
                            array[] real x_r, array[] int x_i) {
  real d = x_r[1];
  int dist_id = x_i[1];
  int primary_id = x_i[2];
  real pwindow = x_r[2];
  int dist_params_len = x_i[3];
  int primary_params_len = x_i[4];

  // Extract distribution parameters
  array[dist_params_len] real params;
  if (dist_params_len) {
    params = theta[1:dist_params_len];
  }
  array[primary_params_len] real primary_params;
  if (primary_params_len) {
    int primary_loc = num_elements(theta);
    primary_params = theta[primary_loc - primary_params_len + 1:primary_loc];
  }

  real log_cdf = dist_lcdf(t | params, dist_id);
  real log_primary_pdf = primary_lpdf(d - t | primary_id, primary_params, 0, pwindow);

  return rep_vector(exp(log_cdf + log_primary_pdf), 1);
}

// ===== primarycensored_analytical_cdf.stan =====
/**
  * Check if an analytical solution exists for the given distribution combination
  * @ingroup analytical_solution_helpers
  *
  * @param dist_id Distribution identifier for the delay distribution
  * @param primary_id Distribution identifier for the primary distribution
  *
  * @return 1 if an analytical solution exists, 0 otherwise
  */
int check_for_analytical(int dist_id, int primary_id) {
  if (dist_id == 2 && primary_id == 1) return 1; // Gamma delay with Uniform primary
  if (dist_id == 1 && primary_id == 1) return 1; // Lognormal delay with Uniform primary
  if (dist_id == 3 && primary_id == 1) return 1; // Weibull delay with Uniform primary
  return 0; // No analytical solution for other combinations
}

/**
  * Compute the primary event censored log CDF analytically for Gamma delay with Uniform primary
  * @ingroup primary_event_analytical_distributions
  *
  * @param d Delay time
  * @param q Lower bound of integration (max(d - pwindow, 0))
  * @param params Array of Gamma distribution parameters [shape, rate]
  * @param pwindow Primary event window
  *
  * @return Log of the primary event censored CDF for Gamma delay with Uniform
  * primary
  */
real primarycensored_gamma_uniform_lcdf(data real d, real q, array[] real params, data real pwindow) {
  real shape = params[1];
  real rate = params[2];
  real log_window = log(pwindow);
  // log E where E = k * theta = shape / rate is the mean of the delay
  real log_E = log(shape) - log(rate);

  // F_T(d; k) and the recursion to F_T(d; k+1):
  // P(k+1, y) = P(k, y) - y^k e^{-y} / Gamma(k+1), with y = rate * d
  real log_F_T_d_k = gamma_lcdf(d | shape, rate);
  real gamma_kp1_pdf_log_d
    = shape * log(rate * d) - rate * d - lgamma(shape + 1);
  real log_F_T_d_kp1 = log_diff_exp(log_F_T_d_k, gamma_kp1_pdf_log_d);

  // q-dependent terms. Final algebra is unified; only a guard to avoid
  // log_diff_exp(-inf, -inf) and log(0) when q == 0 (q is data, so autodiff
  // is unaffected by this branch).
  real log_q_F_T_q;    // log(q * F_T(q; k))
  real log_E_tF_T_q;   // log(E * F_T(q; k+1))
  if (q > 0) {
    real log_F_T_q_k = gamma_lcdf(q | shape, rate);
    real gamma_kp1_pdf_log_q
      = shape * log(rate * q) - rate * q - lgamma(shape + 1);
    real log_F_T_q_kp1 = log_diff_exp(log_F_T_q_k, gamma_kp1_pdf_log_q);
    log_q_F_T_q = log(q) + log_F_T_q_k;
    log_E_tF_T_q = log_E + log_F_T_q_kp1;
  } else {
    log_q_F_T_q = negative_infinity();
    log_E_tF_T_q = negative_infinity();
  }

  // Unified form: F_{S+}(d) = (A - B) / w_P with A, B sums of positives:
  //   A = d * F_T(d; k)   + E * F_T(q; k+1)
  //   B = q * F_T(q; k)   + E * F_T(d; k+1)
  // Ordering A >= B is guaranteed by F_{S+}(d) >= 0.
  real log_A = log_sum_exp(log(d) + log_F_T_d_k, log_E_tF_T_q);
  real log_B = log_sum_exp(log_q_F_T_q, log_E + log_F_T_d_kp1);

  return log_diff_exp(log_A, log_B) - log_window;
}

/**
  * Compute the primary event censored log CDF analytically for Lognormal delay with Uniform primary
  * @ingroup primary_event_analytical_distributions
  *
  * @param d Delay time
  * @param q Lower bound of integration (max(d - pwindow, 0))
  * @param params Array of Lognormal distribution parameters [mu, sigma]
  * @param pwindow Primary event window
  *
  * @return Log of the primary event censored CDF for Lognormal delay with
  * Uniform primary
  */
real primarycensored_lognormal_uniform_lcdf(data real d, real q, array[] real params, data real pwindow) {
  real mu = params[1];
  real sigma = params[2];
  real mu_sigma2 = mu + square(sigma);
  real log_window = log(pwindow);
  // log E where E = exp(mu + sigma^2/2) is the mean of the delay
  real log_E = mu + 0.5 * square(sigma);

  real log_F_T_d = lognormal_lcdf(d | mu, sigma);
  real log_tF_T_d = lognormal_lcdf(d | mu_sigma2, sigma);

  // q-dependent terms (guard only to avoid log(0); final algebra is unified).
  real log_q_F_T_q;    // log(q * F_T(q))
  real log_E_tF_T_q;   // log(E * tilde F_T(q))
  if (q > 0) {
    real log_F_T_q = lognormal_lcdf(q | mu, sigma);
    real log_tF_T_q = lognormal_lcdf(q | mu_sigma2, sigma);
    log_q_F_T_q = log(q) + log_F_T_q;
    log_E_tF_T_q = log_E + log_tF_T_q;
  } else {
    log_q_F_T_q = negative_infinity();
    log_E_tF_T_q = negative_infinity();
  }

  // Unified form: F_{S+}(d) = (A - B) / w_P with
  //   A = d * F_T(d) + E * tilde F_T(q)
  //   B = q * F_T(q) + E * tilde F_T(d)
  // Ordering A >= B is guaranteed by F_{S+}(d) >= 0.
  real log_A = log_sum_exp(log(d) + log_F_T_d, log_E_tF_T_q);
  real log_B = log_sum_exp(log_q_F_T_q, log_E + log_tF_T_d);

  return log_diff_exp(log_A, log_B) - log_window;
}

/**
  * Compute the log of the lower incomplete gamma function
  * @ingroup analytical_solution_helpers
  *
  * This function is used in the analytical solution for the primary censored
  * Weibull distribution with uniform primary censoring. It corresponds to the
  * g(t; λ, k) function described in the analytic solutions document.
  *
  * @param t Upper bound of integration
  * @param shape Shape parameter (k) of the Weibull distribution
  * @param scale Scale parameter (λ) of the Weibull distribution
  *
  * @return Log of g(t; λ, k) = γ(1 + 1/k, (t/λ)^k)
  */
real log_weibull_g(real t, real shape, real scale) {
  real x = pow(t * inv(scale), shape);
  real a = 1 + inv(shape);
  return log(gamma_p(a, x)) + lgamma(a);
}

/**
  * Compute the primary event censored log CDF analytically for Weibull delay with Uniform primary
  * @ingroup primary_event_analytical_distributions
  *
  * @param d Delay time
  * @param q Lower bound of integration (max(d - pwindow, 0))
  * @param params Array of Weibull distribution parameters [shape, scale]
  * @param pwindow Primary event window
  *
  * @return Log of the primary event censored CDF for Weibull delay with
  * Uniform primary
  */
real primarycensored_weibull_uniform_lcdf(data real d, real q, array[] real params, data real pwindow) {
  real shape = params[1];
  real scale = params[2];
  real log_window = log(pwindow);
  real log_scale = log(scale);

  // For Weibull: E = scale (lambda) and tilde F_T(t) = g(t; lambda, k), so
  // log(E * tilde F_T(t)) = log(scale) + log_weibull_g(t, shape, scale).
  real log_F_T_d = weibull_lcdf(d | shape, scale);
  real log_E_tF_T_d = log_scale + log_weibull_g(d, shape, scale);

  // q-dependent terms (guard only to avoid log(0); final algebra is unified).
  real log_q_F_T_q;    // log(q * F_T(q))
  real log_E_tF_T_q;   // log(E * tilde F_T(q)) = log(scale * g(q; lambda, k))
  if (q > 0) {
    log_q_F_T_q = log(q) + weibull_lcdf(q | shape, scale);
    log_E_tF_T_q = log_scale + log_weibull_g(q, shape, scale);
  } else {
    log_q_F_T_q = negative_infinity();
    log_E_tF_T_q = negative_infinity();
  }

  // Unified form: F_{S+}(d) = (A - B) / w_P with
  //   A = d * F_T(d)    + scale * g(q; lambda, k)
  //   B = q * F_T(q)    + scale * g(d; lambda, k)
  // Ordering A >= B is guaranteed by F_{S+}(d) >= 0.
  real log_A = log_sum_exp(log(d) + log_F_T_d, log_E_tF_T_q);
  real log_B = log_sum_exp(log_q_F_T_q, log_E_tF_T_d);

  return log_diff_exp(log_A, log_B) - log_window;
}

/**
  * Compute the primary event censored log CDF analytically for a single delay
  * (internal version without truncation)
  * @ingroup primary_event_analytical_distributions
  */
real primarycensored_analytical_lcdf_raw(data real d, int dist_id,
                                         array[] real params,
                                         data real pwindow,
                                         int primary_id) {
  real q = max({d - pwindow, 0});

  if (dist_id == 2 && primary_id == 1) {
    return primarycensored_gamma_uniform_lcdf(d | q, params, pwindow);
  } else if (dist_id == 1 && primary_id == 1) {
    return primarycensored_lognormal_uniform_lcdf(d | q, params, pwindow);
  } else if (dist_id == 3 && primary_id == 1) {
    return primarycensored_weibull_uniform_lcdf(d | q, params, pwindow);
  }
  return negative_infinity();
}

/**
  * Compute the primary event censored log CDF analytically for a single delay
  * @ingroup primary_event_analytical_distributions
  *
  * @param d Delay
  * @param dist_id Distribution identifier
  * @param params Array of distribution parameters
  * @param pwindow Primary event window
  * @param L Minimum delay (lower truncation point)
  * @param D Maximum delay (upper truncation point)
  * @param primary_id Primary distribution identifier
  * @param primary_params Primary distribution parameters
  *
  * @return Primary event censored log CDF, normalized over [L, D] if truncation
  * is applied
  */
real primarycensored_analytical_lcdf(data real d, int dist_id,
                                           array[] real params,
                                           data real pwindow, data real L,
                                           data real D, int primary_id,
                                           array[] real primary_params) {
  if (d <= L) return negative_infinity();
  if (d >= D) return 0;

  real result = primarycensored_analytical_lcdf_raw(
    d, dist_id, params, pwindow, primary_id
  );

  // Apply truncation normalization
  if (!is_inf(D) || L > 0) {
    vector[2] bounds = primarycensored_truncation_bounds(
      L, D, dist_id, params, pwindow, primary_id, primary_params
    );
    real log_cdf_L = bounds[1];
    real log_cdf_D = bounds[2];

    real log_normalizer = primarycensored_log_normalizer(log_cdf_D, log_cdf_L, L);
    result = primarycensored_apply_truncation(result, log_cdf_L, log_normalizer, L);
  }

  return result;
}

/**
  * Compute the primary event censored CDF analytically for a single delay
  * @ingroup primary_event_analytical_distributions
  *
  * @param d Delay
  * @param dist_id Distribution identifier
  * @param params Array of distribution parameters
  * @param pwindow Primary event window
  * @param L Minimum delay (lower truncation point)
  * @param D Maximum delay (upper truncation point)
  * @param primary_id Primary distribution identifier
  * @param primary_params Primary distribution parameters
  *
  * @return Primary event censored CDF, normalized over [L, D] if truncation
  * is applied
  */
real primarycensored_analytical_cdf(data real d, int dist_id,
                                          array[] real params,
                                          data real pwindow, data real L,
                                          data real D, int primary_id,
                                          array[] real primary_params) {
  return exp(primarycensored_analytical_lcdf(d | dist_id, params, pwindow, L, D, primary_id, primary_params));
}

// ===== expgrowth.stan =====
/**
  * Exponential growth probability density function (PDF)
  * @ingroup exponential_growth_distributions
  *
  * @param x Value at which to evaluate the PDF
  * @param xmin Lower bound of the distribution
  * @param xmax Upper bound of the distribution
  * @param r Rate parameter for exponential growth
  * @return The PDF evaluated at x
  */
real expgrowth_pdf(real x, real xmin, real xmax, real r) {
  if (x < xmin || x > xmax) {
    return 0;
  }
  if (abs(r) < 1e-10) {
    return 1 / (xmax - xmin);
  }
  return r * exp(r * x) / (exp(r * xmax) - exp(r * xmin));
}

/**
  * Exponential growth log probability density function (log PDF)
  * @ingroup exponential_growth_distributions
  *
  * @param x Value at which to evaluate the log PDF
  * @param xmin Lower bound of the distribution
  * @param xmax Upper bound of the distribution
  * @param r Rate parameter for exponential growth
  * @return The log PDF evaluated at x
  */
real expgrowth_lpdf(real x, real xmin, real xmax, real r) {
  if (x < xmin || x > xmax) {
    return negative_infinity();
  }
  if (abs(r) < 1e-10) {
    return -log(xmax - xmin);
  }
  return log(abs(r)) + r * x -
    log(abs(exp(r * xmax) - exp(r * xmin)));
}

/**
  * Exponential growth cumulative distribution function (CDF)
  * @ingroup exponential_growth_distributions
  *
  * @param x Value at which to evaluate the CDF
  * @param xmin Lower bound of the distribution
  * @param xmax Upper bound of the distribution
  * @param r Rate parameter for exponential growth
  * @return The CDF evaluated at x
  */
real expgrowth_cdf(real x, real xmin, real xmax, real r) {
  if (x < xmin) {
    return 0;
  }
  if (x > xmax) {
    return 1;
  }
  if (abs(r) < 1e-10) {
    return (x - xmin) / (xmax - xmin);
  }
  return (exp(r * x) - exp(r * xmin)) / (exp(r * xmax) - exp(r * xmin));
}

/**
  * Exponential growth log cumulative distribution function (log CDF)
  * @ingroup exponential_growth_distributions
  *
  * @param x Value at which to evaluate the log CDF
  * @param xmin Lower bound of the distribution
  * @param xmax Upper bound of the distribution
  * @param r Rate parameter for exponential growth
  * @return The log CDF evaluated at x
  */
real expgrowth_lcdf(real x, real xmin, real xmax, real r) {
  if (x < xmin) {
    return negative_infinity();
  }
  if (x > xmax) {
    return 0;
  }
  return log(expgrowth_cdf(x | xmin, xmax, r));
}

/**
  * Exponential growth random number generator
  * @ingroup exponential_growth_distributions
  *
  * @param xmin Lower bound of the distribution
  * @param xmax Upper bound of the distribution
  * @param r Rate parameter for exponential growth
  * @return A random draw from the exponential growth distribution
  */
real expgrowth_rng(real xmin, real xmax, real r) {
  real u = uniform_rng(0, 1);
  if (abs(r) < 1e-10) {
    return xmin + u * (xmax - xmin);
  }
  return log(u * exp(r * xmax) + (1 - u) * exp(r * xmin)) / r;
}

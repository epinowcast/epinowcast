/**
 * Compute the log cumulative distribution function (LCDF) for a log-logistic
 * distribution
 * 
 * Calculates the LCDF of a log-logistic distribution for a given value using 
 * specified scale and shape parameters.
 * 
 * @param y The value at which to compute the LCDF.
 * 
 * @param alpha Scale parameter of the log-logistic distribution (alpha > 0).
 *
 * @param beta Shape parameter of the log-logistic distribution (beta > 0).
 * 
 * @return The log-logistic LCDF of y.
 */
real loglogistic_lcdf (real y, real alpha, real beta) {
  return -log1p((y / alpha) ^-beta);
}

/**
 * Compute the discretised LCDF for various distributions
 * 
 * Computes the LCDF at integer points from 1 to u for a selected parametric
 * distribution. Supports exponential, lognormal, gamma, and log-logistic
 * distributions.
 * 
 * @param mu Location parameter for the distribution.
 *
 * @param sigma Scale parameter for the distribution.
 *
 * @param u Upper bound of the discretized LCDF.
 *
 * @param dist Integer flag for distribution type (1: exponential, 2: lognormal,
 * 3: gamma, 4: log-logistic).
 * 
 * @return Vector of LCDF values for the specified distribution.
 * 
 * @note Uses `loglogistic_lcdf` for the log-logistic distribution.
 */
vector lcdf_discretised(real mu, real sigma, int u, int dist) {
  vector[u] integer_lcdf;
  if (dist == 1) {
    real emu = exp(-mu);
    for (i in 1:u) {
      integer_lcdf[i] = exponential_lcdf(i | emu);
    }
  } else if (dist == 2) {
    for (i in 1:u) {
      integer_lcdf[i] = lognormal_lcdf(i | mu, sigma);
    }
  } else if (dist == 3) {
    real emu = exp(mu);
    for (i in 1:u) {
      integer_lcdf[i] = gamma_lcdf(i | emu, sigma);
    }
  } else if (dist == 4) {
    real emu = exp(mu);
    for (i in 1:u) {
      integer_lcdf[i] = loglogistic_lcdf(i | emu, sigma);
    }
  } else {
    reject("Unknown distribution function provided.");
  }
  return(integer_lcdf);
}

/**
 * Normalise a discretised LCDF under double censoring
 * 
 * Adjusts LCDF values for the probability mass beyond the upper bound of the 
 * discretised LCDF, assuming double censoring and a uniform interval 
 * approximation. Different strategies are applied depending on `max_strat`.
 * 
 * @param lcdf Vector of LCDF values to be adjusted.
 *
 * @param u Upper bound of the discretized LCDF.
 *
 * @param max_strat Strategy for handling probability mass beyond upper bound.
 * 
 * @return Vector of adjusted LCDF values.
 * 
 * @note Used on the output of `lcdf_discretised`.
 */
vector normalise_lcdf_as_uniform_double_censored(vector lcdf, int u,
  int max_strat) {
  vector[u] adjusted_lcdf;
  if (max_strat == 0) {
    // ignore (i.e. sum of probabilities does not add to 1)
    // NOTE: This cannot be used when using lcdf_to_logit_hazard as
    // it will return the same result as using strategy 2.
    adjusted_lcdf = lcdf;
  } else if (max_strat == 1) {
    // add to upper bound: cdf_u = 1 (i.e. lcdf_u = 0)
    adjusted_lcdf = lcdf;
    adjusted_lcdf[u] = 0;
    // normalise to account for double censoring
    adjusted_lcdf = adjusted_lcdf - log(2);
  } else if (max_strat == 2) {
    // normalize: cdf = cdf / (cdf[u] + cdf[u-1])
    // both u and u-1 are in the denominator to account for the 2 day width of
    // the (overlapping) intervals from the uniform interval approximation:
    // For a delay d, the interval is [d-1, d+1], e.g. the interval for delay 0 
    // goes from -1 to 1, and the interval for delay 1 goes from 0 to 2 in the 
    // LCDF, respectively. For a maximum delay of D days, we therefore evaluate 
    // the LCDF up to the integer u = D+1. The total mass of this LCDF is thus:
    // sum_{d=0}^D (F_{d+1} - F_{d-1}) = sum_{i=1}^u (F_{i} - F_{i-2}) = F_{u} + F_{u-1}
    // If u were infinite this would be equivalent to dividing by 2.
    if (u == 1) {
      adjusted_lcdf = lcdf - lcdf[1];
    }
    if (u > 1) {
      adjusted_lcdf = lcdf - log_sum_exp(lcdf[u], lcdf[u-1]);
    }
  } else {
    reject("Unknown strategy to handle probability mass beyond the maximum value.");
  }
  return(adjusted_lcdf);
}

/**
 * Compute LPMF from discretised LCDF under double censoring
 * 
 * Converts LCDF values to log-scale probability mass function (LPMF) assuming 
 * double censoring and a uniform interval approximation. Suitable for 
 * discretised LCDFs evaluated at integers 1 to u.
 * 
 * @param lcdf Vector of LCDF values.
 *
 * @param u Upper bound of the discretized LCDF / LPMF.
 * 
 * @return Vector of log-scale PMF values.
 * 
 * @note While the elements of the LCDF vector correspond to delays 1 to u, the
 * elements of the PMF correspond to delays 0:(u-1). Hence, log(p_0) = lpmf[1].
 *
 * @note Processes output of `normalise_lcdf_as_uniform_double_censored`.
 */
vector lcdf_to_uniform_double_censored_log_prob(vector lcdf, int u) {
  vector[u] lpmf; 
  // p_0 = cdf_1 - cdf_0
  lpmf[1] = lcdf[1];
  if (u > 1) {
    // p_1 = cdf_2 - cdf_0
    lpmf[2] = lcdf[2];
    if (u > 2) {
      // p_u = cdf_u+1 - cdf_u-1
      lpmf[3:u] = log_diff_exp(lcdf[3:u], lcdf[1:(u-2)]);
    }
  }
  return(lpmf);
}

/**
 * Compute logit hazards from log probabilities.
 * 
 * Derives logit hazards from log probabilities of a delay LPMF, assuming 
 * double censoring and a uniform interval approximation for discretised delays.
 * 
 * @param lprob Vector of log probabilities from the LPMF.
 *
 * @param lcdf Vector of corresponding LCDF values for the LMPF. This could also
 * be computed from lprob, but by re-using the precomputed LCDF from elsewhere 
 * we reduce overall computation.
 *
 * @param u Upper bound of discretized LCDF.
 * 
 * @return Vector of logit hazards.
 *
* @note While the elements of the LCDF vector correspond to delays 1 to u, the
 * elements of the PMF correspond to delays 0:(u-1). Hence, log(h_0) = lhaz[1].
 * 
 * @note Processes output of `lcdf_to_uniform_double_censored_log_prob`
 * and `normalise_lcdf_as_uniform_double_censored
 *
 * @brief Compute discretised logit hazard
 *
 * @f[
 * \begin{align*}
 *   \text{Let } & h_n = \text{ hazard at time } n, \\
 *               & p_n = \text{ probability at time } n, \\
 *               & cdf_n = \text{ cumulative distribution function at time } n, \\
 *               & ccdf_n = \text{ complementary cumulative distribution function at time } n = 1 - cdf_n. \\
 *   \\
 *   % Hazard definition
 *   h_n &= \frac{p_n}{1 - \sum_{d=0}^{n-1} p_d} \\
 *       &= \frac{cdf_{n+1} - cdf_{n-1}}{1 - \sum_{d=0}^{n-1} (cdf_{d+1} - cdf_{d-1})} \\
 *       &= \frac{cdf_{n+1} - cdf_{n-1}}{1 - (cdf_n + cdf_{n-1})} \\
 *       &= \frac{cdf_{n+1} - cdf_{n-1}}{ccdf_n - cdf_{n-1}}. \\
 *   \\
 *   % Log transformation
 *   \log(h_n) &= \log(cdf_{n+1} - cdf_{n-1}) - \log(ccdf_n - cdf_{n-1}).
 * \end{align*}
 * @f]
 */
vector lprob_to_uniform_double_censored_log_hazard(vector lprob, vector lcdf,
   int u) {
  vector[u] lhaz;
  // h_0 = F_1
  lhaz[1] = lcdf[1];
  // h_n = p_n / (1 - sum^{n-1}_{d=0} p_d)
  // h_n = (cdf_n+1 - cdf_n-1) / (1 - sum^{n-1}_{d=0} cdf_d+1 - cdf_d-1)
  // h_n = (cdf_n+1 - cdf_n-1) / (1 - (cdf_n + cdf_n-1))
  // h_n = (cdf_n+1 - cdf_n-1) / (1 - cdf_n - cdf_n-1)
  // h_n = (cdf_n+1 - cdf_n-1) / (ccdf_n - cdf_n-1)
  // log(h_n) = log(cdf_n+1 - cdf_n-1) - log(ccdf_n - cdf_n-1)
  if (n > 1) {
    vector[n-2] lccdf;
    // cccdf_n = 1 - cdf_n
    lccdf = log1m_exp(lcdf[1:(n-2)]);
    lhaz[2] = lprob[2] - lccdf[1];
    if (u > 2) {
      lhaz[3:(u-1)] = lprob[3:(u-1)] - log_diff_exp(lccdf[2:(u-2)], lcdf[1:(u-3)]);
    }
  }
  return(lhaz);
}

/**
 * Convert log hazards to logit hazards efficiently
 * 
 * Transforms log hazards to logit hazards without converting to the natural
 * scale. Used in the final step of converting discretised probability
 * distributions to logit hazards.
 * 
 * @param lhaz Vector of log hazards.
 *
 * @param n Number of hazards.
 * 
 * @return Vector of logit hazards.
 * 
 * @note Final transformation step in `discretised_logit_hazard`.
 */
vector log_hazard_to_logit_hazard(vector lhaz, int n) {
  vector[n] logit_haz;
  // Logit transformation
  logit_haz[1:(n-1)] = lhaz[1:(n-1)] - log1m_exp(lhaz[1:(n-1)]);
  // Set last logit transformed hazard to Inf (i.e h[n] = 1)
  logit_haz[n] = positive_infinity();
  return(logit_haz);
}

/**
 * Calculate logit hazard or log probability for discretised delay distribution
 * 
 * Computes logit hazards or log probabilities for a specified discretised
 * parametric distribution up to a maximum possible delay. Employs various 
 * normalisation strategies and assumes that delays are double-censored and 
 * that the interval width is approximately uniformly distributed.
 * 
 * @param mu Location parameter of the parametric distribution.
 *
 * @param sigma Scale parameter of the parametric distribution.
 *
 * @param dmax Maximum possible delay. The parametric distribution will be 
 * truncated at dmax.
 *
 * @param dist Distribution type indicator (e.g., exponential, lognormal, ...).
 *
 * @param max_strat Strategy for normalising LCDF values (e.g., handling 
 * probability mass beyond the maximum observed value).
 *
 * @param ref_as_p Flag indicating whether to return log probabilities directly 
 * (1) or to convert to logit hazards (0).
 * 
 * @return A vector of logit hazards or log probabilities of the discretised 
 * distribution, representing discrete delays from 0 to (dmax-1).
 * 
 * @note This function integrates several steps:
 *       1. Generates LCDF values using `lcdf_discretised`.
 *       2. Normalises these LCDF values with
 *          `normalise_lcdf_as_uniform_double_censored`.
 *       3. Converts LCDF to log probabilities using
 *          `lcdf_to_uniform_double_censored_log_prob`.
 *       4. If `ref_as_p` is 0, further processes these probabilities into 
 *          logit hazards using `lprob_to_uniform_double_censored_log_hazard`
 *          and `log_hazard_to_logit_hazard`.
 * 
 * Dependencies:
 *   - `lcdf_discretised`
 *   - `normalise_lcdf_as_uniform_double_censored`
 *   - `lcdf_to_uniform_double_censored_log_prob`
 *   - `lprob_to_uniform_double_censored_log_hazard`
 *   - `log_hazard_to_logit_hazard`
 */
vector discretised_logit_hazard(real mu, real sigma, int n, int dist, 
                                int max_strat, int ref_as_p) {
  vector[n] lcdf;
  vector[n] lprob;
  vector[n] logit_haz; 
  lcdf = lcdf_discretised(mu, sigma, n, dist);
  lcdf = normalise_lcdf_as_uniform_double_censored(lcdf, n, max_strat);
  lprob = lcdf_to_uniform_double_censored_log_prob(lcdf, n);
  if (ref_as_p == 1) {
    // In the mode where there are no hazard effects downstream functions
    // make use of the log probability directly so we return it here without
    // converting to the logit hazard.
    logit_haz = lprob;
  }else{
    vector[n] lhaz;
    lhaz = lprob_to_uniform_double_censored_log_hazard(lprob, lcdf, n);
    logit_haz = log_hazard_to_logit_hazard(lhaz, n);
  }
  return(logit_haz);
}

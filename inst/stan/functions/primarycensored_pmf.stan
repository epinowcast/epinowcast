/**
 * Primary event censored discretisation wrapper for epinowcast
 *
 * Wraps the vendored primarycensored Stan functions (see
 * primarycensored.stan) so that they can be used as a drop-in alternative to
 * discretised_logit_hazard() when discretising a parametric reference date
 * delay distribution. The primarycensored approach accounts for double
 * interval censoring (a uniform primary event window convolved with a
 * secondary reporting interval) rather than the uniform-interval approximation
 * used by discretised_logit_hazard().
 *
 * @ingroup pmf_handlers
 */

/**
 * Translate an epinowcast distribution id to a primarycensored dist_id
 *
 * epinowcast uses model_refp ids (1: exponential, 2: lognormal, 3: gamma)
 * which differ from primarycensored's pcd_stan_dist_id() convention
 * (1: lognormal, 2: gamma, 3: weibull, 4: exponential). This function maps the
 * supported epinowcast ids onto the primarycensored ids.
 *
 * @param dist epinowcast model_refp distribution id.
 *
 * @return The corresponding primarycensored dist_id.
 *
 * @note The exponential (epinowcast id 1) is routed through the
 * primarycensored gamma id (2) as a Gamma(shape = 1) special case. This uses
 * the analytical gamma-uniform solution rather than falling back to the
 * per-delay ODE integration that primarycensored's standalone exponential id
 * (4) would require, which is substantially faster inside the sampler.
 *
 * @note The log-logistic distribution was dropped from epinowcast pending
 * support in primarycensored
 * (see https://github.com/epinowcast/primarycensored/issues/321); any other
 * id is rejected.
 */
int enw_to_pcens_dist_id(int dist) {
  if (dist == 1) return 2;  // exponential -> primarycensored gamma (shape 1)
  if (dist == 2) return 1;  // lognormal   -> primarycensored lognormal
  if (dist == 3) return 2;  // gamma       -> primarycensored gamma
  reject(
    "The primarycensored discretisation does not support distribution id ",
    dist, ". Supported distributions are exponential, lognormal and gamma."
  );
}

/**
 * Translate epinowcast (mu, sigma) parameters to primarycensored parameters
 *
 * epinowcast parameterises its parametric reference delay distributions on a
 * transformed scale (e.g. log rate for the exponential, log shape for the
 * gamma) that matches lcdf_discretised() in discretised_logit_hazard.stan.
 * The vendored primarycensored functions expect the native Stan
 * parameterisation. This function performs the translation so that the two
 * discretisation paths share the same user facing parameters.
 *
 * @param mu Location parameter on the epinowcast transformed scale.
 *
 * @param sigma Scale parameter on the epinowcast transformed scale.
 *
 * @param dist epinowcast model_refp distribution id.
 *
 * @return A length two array of native primarycensored distribution
 * parameters.
 */
array[] real enw_to_pcens_params(real mu, real sigma, int dist) {
  array[2] real params;
  if (dist == 1) {
    // Exponential: epinowcast uses exp(-mu) as the rate. Routed through the
    // gamma path as Gamma(shape = 1, rate = exp(-mu)), which is identical to
    // Exponential(rate = exp(-mu)) but hits the analytical gamma-uniform
    // solution.
    params[1] = 1;
    params[2] = exp(-mu);
  } else if (dist == 2) {
    // Lognormal: shared (meanlog, sdlog) parameterisation.
    params[1] = mu;
    params[2] = sigma;
  } else if (dist == 3) {
    // Gamma: epinowcast uses exp(mu) as the shape with sigma as the rate;
    // primarycensored gamma takes (shape, rate).
    params[1] = exp(mu);
    params[2] = sigma;
  } else {
    reject("Unsupported distribution id for primarycensored params: ", dist);
  }
  return params;
}

/**
 * Convert a proper discretised log PMF to logit hazards
 *
 * Computes logit hazards from a non-overlapping discretised log PMF (such as
 * the one returned by the primarycensored functions) using the standard
 * discrete survival hazard h_d = p_d / S_{d-1}, where S_{d-1} is the survival
 * function S_{d-1} = 1 - sum_{i < d} p_i. This differs from
 * lprob_to_uniform_double_censored_log_hazard(), which assumes the overlapping
 * uniform-interval PMF produced by discretised_logit_hazard().
 *
 * @param lprob Vector of log probabilities, one per discrete delay 0:(u - 1).
 *
 * @param u Number of discrete delays (length of lprob).
 *
 * @return Vector of logit hazards matching the output contract of
 * log_hazard_to_logit_hazard().
 *
 * @note The final hazard is fixed to 1 (logit hazard +inf) so that all
 * remaining probability mass is reported by the maximum delay, matching
 * discretised_logit_hazard().
 */
vector lprob_to_log_hazard(vector lprob, int u) {
  vector[u] lhaz;
  // h_0 = p_0 (survival before delay 0 is 1).
  lhaz[1] = lprob[1];
  // Running log survival: log S_d = log(1 - sum_{i <= d} p_i).
  real log_surv = log1m_exp(lprob[1]);
  for (d in 2:u) {
    // h_{d-1} = p_{d-1} / S_{d-2}; here lprob[d] is p_{d-1} and log_surv is
    // log S_{d-2} (survival up to but excluding the current delay).
    lhaz[d] = lprob[d] - log_surv;
    // Update survival to exclude the current delay before the next iteration.
    if (d < u) {
      log_surv = log_diff_exp(log_surv, lprob[d]);
    }
  }
  // Pin the terminal hazard to exactly 1 (log(1) = 0) so that
  // log_hazard_to_logit_hazard() yields +inf and all remaining mass is
  // reported at the maximum delay, rather than relying on floating-point
  // cancellation in the final iteration above.
  lhaz[u] = 0;
  return log_hazard_to_logit_hazard(lhaz);
}

/**
 * Discretise a parametric delay distribution using primary event censoring
 *
 * Computes the log probability mass function of a double interval censored
 * delay distribution using the vendored primarycensored Stan functions and,
 * optionally, converts it to logit hazards so that the result is a drop in
 * replacement for discretised_logit_hazard().
 *
 * @param mu Location parameter of the parametric distribution (epinowcast
 * transformed scale).
 *
 * @param sigma Scale parameter of the parametric distribution (epinowcast
 * transformed scale).
 *
 * @param dmax Maximum possible delay. The distribution is discretised over
 * delays 0 to (dmax - 1) and normalised over that range.
 *
 * @param dist epinowcast model_refp distribution id (1: exponential,
 * 2: lognormal, 3: gamma).
 *
 * @param ref_as_p Flag indicating whether to return log probabilities directly
 * (1) or to convert to logit hazards (0).
 *
 * @return A vector of logit hazards or log probabilities of the discretised
 * distribution, representing discrete delays from 0 to (dmax - 1). The output
 * contract matches discretised_logit_hazard().
 *
 * @note Uses a uniform primary event window of width 1 and assumes an integer
 * secondary censoring window of width 1, matching epinowcast's daily
 * discretisation. Right truncation is applied at dmax via the primarycensored
 * D argument.
 */
vector discretised_pcens_logit_hazard(real mu, real sigma, int dmax, int dist,
                                      int ref_as_p) {
  int pcens_dist = enw_to_pcens_dist_id(dist);
  // All supported distributions (exponential routed via gamma, lognormal,
  // gamma) take two parameters under the primarycensored convention.
  array[2] real params = enw_to_pcens_params(mu, sigma, dist);
  array[0] real primary_params;
  vector[dmax] lprob = primarycensored_sone_lpmf_vectorized(
    dmax - 1, 0.0, dmax * 1.0, pcens_dist, params, 1.0, 1, primary_params
  );
  if (ref_as_p == 1) {
    return lprob;
  }
  return lprob_to_log_hazard(lprob, dmax);
}

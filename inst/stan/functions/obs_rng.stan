/**
 * Generate random draws from the observation model
 * 
 * Produces random draws from the specified observation model.
 * 
 * @param log_exp_obs Vector logarithm of expected observations.
 * @param phi Dispersion parameter for the negative binomial model, ignored for 
 * the Poisson model. Should be an array with the first element used.
 *
 * @param model_obs Indicator of the model used (0 for Poisson, 1 for negative
 * binomial with a quadratic mean-variance relationship, 2 for negative
 * binomial with a linear mean-variance relationship).
 *
 * @return An array of integer random draws corresponding to the observation
 * counts under the specified model.
 * 
 * @note Depending on the `model_obs` flag, this function uses either 
 * `neg_binomial_2_log_rng` for the negative binomial model or 
 * `poisson_log_rng` for the Poisson model to generate the random draws.
 */
array[] int obs_rng(vector log_exp_obs, array[] real phi, int model_obs) {
  int n = num_elements(log_exp_obs);
  array[n] int pp;
  // Stan's count RNGs draw a Poisson rate (or negative binomial gamma rate)
  // that must stay below 2^30; an expected count above this overflows and
  // throws, discarding the whole draw. Approximate inference methods such as
  // the Laplace approximation can sample extreme tail values for the linear
  // predictor, so we cap the log expected count at a value safely below the
  // RNG limit. This is a no-op for realistic expected counts.
  real max_log_exp = 18.0;

  // Handle -Inf values (structural zeros from reporting aggregation)
  // For days with zero reporting probability, set prediction to 0
  for (i in 1:n) {
    if (is_inf(log_exp_obs[i])) {
      pp[i] = 0;
    } else {
      real capped_log_exp = fmin(log_exp_obs[i], max_log_exp);
      if (model_obs == 0) {
        pp[i] = poisson_log_rng(capped_log_exp);
      } else if (model_obs == 1) {
        pp[i] = neg_binomial_2_log_rng(capped_log_exp, phi[1]);
      } else {
        // NB1 parameterisation: variance = mu + phi * mu, so phi_nb2 = mu * phi
        pp[i] = neg_binomial_2_log_rng(
          capped_log_exp, exp(capped_log_exp + log(phi[1]))
        );
      }
    }
  }
  return(pp);
}

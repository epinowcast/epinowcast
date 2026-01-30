/**
 * Unnormalized observation likelihood for model block
 *
 * Computes the unnormalized log probability mass function for observations.
 * Uses `_lupmf` variants which drop constants that don't depend on parameters,
 * providing better performance when used in the model block.
 *
 * @param obs Observations, can be a single integer (non-vectorized) or an
 * array of integers (vectorized).
 *
 * @param log_exp_obs Logarithm of expected observations, can be a single real
 * (non-vectorized) or a vector (vectorized).
 *
 * @param phi Dispersion parameter for the negative binomial model, ignored for
 * the Poisson model. Should be an array with the first element used.
 *
 * @param model_obs Indicator of the model used (0 for Poisson, 1 for negative
 * binomial with a quadratic mean-variance relationship, 2 for negative
 * binomial with a linear mean-variance relationship).
 *
 * @return The unnormalized log probability mass of the observations.
 *
 * @note Use this function in the model block for efficiency. For log_lik
 * calculations (e.g., for loo), use `obs_lpmf` instead.
 */
real obs_lupmf(array[] int obs, vector log_exp_obs, array[] real phi,
               int model_obs) {
  if (model_obs == 0) {
    return poisson_log_lupmf(obs | log_exp_obs);
  } else if (model_obs == 1) {
    return neg_binomial_2_log_lupmf(obs | log_exp_obs, phi[1]);
  } else {
    return neg_binomial_2_log_lupmf(
      obs | log_exp_obs, exp(log_exp_obs + log(phi[1]))
    );
  }
}

real obs_lupmf(int obs, real log_exp_obs, array[] real phi, int model_obs) {
  if (model_obs == 0) {
    return poisson_log_lupmf(obs | log_exp_obs);
  } else if (model_obs == 1) {
    return neg_binomial_2_log_lupmf(obs | log_exp_obs, phi[1]);
  } else {
    return neg_binomial_2_log_lupmf(
      obs | log_exp_obs, exp(log_exp_obs + log(phi[1]))
    );
  }
}

/**
 * Normalized observation likelihood for log_lik calculations
 *
 * Computes the normalized log probability mass function for observations.
 * Use this for log_lik calculations in generated quantities (e.g., for loo).
 *
 * @param obs Observations, can be a single integer (non-vectorized) or an
 * array of integers (vectorized).
 *
 * @param log_exp_obs Logarithm of expected observations, can be a single real
 * (non-vectorized) or a vector (vectorized).
 *
 * @param phi Dispersion parameter for the negative binomial model, ignored for
 * the Poisson model. Should be an array with the first element used.
 *
 * @param model_obs Indicator of the model used (0 for Poisson, 1 for negative
 * binomial with a quadratic mean-variance relationship, 2 for negative
 * binomial with a linear mean-variance relationship).
 *
 * @return The normalized log probability mass of the observations.
 */
real obs_lpmf(array[] int obs, vector log_exp_obs, array[] real phi,
              int model_obs) {
  if (model_obs == 0) {
    return poisson_log_lpmf(obs | log_exp_obs);
  } else if (model_obs == 1) {
    return neg_binomial_2_log_lpmf(obs | log_exp_obs, phi[1]);
  } else {
    return neg_binomial_2_log_lpmf(
      obs | log_exp_obs, exp(log_exp_obs + log(phi[1]))
    );
  }
}

real obs_lpmf(int obs, real log_exp_obs, array[] real phi, int model_obs) {
  if (model_obs == 0) {
    return poisson_log_lpmf(obs | log_exp_obs);
  } else if (model_obs == 1) {
    return neg_binomial_2_log_lpmf(obs | log_exp_obs, phi[1]);
  } else {
    return neg_binomial_2_log_lpmf(
      obs | log_exp_obs, exp(log_exp_obs + log(phi[1]))
    );
  }
}

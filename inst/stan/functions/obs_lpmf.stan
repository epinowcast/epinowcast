/**
 * Observation likelihood
 * 
 * Computes the log probability mass function (LPMF) for observations. This 
 * function is overloaded to handle both vectorized and non-vectorized inputs. 
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
 * @return The log probability mass of the observations under the specified
 * model.
 * 
 * @note The function selects between the negative binomial model and the
 * Poisson model based on the `model_obs` flag. It uses
 * `neg_binomial_2_log_lpmf` for the negative binomial model and
 * `poisson_log_lpmf` for the Poisson model.
 */
real obs_lpmf(array[] int obs, vector log_exp_obs, array[] real phi,
                   int model_obs) {
  real tar = 0;
  if (model_obs == 0) {
    tar = poisson_log_lpmf(obs | log_exp_obs);
  }else if (model_obs == 1) {
    tar = neg_binomial_2_log_lpmf(obs | log_exp_obs, phi[1]);
  }else{
    tar = neg_binomial_2_log_lpmf(obs | log_exp_obs, exp(log_exp_obs + log(phi[1])));
  }
  return(tar);
}

real obs_lpmf(int obs, real log_exp_obs, array[] real phi,
         int model_obs) {
  real tar = 0;
  if (model_obs == 0) {
    tar = poisson_log_lpmf(obs | log_exp_obs);
  }else if (model_obs == 1) {
    tar = neg_binomial_2_log_lpmf(obs | log_exp_obs, phi[1]);
  }else{
    tar = neg_binomial_2_log_lpmf(obs | log_exp_obs, exp(log_exp_obs + log(phi[1])));
  }
  return(tar);
}

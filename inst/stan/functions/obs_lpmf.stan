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
 * binomial).
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
  if (model_obs) {
    tar = neg_binomial_2_log_lpmf(obs | log_exp_obs, phi[1]);
  }else{
    tar = poisson_log_lpmf(obs | log_exp_obs);
  }
  return(tar);
}

real obs_lpmf(int obs, real log_exp_obs, array[] real phi,
         int model_obs) {
  real tar = 0;
  if (model_obs) {
    tar = neg_binomial_2_log_lpmf(obs | log_exp_obs, phi[1]);
  }else{
    tar = poisson_log_lpmf(obs | log_exp_obs);
  }
  return(tar);
}

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
 * binomial).
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
  if (model_obs) {
    pp = neg_binomial_2_log_rng(log_exp_obs, phi[1]);
  }else{
    pp = poisson_log_rng(log_exp_obs);
  }
  return(pp);
}

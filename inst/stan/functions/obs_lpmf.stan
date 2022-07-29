// vectorised observation likelihood
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

// non-vectorised observation likelihood
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

// random draws from the observation model
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

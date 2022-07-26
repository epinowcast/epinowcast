// Compute the cdf of a parametric distribution at values 1:n
vector upper_lcdf_discrete(real mu, real sigma, int n, int dist) {
  vector[n] upper_cdf;
  if (dist == 1) {
    real emu = exp(-mu);
    for (i in 1:n) {
      upper_cdf[i] = exponential_cdf(i | emu);
    }
  } else if (dist == 2) {
    for (i in 1:n) {
      upper_cdf[i] = lognormal_cdf(i | mu, sigma);
    }
  } else if (dist == 3) {
    real emu = exp(mu);
    for (i in 1:n) {
      upper_cdf[i] = gamma_cdf(i | emu, sigma);
    }
  } else if (dist == 4) {
    real emu = exp(mu);
    for (i in 1:n) {
      upper_cdf[i] = loglogistic_cdf(i | emu, sigma);
    }
  } else {
    reject("Unknown distribution function provided.");
  }
  return(upper_cdf);
}

// Adjust a vector of cdf evaluations for probability mass beyond maximum value
vector adjust_lcdf_discrete(vector lcdf, int n, int max_strat) {
  vector[n] adjusted_cdf;
  if (max_strat == 0) {
    // ignore
    adjusted_cdf = cdf;
  } else if (max_strat == 1) {
    // add to maximum value
    adjusted_cdf = cdf;
    adjusted_cdf[n] = 1;
  } else if (max_strat == 2) {
    // normalize
    adjusted_cdf = cdf / cdf[n];
  } else {
    reject("Unknown strategy to handle probability mass beyond the maximum value.");
  }
  return(adjusted_cdf);
}

// Calculate the daily probability of reporting using parametric
// distributions up to the maximum observed delay
vector discretised_reporting_log_prob(real mu, real sigma, int n, int dist, int max_strat) {
  vector[n] lpmf; 
  vector[n] lcdf;
  lcdf = upper_lcdf_discrete(mu, sigma, n, dist);
  lcdf = adjust_lcdf_discrete(cdf, n, max_strat);
  // compute discretised pmf
  lpmf[1] = lcdf[1];
  lpmf[2:n] = log_diff_exp(lcdf[2:n], lcdf[1:(n-1)]);
  return(lpmf);
}

// Calculate the daily hazard of reporting using parametric
// distributions up to the maximum observed delay
vector discretised_reporting_logit_hazard(real mu, real sigma, int n, int dist,
                                          int max_strat) {
  vector[n] lhaz; 
  vector[n] lcdf;
  vector[n] lccdf;
  cdf = upper_lcdf_discrete(mu, sigma, n, dist);
  cdf = adjust_lcdf_discrete(cdf, n, max_strat);
  ccdf = log1m_exp(lcdf);
  // compute discretised hazard
  lhaz[1] = lcdf[1];
  lhaz[2:(n-1)] = log1m_exp(lccdf[2:(n-1)] - lccdf[1:(n-2)]);
  lhaz[n] = 0;
  lhaz = lhaz - log1m_exp(lhaz);
  return(lhaz);
}

vector discer

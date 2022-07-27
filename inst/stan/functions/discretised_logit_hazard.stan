real loglogistic_lcdf (real y, real alpha, real beta) {
  return -log1p((y / alpha) ^-beta);
}

// Compute the cdf of a parametric distribution at values 1:n
vector upper_lcdf_discrete(real mu, real sigma, int n, int dist) {
  vector[n] upper_lcdf;
  if (dist == 1) {
    real emu = exp(-mu);
    for (i in 1:n) {
      upper_lcdf[i] = exponential_lcdf(i | emu);
    }
  } else if (dist == 2) {
    for (i in 1:n) {
      upper_lcdf[i] = lognormal_lcdf(i | mu, sigma);
    }
  } else if (dist == 3) {
    real emu = exp(mu);
    for (i in 1:n) {
      upper_lcdf[i] = gamma_lcdf(i | emu, sigma);
    }
  } else if (dist == 4) {
    real emu = exp(mu);
    for (i in 1:n) {
      upper_lcdf[i] = loglogistic_lcdf(i | emu, sigma);
    }
  } else {
    reject("Unknown distribution function provided.");
  }
  return(upper_lcdf);
}

// Adjust a vector of cdf evaluations for probability mass beyond maximum value
vector adjust_lcdf_discrete(vector lcdf, int n, int max_strat) {
  vector[n] adjusted_lcdf;
  if (max_strat == 0) {
    // ignore (i.e sum of probability does not add to 1)
    // NOTE: This cannot be used when using lcdf_to_logit_hazard as
    // it will return the same result as using strategy 2.
    adjusted_lcdf = lcdf;
  } else if (max_strat == 1) {
    // add to maximum value: cdf_n = 1
    adjusted_lcdf = lcdf;
    adjusted_lcdf[n] = 0;
  } else if (max_strat == 2) {
    // normalize: cdf = cdf / cdf[n]
    adjusted_lcdf = lcdf - lcdf[n];
  } else {
    reject("Unknown strategy to handle probability mass beyond the maximum value.");
  }
  return(adjusted_lcdf);
}

// compute discretised log scale pmf
vector lcdf_to_log_prob(vector lcdf, int n) {
  vector[n] lpmf; 
  lpmf[1] = lcdf[1];
  // p = cdf_n - cdf_n-1
  lpmf[2:n] = log_diff_exp(lcdf[2:n], lcdf[1:(n-1)]);
  return(lpmf);
}

// compute discretised logit hazard
vector lcdf_to_logit_hazard(vector lcdf, int n) {
  vector[n] lhaz;
  vector[n-1] lccdf;
  // cccdf = 1 - cdf
  lccdf = log1m_exp(lcdf[1:(n-1)]);
  lhaz[1] = lcdf[1];
  // h = 1 - CCDF_n / CCDF_n-1
  lhaz[2:(n-1)] = log1m_exp(lccdf[2:(n-1)] - lccdf[1:(n-2)]);
  // Logit transformation
  lhaz[1:(n-1)] = lhaz[1:(n-1)] - log1m_exp(lhaz[1:(n-1)]);
  // Set last logit transformed hazard to Inf (i.e h[n] = 1)
  lhaz[n] = positive_infinity();
  return(lhaz);
}

// Calculate discreteised logit hazard or log probability
// up to a maximum oberved delay with a range of normalisation strategies
// Calculate the daily hazard of reporting using parametric
// distributions up to the maximum observed delay
vector discretised_logit_hazard(real mu, real sigma, int n, int dist, 
                                int max_strat, int ref_as_p) {
  vector[n] lcdf;
  vector[n] lhaz; 
  lcdf = upper_lcdf_discrete(mu, sigma, n, dist);
  lcdf = adjust_lcdf_discrete(lcdf, n, max_strat);
  if (ref_as_p == 1) {
    lhaz = lcdf_to_log_prob(lcdf, n);
  }else{
    lhaz = lcdf_to_logit_hazard(lcdf, n);
  }
  return(lhaz);
}

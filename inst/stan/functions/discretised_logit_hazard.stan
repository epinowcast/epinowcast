real loglogistic_lcdf (real y, real alpha, real beta) {
  return -log1p((y / alpha) ^-beta);
}

// Compute the cdf of a parametric distribution at values 1:n
vector lcdf_vectorised(real mu, real sigma, int n, int dist) {
  vector[n] integer_lcdf;
  if (dist == 1) {
    real emu = exp(-mu);
    for (i in 1:n) {
      integer_lcdf[i] = exponential_lcdf(i | emu);
    }
  } else if (dist == 2) {
    for (i in 1:n) {
      integer_lcdf[i] = lognormal_lcdf(i | mu, sigma);
    }
  } else if (dist == 3) {
    real emu = exp(mu);
    for (i in 1:n) {
      integer_lcdf[i] = gamma_lcdf(i | emu, sigma);
    }
  } else if (dist == 4) {
    real emu = exp(mu);
    for (i in 1:n) {
      integer_lcdf[i] = loglogistic_lcdf(i | emu, sigma);
    }
  } else {
    reject("Unknown distribution function provided.");
  }
  return(integer_lcdf);
}

// Adjust a vector of cdf evaluations for probability mass beyond maximum value
// Assumes double censoring and a uniform interval approximation
vector normalise_lcdf_as_uniform_double_censored(vector lcdf, int n,
  int max_strat) {
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
    // normalise to account for double censoring
    adjusted_lcdf = adjusted_lcdf - log(2);
  } else if (max_strat == 2) {
    // normalize: cdf = cdf / (cdf[n] + cdf[n-1])
    // both n and n-1 are in the denominator to account for 2 day width of the
    // interval period
    // If n were infinite this would be equivalent to dividing by 2.
    if (n == 1) {
      adjusted_lcdf = lcdf - lcdf[1];
    }
    if (n > 1) {
      adjusted_lcdf = lcdf - log_sum_exp(lcdf[n], lcdf[n-1]);
    }
  } else {
    reject("Unknown strategy to handle probability mass beyond the maximum value.");
  }
  return(adjusted_lcdf);
}

// compute discretised log scale pmf from 0:n
// assumes double censoring and a uniform interval approximation
vector lcdf_to_uniform_double_censored_log_prob(vector lcdf, int n) {
  vector[n] lpmf; 
  // p_0 = cdf_1 - cdf_0
  lpmf[1] = lcdf[1];
  if (n > 1) {
    // p_1 = cdf_2 - cdf_0
    lpmf[2] = lcdf[2];
    if (n > 2) {
      // p_n = cdf_n+1 - cdf_n-1
      lpmf[3:n] = log_diff_exp(lcdf[3:n], lcdf[1:(n-2)]);
    }
  }
  return(lpmf);
}

// compute discretised logit hazard
vector lprob_to_uniform_double_censored_log_hazard(vector lprob, vector lcdf,
   int n) {
  vector[n] lhaz;
  // h_0 = cdf_1
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
    if (n > 2) {
      lhaz[3:(n-1)] = lprob[3:(n-1)] - log_diff_exp(lccdf[2:(n-2)], lcdf[1:(n-3)]);
    }
  }
  return(lhaz);
}

// Convert from log hazard to logit hazard efficiently (i.e. without converting
// to the natural scale)
vector log_hazard_to_logit_hazard(vector lhaz, int n) {
  vector[n] logit_haz;
  // Logit transformation
  logit_haz[1:(n-1)] = lhaz[1:(n-1)] - log1m_exp(lhaz[1:(n-1)]);
  // Set last logit transformed hazard to Inf (i.e h[n] = 1)
  logit_haz[n] = positive_infinity();
  return(logit_haz);
}

// Calculate discreteised logit hazard or log probability
// up to a maximum oberved delay with a range of normalisation strategies
// Assumes that delays are double-censored and that the interval width is 
// approximately uniformly distributed.
vector discretised_logit_hazard(real mu, real sigma, int n, int dist, 
                                int max_strat, int ref_as_p) {
  vector[n] lcdf;
  vector[n] lprob;
  vector[n] logit_haz; 
  lcdf = lcdf_vectorised(mu, sigma, n, dist);
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

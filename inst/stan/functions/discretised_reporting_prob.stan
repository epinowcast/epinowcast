// Compute the cdf of a parametric distribution at values 1:n
vector upper_cdf_discrete(real mu, real sigma, int n, int dist) {
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
vector adjust_cdf_discrete(vector cdf, int n, int max_strat) {
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
vector discretised_reporting_prob(real mu, real sigma, int n, int dist, int max_strat) {
  vector[n] pmf; 
  vector[n] cdf;
  cdf = upper_cdf_discrete(mu, sigma, n, dist);
  cdf = adjust_cdf_discrete(cdf, n, max_strat);
  // compute discretised pmf
  pmf[1] = cdf[1];
  pmf[2:n] = cdf[2:n] - cdf[1:(n-1)];
  return(pmf);
}

// Calculate the daily hazard of reporting using parametric
// distributions up to the maximum observed delay
vector discretised_reporting_hazard(real mu, real sigma, int n, int dist, int max_strat) {
  vector[n] haz; 
  vector[n] cdf;
  vector[n] ccdf;
  cdf = upper_cdf_discrete(mu, sigma, n, dist);
  cdf = adjust_cdf_discrete(cdf, n, max_strat);
  ccdf = 1 - cdf;
  // compute discretised hazard
  haz[1] = cdf[1];
  haz[2:(n-1)] = 1 - ccdf[2:(n-1)]./ccdf[1:(n-2)];
  haz[n] = 1;
  return(haz);
}
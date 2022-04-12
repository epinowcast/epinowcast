// Discretised lognormal daily probability of reporting truncated by the
// maximum delay
vector discretised_lognormal_pmf(real mu, real sigma, int n) {
  vector[n] pmf;
  vector[n] upper_cdf;
  for (i in 1:n) {
    real adj_y = (log(i) - mu) / sigma;
    upper_cdf[i] = normal_cdf(adj_y | 0.0, 1.0);
  }
  pmf[1] = upper_cdf[1];
  pmf[2:n] = upper_cdf[2:n] - upper_cdf[1:(n-1)];
  // normalize
  pmf = pmf / upper_cdf[n];
  return(pmf);
}

// Discretised gamma daily probability of reporting truncated by the
// maximum delay
vector discretised_gamma_pmf(real mu, real sigma, int n) {
  vector[n] pmf;
  // calculate alpha and beta for gamma distribution
  real alpha = (mu / sigma)^2;
  real beta = mu / sigma^2;
  // calculate pmf
  vector[n] upper_cdf;
  for (i in 1:n) {
    upper_cdf[i] = gamma_cdf(i | alpha, beta);
  }
  pmf[1] = upper_cdf[1];
  pmf[2:n] = upper_cdf[2:n] - upper_cdf[1:(n-1)];
  // normalize
  pmf = pmf / upper_cdf[n];
  return(pmf);
}

// Calculate the daily probability of reporting using parameteric
// distributions up to the maximum observed delay
vector calculate_pmf(real logmean, real logsd, int pmf_max, int dist) {
  vector[pmf_max] pmf;
  if (dist == 0) {
    pmf = discretised_lognormal_pmf(logmean, logsd, pmf_max);
  }else if (dist == 1) {
    pmf = discretised_gamma_pmf(exp(logmean), logsd, pmf_max);
  }
  return(pmf);
}
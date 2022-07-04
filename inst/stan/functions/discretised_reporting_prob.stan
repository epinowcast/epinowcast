// Calculate the daily probability of reporting using parametric
// distributions up to the maximum observed delay
vector discretised_reporting_prob(real mu, real sigma, int n, int dist) {
  vector[n] pmf; 
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
  } else {
    reject("Unknown distribution function provided.");
  }
  // discretise
  pmf[1] = upper_cdf[1];
  pmf[2:n] = upper_cdf[2:n] - upper_cdf[1:(n-1)];
  // normalize
  pmf = pmf / upper_cdf[n];
  return(pmf);
}
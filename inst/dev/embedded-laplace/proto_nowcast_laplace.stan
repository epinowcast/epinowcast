// Embedded-Laplace nowcast: GP latent trend on log expected counts by
// reference date, marginalised analytically; NB2 observation of the
// reporting triangle with a static discretised-lognormal reporting delay.
functions {
  // GP prior covariance over reference-date indices.
  matrix cov_fn(array[] real x, real gp_alpha, real gp_rho) {
    return add_diag(gp_exp_quad_cov(x, gp_alpha, gp_rho), 1e-6);
  }
  // Custom log-likelihood over observed triangle cells, conditional on the
  // latent field `theta` (GP deviations by reference date). Each cell maps
  // to a single theta element so the Hessian is diagonal (block size 1).
  // eta = intercept + theta[ref] + log_p_delay[cell]; NB2 is log-concave in
  // eta and eta is linear in theta, so the likelihood is log-concave.
  real ll_fn(vector theta, array[] int y, array[] int cell_t,
             vector cell_logp, real intercept, real phi) {
    int n = num_elements(y);
    vector[n] eta;
    for (i in 1:n) {
      eta[i] = intercept + theta[cell_t[i]] + cell_logp[i];
    }
    return neg_binomial_2_log_lpmf(y | eta, phi);
  }
}
data {
  int<lower=1> T;                 // number of reference dates
  int<lower=0> D;                 // max delay index (delays 0..D)
  int<lower=1> n_obs;             // number of observed triangle cells
  array[n_obs] int<lower=0> y;    // observed counts
  array[n_obs] int<lower=1> cell_t;   // reference-date index per cell (1..T)
  array[n_obs] int<lower=0> cell_d;   // delay per cell (0..D)
  array[T] real ref_x;            // reference-date coordinates for the GP
  array[T] int<lower=0> row_obs_sum;  // observed total per reference date
}
parameters {
  real intercept;
  real<lower=0> gp_alpha;
  real<lower=0> gp_rho;
  real delay_mu;
  real<lower=0> delay_sigma;
  real<lower=0> phi;
}
transformed parameters {
  // Discretised, truncated (0..D) lognormal reporting-delay pmf.
  vector[D + 1] log_p_delay;
  {
    vector[D + 1] cdf_hi;
    for (d in 0:D) {
      cdf_hi[d + 1] = lognormal_cdf(d + 1 | delay_mu, delay_sigma);
    }
    vector[D + 1] pmf;
    pmf[1] = cdf_hi[1];
    for (d in 1:D) {
      pmf[d + 1] = cdf_hi[d + 1] - cdf_hi[d];
    }
    pmf = pmf / sum(pmf);
    log_p_delay = log(pmf);
  }
  // Per-cell log delay probability.
  vector[n_obs] cell_logp;
  for (i in 1:n_obs) {
    cell_logp[i] = log_p_delay[cell_d[i] + 1];
  }
}
model {
  intercept ~ normal(5, 5);
  gp_alpha ~ normal(0, 1);
  gp_rho ~ inv_gamma(5, 5);
  delay_mu ~ normal(1.5, 1);
  delay_sigma ~ normal(0.5, 0.5);
  phi ~ normal(0, 5);
  target += laplace_marginal(
    ll_fn, (y, cell_t, cell_logp, intercept, phi), 1,
    cov_fn, (ref_x, gp_alpha, gp_rho)
  );
}
generated quantities {
  vector[T] theta = laplace_latent_rng(
    ll_fn, (y, cell_t, cell_logp, intercept, phi), 1,
    cov_fn, (ref_x, gp_alpha, gp_rho)
  );
  // Nowcast: observed total plus predicted unobserved cells (delay > T - t).
  array[T] int nowcast;
  for (t in 1:T) {
    real lambda_t = exp(intercept + theta[t]);
    int pred = 0;
    for (d in (T - t + 1):D) {
      if (d <= D) {
        pred += neg_binomial_2_rng(lambda_t * exp(log_p_delay[d + 1]), phi);
      }
    }
    nowcast[t] = row_obs_sum[t] + pred;
  }
}

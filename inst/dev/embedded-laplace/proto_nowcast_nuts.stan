// NUTS reference: identical model with the GP latent field sampled
// explicitly (gold standard for validating the embedded-Laplace version).
functions {
  matrix cov_fn(array[] real x, real gp_alpha, real gp_rho) {
    return add_diag(gp_exp_quad_cov(x, gp_alpha, gp_rho), 1e-6);
  }
}
data {
  int<lower=1> T;
  int<lower=0> D;
  int<lower=1> n_obs;
  array[n_obs] int<lower=0> y;
  array[n_obs] int<lower=1> cell_t;
  array[n_obs] int<lower=0> cell_d;
  array[T] real ref_x;
  array[T] int<lower=0> row_obs_sum;
}
parameters {
  real intercept;
  real<lower=0> gp_alpha;
  real<lower=0> gp_rho;
  real delay_mu;
  real<lower=0> delay_sigma;
  real<lower=0> phi;
  vector[T] theta_std;            // non-centred GP coefficients
}
transformed parameters {
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
  matrix[T, T] L = cholesky_decompose(cov_fn(ref_x, gp_alpha, gp_rho));
  vector[T] theta = L * theta_std;
}
model {
  intercept ~ normal(5, 5);
  gp_alpha ~ normal(0, 1);
  gp_rho ~ inv_gamma(5, 5);
  delay_mu ~ normal(1.5, 1);
  delay_sigma ~ normal(0.5, 0.5);
  phi ~ normal(0, 5);
  theta_std ~ std_normal();
  {
    vector[n_obs] eta;
    for (i in 1:n_obs) {
      eta[i] = intercept + theta[cell_t[i]] + log_p_delay[cell_d[i] + 1];
    }
    target += neg_binomial_2_log_lpmf(y | eta, phi);
  }
}
generated quantities {
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

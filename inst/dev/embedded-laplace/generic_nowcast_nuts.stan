// NUTS reference for the generic embedded-Laplace nowcast.
//
// Identical model and priors, but each group's latent field is sampled
// explicitly (non-centred) via the Cholesky factor of the same additively
// assembled covariance K(phi). This is the gold standard for validating the
// embedded-Laplace marginalisation.
functions {
  matrix gp_cov(array[] real x, real alpha, real rho, int kernel_type) {
    int n = size(x);
    if (kernel_type == 1) {
      return gp_exp_quad_cov(x, alpha, rho);
    } else {
      matrix[n, n] K;
      real a2 = square(alpha);
      real s3 = sqrt(3.0);
      for (i in 1:n) {
        K[i, i] = a2;
        for (j in (i + 1):n) {
          real r = abs(x[i] - x[j]);
          real c = s3 * r / rho;
          real v = a2 * (1 + c) * exp(-c);
          K[i, j] = v;
          K[j, i] = v;
        }
      }
      return K;
    }
  }

  vector hsgp_sd(real alpha, real rho, vector lambda) {
    int M = num_elements(lambda);
    vector[M] s;
    real c = alpha * sqrt(sqrt(2 * pi()) * rho);
    for (m in 1:M) {
      s[m] = c * exp(-0.25 * square(rho) * lambda[m]);
    }
    return s;
  }

  matrix cov_fn(
    int n_ref,
    int use_re, matrix Z, vector sigma_re,
    int use_gp, array[] real ref_x, real gp_alpha, real gp_rho,
    int gp_kernel,
    int use_hsgp, matrix PHI, vector hsgp_lambda, real hsgp_alpha,
    real hsgp_rho,
    real jitter
  ) {
    matrix[n_ref, n_ref] K = rep_matrix(0, n_ref, n_ref);
    if (use_re == 1) {
      K += diag_post_multiply(Z, square(sigma_re)) * Z';
    }
    if (use_gp == 1) {
      K += gp_cov(ref_x, gp_alpha, gp_rho, gp_kernel);
    }
    if (use_hsgp == 1) {
      vector[num_elements(hsgp_lambda)] s = hsgp_sd(
        hsgp_alpha, hsgp_rho, hsgp_lambda
      );
      K += diag_post_multiply(PHI, square(s)) * PHI';
    }
    return add_diag(K, jitter);
  }
}
data {
  int<lower=1> G;
  int<lower=1> T;
  int<lower=0> D;
  int<lower=1> n_obs;
  array[n_obs] int<lower=0> y;
  array[n_obs] int<lower=1> cell_g;
  array[n_obs] int<lower=1> cell_t;
  array[n_obs] int<lower=0> cell_d;

  int<lower=1> P;
  matrix[G * T, P] X_fixed;

  int<lower=0, upper=1> use_re;
  int<lower=0> q_re;
  matrix[T, q_re] Z;

  int<lower=0, upper=1> use_gp;
  int<lower=1, upper=2> gp_kernel;
  array[T] real ref_x;

  int<lower=0, upper=1> use_hsgp;
  int<lower=0> M_hsgp;
  matrix[T, M_hsgp] PHI;
  vector[M_hsgp] hsgp_lambda;

  real<lower=0> jitter;

  int<lower=1, upper=2> obs_family;

  vector[P] prior_beta_mean;
  vector<lower=0>[P] prior_beta_sd;
  real<lower=0> prior_sigma_re_sd;
  real prior_gp_alpha_sd;
  real prior_gp_rho_a;
  real prior_gp_rho_b;
  real prior_hsgp_alpha_sd;
  real prior_hsgp_rho_a;
  real prior_hsgp_rho_b;
  real prior_delay_mu_mean;
  real<lower=0> prior_delay_mu_sd;
  real<lower=0> prior_delay_sigma_sd;
  real<lower=0> prior_phi_sd;

  array[G, T] int<lower=0> row_obs_sum;
}
parameters {
  vector[P] beta_fixed;
  vector<lower=0>[q_re] sigma_re;
  real<lower=0> gp_alpha;
  real<lower=0> gp_rho;
  real<lower=0> hsgp_alpha;
  real<lower=0> hsgp_rho;
  real delay_mu;
  real<lower=0> delay_sigma;
  real<lower=0> phi;
  matrix[T, G] theta_std;             // non-centred latent fields per group
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
  matrix[G, T] mu_ref;
  {
    vector[G * T] mu_flat = X_fixed * beta_fixed;
    for (g in 1:G) {
      for (t in 1:T) {
        mu_ref[g, t] = mu_flat[(g - 1) * T + t];
      }
    }
  }
  // Same covariance, shared across groups; sample each field non-centred.
  matrix[T, T] L = cholesky_decompose(cov_fn(
    T, use_re, Z, sigma_re, use_gp, ref_x, gp_alpha, gp_rho, gp_kernel,
    use_hsgp, PHI, hsgp_lambda, hsgp_alpha, hsgp_rho, jitter
  ));
  matrix[T, G] theta = L * theta_std;
}
model {
  beta_fixed ~ normal(prior_beta_mean, prior_beta_sd);
  if (q_re > 0) {
    sigma_re ~ normal(0, prior_sigma_re_sd);
  }
  gp_alpha ~ normal(0, prior_gp_alpha_sd);
  gp_rho ~ inv_gamma(prior_gp_rho_a, prior_gp_rho_b);
  hsgp_alpha ~ normal(0, prior_hsgp_alpha_sd);
  hsgp_rho ~ inv_gamma(prior_hsgp_rho_a, prior_hsgp_rho_b);
  delay_mu ~ normal(prior_delay_mu_mean, prior_delay_mu_sd);
  delay_sigma ~ normal(0, prior_delay_sigma_sd);
  phi ~ normal(0, prior_phi_sd);
  to_vector(theta_std) ~ std_normal();
  {
    vector[n_obs] eta;
    for (i in 1:n_obs) {
      eta[i] = mu_ref[cell_g[i], cell_t[i]]
               + theta[cell_t[i], cell_g[i]]
               + log_p_delay[cell_d[i] + 1];
    }
    if (obs_family == 1) {
      target += neg_binomial_2_log_lpmf(y | eta, phi);
    } else {
      target += poisson_log_lpmf(y | eta);
    }
  }
}
generated quantities {
  array[G, T] int nowcast;
  for (g in 1:G) {
    for (t in 1:T) {
      real eta_base = mu_ref[g, t] + theta[t, g];
      int pred = 0;
      for (d in (T - t + 1):D) {
        real eta_cell = eta_base + log_p_delay[d + 1];
        if (obs_family == 1) {
          pred += neg_binomial_2_log_rng(eta_cell, phi);
        } else {
          pred += poisson_log_rng(eta_cell);
        }
      }
      nowcast[g, t] = row_obs_sum[g, t] + pred;
    }
  }
}

// Matched NUTS reference for the package embedded-Laplace nowcast model.
//
// Shares the EXACT data block, priors, delay discretisation and observation
// family of inst/stan/models/epinowcast_laplace.stan, but samples the latent
// log-expected-count field theta_g ~ MVN(0, K_g) per group (non-centred via a
// Cholesky factor) instead of marginalising it analytically. This isolates the
// embedded-Laplace approximation: any difference in the nowcast or the
// hyperparameters between this model and the Laplace model is attributable to
// the approximation, not to a model-specification mismatch.
//
// Used only by inst/dev/embedded-laplace/validate_package.R; it is not part of
// the package build.
functions {
#include functions/primarycensored.stan
#include functions/primarycensored_pmf.stan
#include functions/gaussian_process.stan

  matrix laplace_cov(
    int T,
    int use_re, matrix Z, vector sigma_re, array[] int re_index,
    int use_gp, matrix PHI, int gp_M, real gp_L, int gp_type, real gp_nu,
    real gp_alpha, real gp_rho,
    real jitter
  ) {
    matrix[T, T] K = rep_matrix(0, T, T);
    if (use_re == 1) {
      int q = cols(Z);
      vector[q] col_var;
      for (j in 1:q) {
        col_var[j] = square(sigma_re[re_index[j]]);
      }
      K += diag_post_multiply(Z, col_var) * Z';
    }
    if (use_gp == 1) {
      vector[gp_type == 1 ? 2 * gp_M : gp_M] s;
      if (gp_type == 0) {
        s = diagSPD_EQ(gp_alpha, gp_rho, gp_L, gp_M);
      } else if (gp_type == 1) {
        s = diagSPD_Periodic(gp_alpha, gp_rho, gp_M);
      } else {
        if (gp_nu == 0.5) {
          s = diagSPD_Matern12(gp_alpha, gp_rho, gp_L, gp_M);
        } else if (gp_nu == 1.5) {
          s = diagSPD_Matern32(gp_alpha, gp_rho, gp_L, gp_M);
        } else {
          s = diagSPD_Matern52(gp_alpha, gp_rho, gp_L, gp_M);
        }
      }
      K += diag_post_multiply(PHI, square(s)) * PHI';
    }
    return add_diag(K, jitter);
  }
}
data {
  int<lower=1> g;
  int<lower=1> t;
  int<lower=1> dmax;
  int<lower=1> n_obs;
  array[n_obs] int<lower=0> obs;
  array[n_obs] int<lower=1> cell_g;
  array[n_obs] int<lower=1> cell_t;
  array[n_obs] int<lower=0> cell_d;
  int<lower=1> nc_t;
  array[g, t] int<lower=0> row_obs_sum;

  int<lower=0> expr_fncol;
  int<lower=0, upper=1> expr_fintercept;
  matrix[g * t, expr_fncol + expr_fintercept] X_fixed;

  int<lower=0, upper=1> use_re;
  int<lower=0> q_re;
  int<lower=0> n_re;
  matrix[t, q_re] Z;
  array[q_re] int<lower=1> re_index;

  int<lower=0, upper=1> use_gp;
  int<lower=0> gp_M;
  int<lower=0, upper=2> gp_type;
  real<lower=0> gp_nu;
  real<lower=0> gp_L;
  matrix[t, use_gp ? (gp_type == 1 ? 2 * gp_M : gp_M) : 0] PHI;

  real<lower=0> jitter;

  int<lower=0, upper=1> obs_family;
  int<lower=1, upper=3> model_refp;

  array[2] real prior_beta_int;
  array[2] real prior_beta;
  array[2] real prior_sigma_re;
  array[2] real prior_gp_alpha;
  array[2] real prior_gp_rho;
  array[2] real prior_refp_mean;
  array[2] real prior_refp_sd;
  array[2] real prior_sqrt_phi;
}
transformed data {
  int n_beta = expr_fncol + expr_fintercept;
}
parameters {
  vector[n_beta] beta_fixed;
  vector<lower=0>[n_re] sigma_re;
  array[use_gp ? 1 : 0] real<lower=0> gp_alpha;
  array[use_gp ? 1 : 0] real<lower=0> gp_rho;
  array[model_refp ? 1 : 0] real refp_mean_int;
  array[model_refp > 1 ? 1 : 0] real<lower=1e-3, upper=2 * dmax> refp_sd_int;
  array[obs_family ? 1 : 0] real<lower=0> sqrt_phi;
  // Non-centred latent field per group (standard normal).
  matrix[t, g] z_theta;
}
transformed parameters {
  vector[dmax] log_p_delay;
  {
    real mu = model_refp ? refp_mean_int[1] : 0;
    real sigma = model_refp > 1 ? refp_sd_int[1] : 1;
    log_p_delay = discretised_pcens_logit_hazard(
      mu, sigma, dmax, model_refp, 1
    );
  }
  real phi = obs_family ? inv_square(sqrt_phi[1]) : 0;
  matrix[g, t] mu_ref;
  {
    vector[g * t] mu_flat = n_beta > 0 ? X_fixed * beta_fixed
                                       : rep_vector(0, g * t);
    for (gg in 1:g) {
      for (tt in 1:t) {
        mu_ref[gg, tt] = mu_flat[(gg - 1) * t + tt];
      }
    }
  }
  // Latent field via Cholesky of the same covariance.
  matrix[t, g] theta;
  {
    real alpha = use_gp ? gp_alpha[1] : 0;
    real rho = use_gp ? gp_rho[1] : 1;
    matrix[t, t] K = laplace_cov(
      t, use_re, Z, sigma_re, re_index, use_gp, PHI, gp_M, gp_L,
      gp_type, gp_nu, alpha, rho, jitter
    );
    matrix[t, t] L = cholesky_decompose(K);
    for (gg in 1:g) {
      theta[, gg] = L * z_theta[, gg];
    }
  }
}
model {
  if (expr_fintercept) {
    beta_fixed[1] ~ normal(prior_beta_int[1], prior_beta_int[2]);
  }
  if (expr_fncol > 0) {
    beta_fixed[(expr_fintercept + 1):n_beta] ~
      normal(prior_beta[1], prior_beta[2]);
  }
  if (use_re == 1) {
    sigma_re ~ normal(prior_sigma_re[1], prior_sigma_re[2]);
  }
  if (use_gp == 1) {
    gp_alpha[1] ~ normal(prior_gp_alpha[1], prior_gp_alpha[2]);
    gp_rho[1] ~ lognormal(prior_gp_rho[1], prior_gp_rho[2]);
  }
  if (model_refp) {
    refp_mean_int[1] ~ normal(prior_refp_mean[1], prior_refp_mean[2]);
  }
  if (model_refp > 1) {
    refp_sd_int[1] ~ normal(prior_refp_sd[1], prior_refp_sd[2]);
  }
  if (obs_family) {
    sqrt_phi[1] ~ normal(prior_sqrt_phi[1], prior_sqrt_phi[2]) T[0, ];
  }
  to_vector(z_theta) ~ std_normal();

  // Likelihood over observed cells.
  {
    vector[n_obs] eta;
    for (i in 1:n_obs) {
      eta[i] = mu_ref[cell_g[i], cell_t[i]] + theta[cell_t[i], cell_g[i]]
        + log_p_delay[cell_d[i] + 1];
    }
    if (obs_family == 1) {
      obs ~ neg_binomial_2_log(eta, phi);
    } else {
      obs ~ poisson_log(eta);
    }
  }
}
generated quantities {
  vector[g * nc_t] pp_inf_obs;
  {
    int out_pos = 1;
    for (gg in 1:g) {
      for (tt in (t - nc_t + 1):t) {
        real eta_base = mu_ref[gg, tt] + theta[tt, gg];
        int pred = 0;
        for (d in (t - tt + 1):(dmax - 1)) {
          real eta_cell = eta_base + log_p_delay[d + 1];
          if (obs_family == 1) {
            pred += neg_binomial_2_log_rng(eta_cell, phi);
          } else {
            pred += poisson_log_rng(eta_cell);
          }
        }
        pp_inf_obs[out_pos] = row_obs_sum[gg, tt] + pred;
        out_pos += 1;
      }
    }
  }
}

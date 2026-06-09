// Experimental embedded-Laplace nowcast model for epinowcast.
//
// This is an opt-in, experimental, generic inference path that marginalises
// the latent log-expected-count field analytically with Stan's embedded
// Laplace approximation (`laplace_marginal_*`, Stan >= 2.39) instead of
// sampling it with NUTS. It reuses epinowcast's existing modules for the
// expectation design (fixed + random effects and/or a `gp()` term), the
// parametric reference delay discretisation (primarycensored), and the
// observation family.
//
// The latent field over reference dates is a zero-mean Gaussian vector per
// group with a covariance K(phi) assembled additively from switchable
// components:
//   * random-effect blocks  Z diag(sigma_re^2) Z'  (from the expectation
//     `(1 | ...)` terms; the design matrix is `Z`, the half-normal sd priors
//     are `sigma_re`);
//   * a Hilbert-space reduced-rank GP  PHI diag(S(alpha, rho)) PHI'  (from a
//     `gp()` term; the basis `PHI` and the kernel spectral density reuse the
//     package's `gaussian_process.stan` functions);
//   * jitter on the diagonal for numerical positive-definiteness.
// The fixed-effect mean `X_fixed * beta_fixed` enters the per-cell linear
// predictor (it is NOT part of the marginalised field, which must stay
// zero-mean as the embedded-Laplace API requires).
//
// Each group is marginalised independently: the per-group joint marginal
// factorises exactly into a sum because groups are a priori independent. This
// keeps each Newton solve small (T x T) and the Hessian block size 1.
//
// Log-concavity: eta is linear in the latent field theta
// (eta = mean + theta[ref] + log_p_delay), and both neg_binomial_2_log and
// poisson_log are log-concave in their log-mean, so the per-group likelihood
// is log-concave in theta and the Laplace approximation is well behaved.
functions {
#include functions/primarycensored.stan
#include functions/primarycensored_pmf.stan
#include functions/gaussian_process.stan

  // Generic additive covariance functor over one group's T reference dates.
  // Assembles whichever components are active and returns the dense T x T
  // matrix. Mirrors the components epinowcast's expectation module can build.
  // sigma_re holds one sd per random-effect group; re_index maps each Z column
  // to its group so the per-column variance is sigma_re[re_index]^2.
  matrix laplace_cov(
    int T,
    int use_re, matrix Z, vector sigma_re, array[] int re_index,
    int use_gp, matrix PHI, int gp_M, real gp_L, int gp_type, real gp_nu,
    real gp_alpha, real gp_rho,
    real jitter
  ) {
    matrix[T, T] K = rep_matrix(0, T, T);
    if (use_re == 1) {
      // Z diag(sigma_re[re_index]^2) Z'.
      int q = cols(Z);
      vector[q] col_var;
      for (j in 1:q) {
        col_var[j] = square(sigma_re[re_index[j]]);
      }
      K += diag_post_multiply(Z, col_var) * Z';
    }
    if (use_gp == 1) {
      // Reuse the package spectral density so the marginal GP covariance
      // PHI diag(S^2) PHI' matches the sampled `gp()` term exactly:
      // var(PHI (S .* eta)) = PHI diag(S^2) PHI' for eta ~ N(0, I).
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

  // Custom log-likelihood over one group's observed triangle cells given the
  // group's latent field theta. cell_mean carries the fixed-effect mean for
  // the cell's reference date plus the discretised log delay pmf, so
  // eta = cell_mean + theta[cell_ref]. obs_family: 1 = NB2, 0 = Poisson.
  real laplace_ll(vector theta, array[] int y, array[] int cell_ref,
                  vector cell_mean, real phi, int obs_family) {
    int n = num_elements(y);
    vector[n] eta;
    for (i in 1:n) {
      eta[i] = cell_mean[i] + theta[cell_ref[i]];
    }
    if (obs_family == 1) {
      return neg_binomial_2_log_lpmf(y | eta, phi);
    } else {
      return poisson_log_lpmf(y | eta);
    }
  }
}
data {
  int<lower=1> g;                     // number of groups
  int<lower=1> t;                     // reference dates per group
  int<lower=1> dmax;                  // maximum delay (delays 0..dmax-1)
  int<lower=1> n_obs;                 // total observed cells across groups
  array[n_obs] int<lower=0> obs;      // observed counts
  array[n_obs] int<lower=1> cell_g;   // group index per cell (1..g)
  array[n_obs] int<lower=1> cell_t;   // ref-date index per cell (1..t)
  array[n_obs] int<lower=0> cell_d;   // delay per cell (0..dmax-1)
  int<lower=1> nc_t;                  // number of nowcast ref dates per group
  array[g, t] int<lower=0> row_obs_sum;  // observed total per group/ref date

  // fixed-effect mean design (per group, per ref date). Row (gg-1)*t + tt.
  int<lower=0> expr_fncol;            // number of fixed-effect columns
  int<lower=0, upper=1> expr_fintercept;
  matrix[g * t, expr_fncol + expr_fintercept] X_fixed;

  // random-effect covariance block (from the expectation `(1 | ...)` terms).
  int<lower=0, upper=1> use_re;
  int<lower=0> q_re;                  // number of RE design columns
  int<lower=0> n_re;                  // number of RE standard deviations
  matrix[t, q_re] Z;                  // RE design (shared across groups)
  array[q_re] int<lower=1> re_index;  // RE group per Z column (into sigma_re)

  // Hilbert-space reduced-rank GP block (from a `gp()` term).
  int<lower=0, upper=1> use_gp;
  int<lower=0> gp_M;                  // number of basis functions
  int<lower=0, upper=2> gp_type;      // 0 SE, 1 periodic, 2 Matern
  real<lower=0> gp_nu;                // Matern smoothness
  real<lower=0> gp_L;                 // boundary factor
  matrix[t, use_gp ? (gp_type == 1 ? 2 * gp_M : gp_M) : 0] PHI;

  real<lower=0> jitter;

  int<lower=0, upper=1> obs_family;   // 1 = NB2, 0 = Poisson
  int<lower=1, upper=3> model_refp;   // 1 exp, 2 lognormal, 3 gamma

  // priors (as data so they can change without recompiling)
  array[2] real prior_beta_int;       // intercept (mean, sd)
  array[2] real prior_beta;           // non-intercept betas (mean, sd)
  array[2] real prior_sigma_re;       // half-normal sd for RE sds (mean, sd)
  array[2] real prior_gp_alpha;       // GP magnitude (mean, sd)
  array[2] real prior_gp_rho;         // GP length scale (lognormal mean, sd)
  array[2] real prior_refp_mean;      // delay mean intercept (mean, sd)
  array[2] real prior_refp_sd;        // delay sd intercept (mean, sd)
  array[2] real prior_sqrt_phi;       // 1/sqrt(overdispersion) (mean, sd)
}
transformed data {
  // Per-group cell counts (cells are stored group-major).
  array[g] int n_g = rep_array(0, g);
  for (i in 1:n_obs) {
    n_g[cell_g[i]] += 1;
  }
  // Number of fixed-effect mean columns actually present.
  int n_beta = expr_fncol + expr_fintercept;
}
parameters {
  vector[n_beta] beta_fixed;
  vector<lower=0>[n_re] sigma_re;            // RE sds (only used if use_re)
  array[use_gp ? 1 : 0] real<lower=0> gp_alpha;
  array[use_gp ? 1 : 0] real<lower=0> gp_rho;
  array[model_refp ? 1 : 0] real refp_mean_int;
  array[model_refp > 1 ? 1 : 0] real<lower=1e-3, upper=2 * dmax> refp_sd_int;
  array[obs_family ? 1 : 0] real<lower=0> sqrt_phi;
}
transformed parameters {
  // Discretised parametric reference delay log pmf (primarycensored double
  // interval censoring), reusing the package discretisation.
  vector[dmax] log_p_delay;
  {
    real mu = model_refp ? refp_mean_int[1] : 0;
    real sigma = model_refp > 1 ? refp_sd_int[1] : 1;
    log_p_delay = discretised_pcens_logit_hazard(
      mu, sigma, dmax, model_refp, 1
    );
  }
  // Overdispersion (NB2): phi = 1 / sqrt_phi^2.
  real phi = obs_family ? inv_square(sqrt_phi[1]) : 0;
  // Fixed-effect mean per (group, ref date).
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
  // Per-cell mean folded for the likelihood: fixed-effect mean + log delay.
  vector[n_obs] cell_mean;
  for (i in 1:n_obs) {
    cell_mean[i] = mu_ref[cell_g[i], cell_t[i]] + log_p_delay[cell_d[i] + 1];
  }
}
model {
  // priors
  if (expr_fintercept) {
    beta_fixed[1] ~ normal(prior_beta_int[1], prior_beta_int[2]);
  }
  if (expr_fncol > 0) {
    beta_fixed[(expr_fintercept + 1):n_beta] ~
      normal(prior_beta[1], prior_beta[2]);
  }
  if (use_re == 1) {
    sigma_re ~ normal(prior_sigma_re[1], prior_sigma_re[2]);  // half-normal
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

  // Marginalise each group's latent field independently and sum targets.
  {
    int pos = 1;
    real alpha = use_gp ? gp_alpha[1] : 0;
    real rho = use_gp ? gp_rho[1] : 1;
    for (gg in 1:g) {
      int ng = n_g[gg];
      array[ng] int yg = segment(obs, pos, ng);
      array[ng] int refg = segment(cell_t, pos, ng);
      vector[ng] meang = segment(cell_mean, pos, ng);
      target += laplace_marginal(
        laplace_ll, (yg, refg, meang, phi, obs_family), 1,
        laplace_cov, (
          t, use_re, Z, sigma_re, re_index, use_gp, PHI, gp_M, gp_L,
          gp_type, gp_nu, alpha, rho, jitter
        )
      );
      pos += ng;
    }
  }
}
generated quantities {
  // Draw each group's latent field, then reconstruct the nowcast (observed
  // total + predicted unobserved cells with delay > t - tt) for the last
  // `nc_t` reference dates per group, group-major. Matches the package's
  // `pp_inf_obs` snapshot ordering so `summary(type = "nowcast")` works.
  vector[g * nc_t] pp_inf_obs;
  {
    int pos = 1;
    int out_pos = 1;
    real alpha = use_gp ? gp_alpha[1] : 0;
    real rho = use_gp ? gp_rho[1] : 1;
    for (gg in 1:g) {
      int ng = n_g[gg];
      array[ng] int yg = segment(obs, pos, ng);
      array[ng] int refg = segment(cell_t, pos, ng);
      vector[ng] meang = segment(cell_mean, pos, ng);
      vector[t] theta_g = laplace_latent_rng(
        laplace_ll, (yg, refg, meang, phi, obs_family), 1,
        laplace_cov, (
          t, use_re, Z, sigma_re, re_index, use_gp, PHI, gp_M, gp_L,
          gp_type, gp_nu, alpha, rho, jitter
        )
      );
      for (tt in (t - nc_t + 1):t) {
        real eta_base = mu_ref[gg, tt] + theta_g[tt];
        int pred = 0;
        // Unobserved delays for ref date tt are (t - tt + 1)..(dmax - 1).
        for (d in (t - tt + 1):(dmax - 1)) {
          if (d >= 0 && d <= dmax - 1) {
            real eta_cell = eta_base + log_p_delay[d + 1];
            if (obs_family == 1) {
              pred += neg_binomial_2_log_rng(eta_cell, phi);
            } else {
              pred += poisson_log_rng(eta_cell);
            }
          }
        }
        pp_inf_obs[out_pos] = row_obs_sum[gg, tt] + pred;
        out_pos += 1;
      }
      pos += ng;
    }
  }
}

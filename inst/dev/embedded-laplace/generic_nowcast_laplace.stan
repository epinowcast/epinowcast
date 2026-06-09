// Generic embedded-Laplace nowcast.
//
// The latent log-expected-count field over reference dates is a zero-mean
// Gaussian vector per group, with a covariance K(phi) assembled additively
// from switchable components:
//   * random-effect blocks  Z diag(sigma_re^2) Z'
//   * a Gaussian process     (full-rank SqExp / Matern-3/2) over ref-date x
//   * a Hilbert-space GP      PHI diag(S(alpha,rho)) PHI'  (reduced rank)
//   * jitter on the diagonal for numerical positive-definiteness.
// The fixed-effect mean X_fixed * beta_fixed enters the per-cell linear
// predictor eta (it is NOT part of the marginalised latent field, so the
// field stays zero-mean Gaussian as the embedded-Laplace API requires).
//
// Each group is marginalised independently: we loop over groups and call
// laplace_marginal once per group with that group's cells and covariance,
// summing the marginal targets. This is preferred over one big
// block-diagonal covariance because (a) groups are a priori independent so
// the joint marginal factorises exactly into the per-group sum, (b) it keeps
// each Newton solve small (T_g x T_g) rather than (sum T_g)^2, and (c) the
// per-cell -> single-latent mapping keeps hessian_block_size = 1 within each
// group without any cross-group padding/masking.
//
// Log-concavity: eta is linear in the latent field theta (eta = mean +
// theta[ref] + log_p_delay), and both neg_binomial_2_log and poisson_log are
// log-concave in their log-mean. Hence the per-group likelihood is
// log-concave in theta and the Laplace approximation is well behaved.
functions {
  // Squared-exponential / Matern-3/2 covariance over scalar coordinates.
  // kernel_type: 1 = squared exponential, 2 = Matern-3/2.
  matrix gp_cov(array[] real x, real alpha, real rho, int kernel_type) {
    int n = size(x);
    if (kernel_type == 1) {
      return gp_exp_quad_cov(x, alpha, rho);
    } else {
      // Matern-3/2: alpha^2 (1 + sqrt(3) r / rho) exp(-sqrt(3) r / rho).
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

  // Hilbert-space reduced-rank GP spectral density S(omega) for a
  // squared-exponential kernel (Riutort-Mayol et al. 2023). PHI holds the
  // basis evaluated at the ref-date coordinates and lambda the eigenvalues.
  vector hsgp_sd(real alpha, real rho, vector lambda) {
    int M = num_elements(lambda);
    vector[M] s;
    real c = alpha * sqrt(sqrt(2 * pi()) * rho);
    for (m in 1:M) {
      s[m] = c * exp(-0.25 * square(rho) * lambda[m]);
    }
    return s;  // returns sqrt(spectral density) * scale; squared below.
  }

  // Generic covariance functor. Assembles whichever components are active
  // from the cov_args tuple and returns the dense n_ref x n_ref matrix.
  matrix cov_fn(
    int n_ref,
    // random-effect block
    int use_re, matrix Z, vector sigma_re,
    // full-rank GP
    int use_gp, array[] real ref_x, real gp_alpha, real gp_rho,
    int gp_kernel,
    // Hilbert-space GP
    int use_hsgp, matrix PHI, vector hsgp_lambda, real hsgp_alpha,
    real hsgp_rho,
    real jitter
  ) {
    matrix[n_ref, n_ref] K = rep_matrix(0, n_ref, n_ref);
    if (use_re == 1) {
      // Z diag(sigma_re^2) Z' = (Z .* row sigma_re^2) Z'.
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

  // Custom log-likelihood over one group's observed triangle cells, given
  // the group's latent field theta. cell_mean carries the fixed-effect mean
  // X_fixed*beta_fixed for the cell's reference date plus log_p_delay, so
  // eta = cell_mean + theta[cell_ref]. obs_family: 1 = NB2, 2 = Poisson.
  real ll_fn(vector theta, array[] int y, array[] int cell_ref,
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
  int<lower=1> G;                     // number of groups
  int<lower=1> T;                     // ref dates per group (shared length)
  int<lower=0> D;                     // max delay index (0..D)
  int<lower=1> n_obs;                 // total observed cells across groups
  array[n_obs] int<lower=0> y;        // observed counts
  array[n_obs] int<lower=1> cell_g;   // group index per cell (1..G)
  array[n_obs] int<lower=1> cell_t;   // ref-date index per cell (1..T)
  array[n_obs] int<lower=0> cell_d;   // delay per cell (0..D)

  // fixed-effect design (per group, per ref date). Row (g-1)*T + t.
  int<lower=1> P;                     // number of fixed-effect columns
  matrix[G * T, P] X_fixed;

  // covariance component switches and inputs
  int<lower=0, upper=1> use_re;
  int<lower=0> q_re;                  // number of RE columns
  matrix[T, q_re] Z;                  // RE design (shared across groups)

  int<lower=0, upper=1> use_gp;
  int<lower=1, upper=2> gp_kernel;    // 1 = SqExp, 2 = Matern-3/2
  array[T] real ref_x;                // ref-date coordinates

  int<lower=0, upper=1> use_hsgp;
  int<lower=0> M_hsgp;                // number of basis functions
  matrix[T, M_hsgp] PHI;              // HSGP basis at ref-date coords
  vector[M_hsgp] hsgp_lambda;         // HSGP eigenvalues

  real<lower=0> jitter;

  int<lower=1, upper=2> obs_family;   // 1 = NB2, 2 = Poisson

  // priors (as data so they can change without recompiling)
  vector[P] prior_beta_mean;
  vector<lower=0>[P] prior_beta_sd;
  real<lower=0> prior_sigma_re_sd;    // half-normal sd for RE sds
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

  array[G, T] int<lower=0> row_obs_sum;  // observed total per group/ref date
}
transformed data {
  // Build per-group cell lists once (indices into the flat cell arrays).
  array[G] int n_g = rep_array(0, G);
  for (i in 1:n_obs) {
    n_g[cell_g[i]] += 1;
  }
}
parameters {
  vector[P] beta_fixed;
  vector<lower=0>[q_re] sigma_re;     // RE sds (only used if use_re)
  real<lower=0> gp_alpha;
  real<lower=0> gp_rho;
  real<lower=0> hsgp_alpha;
  real<lower=0> hsgp_rho;
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
  // Fixed-effect mean per (group, ref date): mu[g, t].
  matrix[G, T] mu_ref;
  {
    vector[G * T] mu_flat = X_fixed * beta_fixed;
    for (g in 1:G) {
      for (t in 1:T) {
        mu_ref[g, t] = mu_flat[(g - 1) * T + t];
      }
    }
  }
  // Per-cell mean folded for the likelihood: fixed-effect mean + delay.
  vector[n_obs] cell_mean;
  for (i in 1:n_obs) {
    cell_mean[i] = mu_ref[cell_g[i], cell_t[i]] + log_p_delay[cell_d[i] + 1];
  }
}
model {
  // priors
  beta_fixed ~ normal(prior_beta_mean, prior_beta_sd);
  if (q_re > 0) {
    sigma_re ~ normal(0, prior_sigma_re_sd);  // half-normal via <lower=0>
  }
  gp_alpha ~ normal(0, prior_gp_alpha_sd);
  gp_rho ~ inv_gamma(prior_gp_rho_a, prior_gp_rho_b);
  hsgp_alpha ~ normal(0, prior_hsgp_alpha_sd);
  hsgp_rho ~ inv_gamma(prior_hsgp_rho_a, prior_hsgp_rho_b);
  delay_mu ~ normal(prior_delay_mu_mean, prior_delay_mu_sd);
  delay_sigma ~ normal(0, prior_delay_sigma_sd);
  phi ~ normal(0, prior_phi_sd);

  // Marginalise each group's latent field independently and sum targets.
  {
    int pos = 1;
    for (g in 1:G) {
      int ng = n_g[g];
      array[ng] int yg = segment(y, pos, ng);
      array[ng] int refg = segment(cell_t, pos, ng);
      vector[ng] meang = segment(cell_mean, pos, ng);
      target += laplace_marginal(
        ll_fn, (yg, refg, meang, phi, obs_family), 1,
        cov_fn, (
          T, use_re, Z, sigma_re, use_gp, ref_x, gp_alpha, gp_rho,
          gp_kernel, use_hsgp, PHI, hsgp_lambda, hsgp_alpha, hsgp_rho,
          jitter
        )
      );
      pos += ng;
    }
  }
}
generated quantities {
  // Draw each group's latent field, then reconstruct per-group, per-ref-date
  // nowcasts (observed total + predicted unobserved cells with delay > T-t).
  array[G, T] int nowcast;
  {
    int pos = 1;
    for (g in 1:G) {
      int ng = n_g[g];
      array[ng] int yg = segment(y, pos, ng);
      array[ng] int refg = segment(cell_t, pos, ng);
      vector[ng] meang = segment(cell_mean, pos, ng);
      vector[T] theta_g = laplace_latent_rng(
        ll_fn, (yg, refg, meang, phi, obs_family), 1,
        cov_fn, (
          T, use_re, Z, sigma_re, use_gp, ref_x, gp_alpha, gp_rho,
          gp_kernel, use_hsgp, PHI, hsgp_lambda, hsgp_alpha, hsgp_rho,
          jitter
        )
      );
      for (t in 1:T) {
        real eta_base = mu_ref[g, t] + theta_g[t];
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
      pos += ng;
    }
  }
}

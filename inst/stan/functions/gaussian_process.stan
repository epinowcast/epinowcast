/**
 * Hilbert-space reduced-rank (spectral) approximate Gaussian process.
 *
 * Adapted from EpiNow2
 * (https://github.com/epiforecasts/EpiNow2,
 * inst/stan/functions/gaussian_process.stan, MIT licensed, copyright
 * EpiForecasts). Lightly modified for epinowcast: array syntax,
 * naming, and an `apply_gp_term()` wrapper that matches the
 * `apply_arima_residual()` per-observation gather used elsewhere in
 * this package.
 *
 * The approximation follows:
 *  - Riutort-Mayol et al. (2023), doi:10.1007/s11222-022-10167-2
 *  - https://avehtari.github.io/casestudies/Motorcycle/motorcycle_gpcourse.html
 *
 * A latent series f over T time points is approximated as
 * `f = PHI * (sqrt(S(rho, alpha)) .* eta)`, where PHI is a fixed
 * (data) matrix of basis functions, S is the spectral density of the
 * chosen kernel evaluated at the basis eigenvalues, and `eta` are
 * unit-normal spectral coefficients. The per-observation contribution
 * is gathered from the (T x G) latent matrix with a flat column-major
 * index, mirroring the ARIMA path.
 */

/**
 * Spectral density for the squared exponential kernel.
 */
vector diagSPD_EQ(real alpha, real rho, real L, int M) {
  vector[M] indices = linspaced_vector(M, 1, M);
  real factor = alpha * sqrt(sqrt(2 * pi()) * rho);
  real exponent = -0.25 * (rho * pi() / 2 / L)^2;
  return factor * exp(exponent * square(indices));
}

/**
 * Squared spectral indices shared by the Matern kernels.
 */
vector matern_indices(int M, real L) {
  vector[M] indices = linspaced_vector(M, 1, M);
  return square(pi() / (2 * L) * indices);
}

/**
 * Spectral density for the 1/2 Matern (Ornstein-Uhlenbeck) kernel.
 */
vector diagSPD_Matern12(real alpha, real rho, real L, int M) {
  vector[M] denom = 1 / rho + rho * matern_indices(M, L);
  return alpha * sqrt(2 ./ denom);
}

/**
 * Spectral density for the 3/2 Matern kernel.
 */
vector diagSPD_Matern32(real alpha, real rho, real L, int M) {
  real factor = 2 * alpha * (sqrt(3) / rho)^1.5;
  vector[M] denom = 3 / square(rho) + matern_indices(M, L);
  return factor ./ denom;
}

/**
 * Spectral density for the 5/2 Matern kernel.
 */
vector diagSPD_Matern52(real alpha, real rho, real L, int M) {
  real factor = 16 * pow(sqrt(5) / rho, 5);
  vector[M] denom = 3 * pow(5 / square(rho) + matern_indices(M, L), 3);
  return alpha * sqrt(factor ./ denom);
}

/**
 * Spectral density for the periodic kernel.
 */
vector diagSPD_Periodic(real alpha, real rho, int M) {
  real a = inv_square(rho);
  vector[M] indices = linspaced_vector(M, 1, M);
  vector[M] q = exp(
    log(alpha) + 0.5 *
      (log(2) - a + to_vector(log_modified_bessel_first_kind(indices, a)))
  );
  return append_row(q, q);
}

/**
 * Update a Gaussian process using the spectral densities.
 *
 * @param PHI   Basis function matrix (T x M, or T x 2M for periodic).
 * @param M     Number of basis functions.
 * @param L     Boundary factor.
 * @param alpha Magnitude (marginal standard deviation).
 * @param rho   Length scale.
 * @param eta   Spectral coefficients (M, or 2M for periodic).
 * @param type  0 = squared exponential, 1 = periodic, 2 = Matern.
 * @param nu    Matern smoothness; one of 0.5, 1.5, 2.5.
 * @return The latent process values (length = rows of PHI).
 */
vector update_gp(matrix PHI, int M, real L, real alpha,
                 real rho, vector eta, int type, real nu) {
  vector[type == 1 ? 2 * M : M] diagSPD;
  if (type == 0) {
    diagSPD = diagSPD_EQ(alpha, rho, L, M);
  } else if (type == 1) {
    diagSPD = diagSPD_Periodic(alpha, rho, M);
  } else if (type == 2) {
    if (nu == 0.5) {
      diagSPD = diagSPD_Matern12(alpha, rho, L, M);
    } else if (nu == 1.5) {
      diagSPD = diagSPD_Matern32(alpha, rho, L, M);
    } else if (nu == 2.5) {
      diagSPD = diagSPD_Matern52(alpha, rho, L, M);
    } else {
      reject("nu must be one of 0.5, 1.5, or 2.5; found nu=", nu);
    }
  }
  return PHI * (diagSPD .* eta);
}

/**
 * Add an approximate Gaussian process latent term to a per-observation
 * predictor.
 *
 * Encapsulates the spectral update, per-group evaluation, and
 * per-observation gather so module call sites are a single line. When
 * `present` is 0 the input is returned unchanged. Each group shares the
 * length scale `rho` and magnitude `alpha`; per-group spectral
 * coefficients are stacked column-wise in `eta`.
 *
 * @param base      Predictor to which the latent process is added.
 * @param present   0 = inert, 1 = active.
 * @param T         Number of time points in the latent series.
 * @param G         Number of groups.
 * @param M         Number of basis functions.
 * @param L         Boundary factor.
 * @param type      Kernel type (0 SE, 1 periodic, 2 Matern).
 * @param nu        Matern smoothness.
 * @param PHI       Basis matrix (T x M, or T x 2M for periodic).
 * @param eta       Spectral coefficients ((2M or M) x G matrix; empty
 *                  when not present).
 * @param rho       Length scale (length-1 array, empty when inert).
 * @param alpha     Magnitude (length-1 array, empty when inert).
 * @param flat_idx  Per-observation column-major index into the
 *                  (T x G) latent matrix.
 * @return base + gathered Gaussian process contribution.
 */
vector apply_gp_term(vector base, int present, int T, int G,
                     int M, real L, int type, real nu,
                     matrix PHI, matrix eta,
                     array[] real rho, array[] real alpha,
                     array[] int flat_idx) {
  if (!present) return base;
  matrix[T, G] gp_eps;
  for (g in 1:G) {
    gp_eps[, g] = update_gp(
      PHI, M, L, alpha[1], rho[1], eta[, g], type, nu
    );
  }
  return base + to_vector(gp_eps)[flat_idx];
}

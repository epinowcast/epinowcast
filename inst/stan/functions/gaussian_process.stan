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
 * predictor, with optional integer-order differencing.
 *
 * Encapsulates the spectral update, per-group evaluation, optional
 * integration, and per-observation gather so module call sites are a
 * single line. When `present` is 0 the input is returned unchanged.
 * Each group shares the length scale `rho` and magnitude `alpha`;
 * per-group spectral coefficients are stacked column-wise in `eta`.
 *
 * The differencing order `d` integrates each group's realisation `d`
 * times before it enters the predictor:
 *
 *   - `d = 0`: stationary deviations of length `T` (the basis matrix is
 *     `T x M`). This is the original behaviour.
 *   - `d >= 1`: the basis matrix has `T - d` rows, so the spectral
 *     update yields `T - d` free values. These fill positions
 *     `(d + 1):T` of a length-`T` vector whose first `d` entries are
 *     zero; applying `cumulative_sum()` `d` times then integrates the
 *     series. Because the leading `d` entries start at zero, they stay
 *     zero through every integration pass, anchoring the first `d`
 *     values of the realisation to zero. This leaves the free level
 *     (for `d = 1`) and additionally the free slope (for `d >= 2`) to
 *     the module's fixed effects rather than the GP, which is the
 *     identifiability fix. `d = 1` matches EpiNow2's non-stationary
 *     reproduction-number GP (`gp[2:(gp_n + 1)] = noise; cumulative_sum`).
 *
 * @param base      Predictor to which the latent process is added.
 * @param present   0 = inert, 1 = active.
 * @param T         Number of time points in the integrated series.
 * @param G         Number of groups.
 * @param M         Number of basis functions.
 * @param L         Boundary factor.
 * @param type      Kernel type (0 SE, 1 periodic, 2 Matern).
 * @param nu        Matern smoothness.
 * @param d         Differencing (integration) order, `d >= 0`.
 * @param PHI       Basis matrix ((T - d) x M, or (T - d) x 2M periodic).
 * @param eta       Spectral coefficients ((2M or M) x G matrix; empty
 *                  when not present).
 * @param rho       Length scale (length-1 array, empty when inert).
 * @param alpha     Magnitude (length-1 array, empty when inert).
 * @param flat_idx  Per-observation column-major index into the
 *                  (T x G) latent matrix.
 * @return base + gathered Gaussian process contribution.
 */
/**
 * Build the (T x G) integrated Gaussian process latent matrix.
 *
 * For `d = 0` each column is the stationary GP. For `d >= 1` the first d
 * entries are anchored to zero, the free values fill (d + 1):T, and the
 * column is integrated d times (the leading zeros survive each
 * cumulative_sum pass).
 */
matrix gp_latent_matrix(int T, int G, int M, real L, int type, real nu,
                        int d, matrix PHI, matrix eta,
                        array[] real rho, array[] real alpha) {
  matrix[T, G] gp_eps;
  for (g in 1:G) {
    vector[rows(PHI)] f = update_gp(
      PHI, M, L, alpha[1], rho[1], eta[, g], type, nu
    );
    if (d == 0) {
      gp_eps[, g] = f;
    } else {
      vector[T] col = rep_vector(0.0, T);
      col[(d + 1):T] = f;
      for (i in 1:d) {
        col = cumulative_sum(col);
      }
      gp_eps[, g] = col;
    }
  }
  return gp_eps;
}

/**
 * Grand mean (over time and groups) of the integrated GP latent.
 *
 * Like `arima_latent_mean_offset`, this is the single level direction that
 * competes with the shared intercept when the GP is integrated (`d >= 1`).
 * Subtracting it from the sampled intercept recovers the original-scale
 * intercept the prior applies to (an additive, unit-Jacobian shift). Each
 * group keeps its own level relative to the grand mean, so a grouped GP is
 * exact for any number of groups. Returns 0 unless present, centring is on,
 * and `d >= 1`.
 */
real gp_latent_mean_offset(int present, int centre, int T, int G,
                           int M, real L, int type, real nu, int d,
                           matrix PHI, matrix eta,
                           array[] real rho, array[] real alpha) {
  if (!present || !centre || d < 1) return 0.0;
  matrix[T, G] gp_eps = gp_latent_matrix(
    T, G, M, L, type, nu, d, PHI, eta, rho, alpha
  );
  return mean(to_vector(gp_eps));
}

vector apply_gp_term(vector base, int present, int centre, int T, int G,
                     int M, real L, int type, real nu, int d,
                     matrix PHI, matrix eta,
                     array[] real rho, array[] real alpha,
                     array[] int flat_idx) {
  if (!present) return base;
  matrix[T, G] gp_eps = gp_latent_matrix(
    T, G, M, L, type, nu, d, PHI, eta, rho, alpha
  );
  // Centre the integrated GP (d >= 1) on its grand mean so the intercept
  // owns the level (mirrors the ARIMA residual). Only the shared grand
  // mean is removed, so a grouped GP keeps each group's own level.
  if (centre && d >= 1) {
    gp_eps = gp_eps - mean(to_vector(gp_eps));
  }
  return base + to_vector(gp_eps)[flat_idx];
}

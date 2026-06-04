/**
 * ARIMA(p, d, q) kernel for regression-style residual modelling.
 *
 * The full kernel maps a vector of unit-normal shocks `z` to a series
 * `eps = K(phi, theta, d) * z` where the linear predictor receives
 * `eps[time_idx, group_idx]` for each observation. The kernel factorises
 * as `D^d * T(psi)`, where:
 *
 *   - `psi` is the truncated impulse response of the ARMA(p, q) process
 *     with autoregressive coefficients `phi` and moving-average
 *     coefficients `theta`. It satisfies the recursion
 *
 *         psi[1] = 1,
 *         psi[k] = sum_{j=1..min(p,k-1)} phi[j] * psi[k-j]
 *                + (k-1 <= q ? theta[k-1] : 0).
 *
 *   - `T(psi)` is the lower-triangular Toeplitz matrix with first column
 *     `psi`. Multiplying it by a shock vector applies the ARMA filter.
 *
 *   - `D` is the lower-triangular matrix of ones (cumulative-sum
 *     operator). `D^d` integrates `d` times. `D^0` is the identity.
 *
 * Stationarity of the AR(p) component is enforced via the partial
 * autocorrelation parameterisation of Barndorff-Nielsen and Schou
 * (1973): given partial autocorrelations `r` in (-1, 1), the
 * Durbin-Levinson recursion produces stationary `phi`.
 */

/**
 * Convert partial autocorrelations to AR coefficients.
 *
 * Implements the Durbin-Levinson recursion in its forward direction.
 * Inputs `r[k] in (-1, 1)` for k = 1..p map bijectively to `phi`
 * giving a stationary AR(p) process.
 */
vector pacf_to_phi(vector r) {
  int p = num_elements(r);
  if (p == 0) return r;
  vector[p] phi = r;
  vector[p] work = r;
  for (k in 2:p) {
    for (j in 1:(k - 1)) {
      work[j] = phi[j] - r[k] * phi[k - j];
    }
    for (j in 1:(k - 1)) {
      phi[j] = work[j];
    }
    phi[k] = r[k];
  }
  return phi;
}

/**
 * Truncated impulse response of the ARMA(p, q) process up to lag T-1.
 *
 * Returns a length-T vector psi with psi[1] = 1 and the remaining
 * entries given by the standard ARMA recursion.
 */
vector arma_impulse(vector phi, vector theta, int T) {
  int p = num_elements(phi);
  int q = num_elements(theta);
  vector[T] psi = rep_vector(0.0, T);
  psi[1] = 1.0;
  for (t in 2:T) {
    real s = 0.0;
    int kmax = min(p, t - 1);
    for (k in 1:kmax) s += phi[k] * psi[t - k];
    if (t - 1 <= q) s += theta[t - 1];
    psi[t] = s;
  }
  return psi;
}

/**
 * Build the lower-triangular Toeplitz matrix from a length-T impulse
 * response.
 *
 * Uses column-wise vector-slice assignment (one assignment per
 * column) rather than scalar element loops, so the inner work runs
 * through Stan's vectorised primitives.
 */
matrix lower_toeplitz(vector psi) {
  int T = num_elements(psi);
  matrix[T, T] K = rep_matrix(0.0, T, T);
  for (s in 1:T) {
    K[s:T, s] = head(psi, T - s + 1);
  }
  return K;
}

/**
 * Build the d-fold cumulative-sum operator (lower triangular).
 *
 * Provided as a utility; the ARIMA kernel path no longer materialises
 * this matrix per iteration. `arima_kernel_matrix()` instead applies
 * `cumulative_sum()` to the columns of the ARMA Toeplitz, avoiding
 * both the D^d build and the dense T x T multiply that follows it.
 */
matrix cumulative_op(int T, int d) {
  if (d == 0) return diag_matrix(rep_vector(1.0, T));
  matrix[T, T] D1 = rep_matrix(0.0, T, T);
  for (s in 1:T) {
    D1[s:T, s] = rep_vector(1.0, T - s + 1);
  }
  matrix[T, T] D = D1;
  for (i in 2:d) D = D * D1;
  return D;
}

/**
 * Build the full ARIMA(p, d, q) kernel.
 *
 * Returns the T x T lower-triangular matrix that maps unit-normal
 * shocks to the latent ARIMA series. The d-fold integration is
 * applied as `d` repeated `cumulative_sum()` calls on the columns of
 * the ARMA Toeplitz, which is mathematically identical to D^d * T(psi)
 * but skips both the construction of the D^d matrix and the dense
 * matrix-matrix multiply that follows it. For `d = 0` no integration
 * pass is taken.
 */
matrix arima_kernel_matrix(vector phi, vector theta, int d, int T) {
  vector[T] psi = arma_impulse(phi, theta, T);
  matrix[T, T] K = lower_toeplitz(psi);
  for (i in 1:d) {
    for (col in 1:T) {
      K[, col] = cumulative_sum(K[, col]);
    }
  }
  return K;
}

/**
 * Apply the ARIMA(p, d, q) kernel to a (T, G) matrix of shocks.
 *
 * Each column is filtered independently through the same kernel. For
 * per-group `phi` / `theta` (independent type), call this once per
 * group with the appropriate column.
 *
 * When p = q = 0 (pure differencing, ARIMA(0, d, 0)) the operation
 * reduces to repeated cumulative sums per column, which avoids
 * materialising the T x T kernel matrix and saves O(T^2) work per
 * iteration. This makes ARIMA(0, 1, 0) — the random-walk equivalent —
 * cost O(T G) per evaluation instead of O(T^2 G).
 */
matrix arima_filter(matrix Z, vector phi, vector theta, int d) {
  int T = rows(Z);
  int G = cols(Z);
  if (num_elements(phi) == 0 && num_elements(theta) == 0) {
    if (d == 0) return Z;
    matrix[T, G] result = Z;
    for (i in 1:d) {
      for (g in 1:G) {
        result[, g] = cumulative_sum(result[, g]);
      }
    }
    return result;
  }
  return arima_kernel_matrix(phi, theta, d, T) * Z;
}

/**
 * Add an ARIMA(p, d, q) latent residual to a per-observation predictor.
 *
 * Encapsulates the kernel build, scaling, and per-observation lookup
 * so module call sites are a single line. When `present` is 0 the
 * input is returned unchanged.
 *
 * @param base       Predictor to which the latent is added.
 * @param n_obs      Length of `base` and of the lookup vectors.
 * @param present    0 = inert, 1 = active.
 * @param centre     1 = mean-centre integrated (d >= 1) residuals so the
 *                   intercept owns the level; 0 = leave the raw series.
 * @param T          Number of time points in the latent series.
 * @param G          Number of groups.
 * @param p, d, q    ARIMA orders.
 * @param z          Unit-normal shocks (T x G).
 * @param pacf       Partial autocorrelations on (-1, 1), length p.
 * @param theta      MA coefficients, length q.
 * @param sigma      Length-1 array (empty when not present) holding the
 *                   latent standard deviation.
 * @param time_idx   Per-observation time index in 1..T.
 * @param group_idx  Per-observation group index in 1..G.
 *
 * @return A new vector equal to `base + sigma * (D^d * T(psi)) * z`
 *         looked up at the per-observation indices.
 */
/**
 * Average (over groups) of the per-group mean of the integrated latent.
 *
 * When the integrated residual is mean-centred (see `apply_arima_residual`)
 * the level it carried is removed from the predictor. To keep the prior on
 * the original-scale intercept (the EpiNow2 device: prior on the recovered
 * level via a unit-Jacobian shift), this offset is subtracted from the
 * sampled intercept so the recovered intercept absorbs the level. The
 * average across groups is used because the intercept is shared across
 * groups; for a single group this makes the centring an exact
 * reparameterisation, for several groups it preserves the shared level and
 * only the per-group deviations from the mean are re-expressed.
 *
 * Returns 0 unless the term is present, centring is on, and d >= 1.
 */
real arima_latent_mean_offset(int present, int centre, int T, int G,
                              int p, int d, int q,
                              matrix z, vector pacf, vector theta,
                              array[] real sigma) {
  if (!present || !centre || d < 1) return 0.0;
  vector[p] phi = pacf_to_phi(pacf);
  matrix[T, G] eps = sigma[1] * arima_filter(z, phi, theta, d);
  real m = 0.0;
  for (gg in 1:G) m += mean(eps[, gg]);
  return m / G;
}

vector apply_arima_residual(vector base, int n_obs,
                            int present, int centre, int T, int G,
                            int p, int d, int q,
                            matrix z, vector pacf, vector theta,
                            array[] real sigma,
                            array[] int flat_idx) {
  if (!present) return base;
  vector[p] phi = pacf_to_phi(pacf);
  matrix[T, G] eps = sigma[1] * arima_filter(z, phi, theta, d);
  // Integration (d >= 1) gives the residual a free overall level: the
  // first shock propagates through the cumulative sum and shifts the
  // whole path, so the residual level trades off against the intercept
  // (a ridge in the joint posterior that slows HMC). When an intercept
  // is present to carry the level, mean-centre each group's series so
  // the residual becomes a pure mean-zero deviation. This mirrors brms's
  // design-matrix centring and EpiNow2's `gp -= mean(gp)`.
  if (centre && d >= 1) {
    for (gg in 1:G) {
      eps[, gg] = eps[, gg] - mean(eps[, gg]);
    }
  }
  // Vectorised gather: flat_idx is precomputed in transformed data
  // as (group_idx - 1) * T + time_idx, so to_vector(eps) (column-
  // major flatten) [flat_idx] returns the per-observation residuals
  // in one shot, replacing the previous element-by-element loop.
  return base + to_vector(eps)[flat_idx];
}

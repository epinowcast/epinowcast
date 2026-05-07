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
 */
matrix lower_toeplitz(vector psi) {
  int T = num_elements(psi);
  matrix[T, T] K = rep_matrix(0.0, T, T);
  for (t in 1:T) {
    for (s in 1:t) {
      K[t, s] = psi[t - s + 1];
    }
  }
  return K;
}

/**
 * Build the d-fold cumulative-sum operator (lower triangular).
 *
 * `cumulative_op(T, 0)` is the identity; `cumulative_op(T, 1)` is the
 * matrix of ones on and below the diagonal; `cumulative_op(T, d)` for
 * d >= 1 integrates d times.
 */
matrix cumulative_op(int T, int d) {
  if (d == 0) return diag_matrix(rep_vector(1.0, T));
  matrix[T, T] D1 = rep_matrix(0.0, T, T);
  for (t in 1:T) for (s in 1:t) D1[t, s] = 1.0;
  matrix[T, T] D = D1;
  for (i in 2:d) D = D * D1;
  return D;
}

/**
 * Build the full ARIMA(p, d, q) kernel.
 *
 * Returns the T x T lower-triangular matrix that maps unit-normal
 * shocks to the latent ARIMA series.
 */
matrix arima_kernel_matrix(vector phi, vector theta, int d, int T) {
  vector[T] psi = arma_impulse(phi, theta, T);
  matrix[T, T] arma_K = lower_toeplitz(psi);
  if (d == 0) return arma_K;
  return cumulative_op(T, d) * arma_K;
}

/**
 * Apply the ARIMA(p, d, q) kernel to a (T, G) matrix of shocks.
 *
 * Each column is filtered independently through the same kernel. For
 * per-group `phi` / `theta` (independent type), call this once per
 * group with the appropriate column.
 */
matrix arima_filter(matrix Z, vector phi, vector theta, int d) {
  int T = rows(Z);
  return arima_kernel_matrix(phi, theta, d, T) * Z;
}

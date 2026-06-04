/**
 * Build a latent delay convolution matrix from a PMF
 *
 * Mirrors the `convolution_matrix()` R helper (with `include_partial = FALSE`)
 * so that an uncertain latent reporting delay PMF, rebuilt for each posterior
 * sample, can be funnelled through the same sparse matrix-vector convolution
 * path used for fixed PMFs. Column `s` places the forward PMF starting at row
 * `s`, i.e. `conv[s + d, s] = pmf[d + 1]` for delay `d`. The first `rd_n - 1`
 * rows hold partially complete convolutions and are dropped downstream, so
 * they are left as zero here (matching `include_partial = FALSE`).
 *
 * @param pmf Latent reporting delay PMF (forward order, delays 0:(rd_n - 1)).
 *
 * @param rd_n Length of the reporting delay PMF.
 *
 * @param ft Number of latent time points (`t + rd_n - 1`).
 *
 * @return An `ft` by `ft` banded convolution matrix.
 */
matrix convolution_matrix(vector pmf, int rd_n, int ft) {
  matrix[ft, ft] conv = rep_matrix(0, ft, ft);
  for (s in 1:ft) {
    int l = min(ft - s + 1, rd_n);
    conv[s:(s + l - 1), s] = pmf[1:l];
  }
  // Drop partially complete convolutions (include_partial = FALSE).
  if (rd_n > 1) {
    conv[1:(rd_n - 1), ] = rep_matrix(0, rd_n - 1, ft);
  }
  return conv;
}

/**
 * Compute log of expected observations from latent values
 *
 * This function calculates the expected observations in log scale based on
 * latent expected values, weighting factors, and observational proportions.
 * The weighting factors are derived from a sparse matrix, which is
 * constructed using the `csr_extract` and `convolution_matrix`
 * R/Stan functions in `epinowcast`. The same path is used for both fixed
 * PMFs (where the sparse components are precomputed in transformed data) and
 * uncertain PMFs (where they are rebuilt per posterior sample).
 *
 * @param exp_llatent Array of vectors of log latent expected values.
 *
 * @param rd_n Length of the reporting delay (1 for immediate reporting).
 *
 * @param w Vector of weighting factors derived from a sparse matrix.
 *
 * @param v, u Arrays for sparse matrix representation, as obtained from
 * `csr_extract`.
 *
 * @param t Number of time periods.
 *
 * @param g Number of groups.
 *
 * @param latent_obs_prop Vector of observational proportions for latent values.
 *
 * @return An array of vectors containing log-transformed expected observed
 * values for each group and time period.
 *
 * @note The function performs different operations based on the value of
 * `rd_n`:
 *       1. If `rd_n` is 1 (immediate reporting):
 *          a. Directly adds the log latent values, log of weights, and
 *             observational proportions for each group.
 *       2. If `rd_n` > 1 (delayed reporting):
 *          a. Uses a convolution matrix constructed using `convolution_matrix`
 *             or otherwise, representing reporting delays.
 *          b. Prior to being used as an input this is converted to a sparse
 *             matrix format using `csr_extract`.
 *          c. Applies the sparse matrix multiplication to the latent values.
 *          d. Converts the resulting values back to the log scale and adds the
 *             observational proportions for each group.
 *
 * These steps account for different reporting delays and the distribution
 * of observations over time.
 *
 * @see `csr_matrix` and `convolution_matrix` Stan functions and epinowcast R
 * functions for details on sparse matrix construction and convolution matrix
 * generation.
 */
array[] vector log_expected_obs_from_latent(
  array[] vector exp_llatent, int rd_n, vector w, array[] int v,
  array[] int u, int t,
  int g, vector latent_obs_prop
) {
  array[g] vector[t] exp_lobs;
  if (rd_n == 1) {
    for (k in 1:g) {
      exp_lobs[k] = exp_llatent[k] + log(w) +
        segment(latent_obs_prop, (k-1) * t + 1, t);
    }
  } else {
    int ft = t + rd_n - 1;
    // Declare once outside loop to avoid repeated allocation
    vector[ft] exp_obs;
    for (k in 1:g) {
      exp_obs = csr_matrix_times_vector(
        ft, ft, w, v, u, exp(exp_llatent[k])
      );
      exp_lobs[k] = log(exp_obs[rd_n:ft]) +
        segment(latent_obs_prop, (k-1) * t + 1, t);
    }
  }
  return(exp_lobs);
}

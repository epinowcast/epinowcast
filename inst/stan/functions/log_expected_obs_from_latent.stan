/**
 * Compute log of expected observations from latent values
 * 
 * This function calculates the expected observations in log scale based on
 * latent expected values, weighting factors, and observational proportions.
 * The weighting factors are derived from a sparse matrix, which is
 * constructed using the `extract_sparse_matrix` and `convolution_matrix`
 * R functions in `epinowcast`.
 * 
 * @param exp_llatent Array of vectors of log latent expected values.
 *
 * @param rd_n Length of the reporting delay (1 for immediate reporting).
 *
 * @param w Vector of weighting factors derived from a sparse matrix.
 *
 * @param v, u Arrays for sparse matrix representation, as obtained from 
 * `extract_sparse_matrix`.
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
               or otherwise, representing reporting delays.
 *          b. Prior to being used as an input this is converted to a sparse
 *             matrix format using `extract_sparse_matrix`.
 *          c. Applies the sparse matrix multiplication to the latent values in
               a sparse matrix multiplication.
 *          d. Converts the resulting values back to the log scale and adds the
 *             observational proportions for each group.
 * 
 * These steps account for different reporting delays and the distribution
 * of observations over time.
 * 
 * @seealso `extract_sparse_matrix` and `convolution_matrix` epinowcast R
 * functions for details on sparse matrix construction and convolution matrix
 * generation.
 */
array[] vector log_expected_obs_from_latent(
  array[] vector exp_llatent, int rd_n, vector w, array[] int v,
  array[] int u, int t,
  int g, vector latent_obs_prop
) {
  array[g] vector[t] exp_lobs;
  int ft = t + rd_n - 1;
  for (k in 1:g) {
    if (rd_n == 1) {
      exp_lobs[k] = exp_llatent[k] + log(w) +
        segment(latent_obs_prop, (k-1) * t + 1, t);
    } else {
      vector[ft] exp_obs = csr_matrix_times_vector(
        ft, ft, w, v, u, exp(exp_llatent[k])
      );
      exp_lobs[k] = log(exp_obs[rd_n:ft]) +
        segment(latent_obs_prop, (k-1) * t + 1, t);
    }
    
  }
  return(exp_lobs);
}

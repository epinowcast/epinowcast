/**
 * Compute log of expected observations from latent values
 * 
 * This function calculates the expected observations in log scale based on
 * latent expected values, weighting factors, and observational proportions.
 * The weighting factors are derived from a sparse matrix, which is
 * constructed using the `csr_extract` and `convolution_matrix`
 * R functions in `epinowcast`.
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
               or otherwise, representing reporting delays.
 *          b. Prior to being used as an input this is converted to a sparse
 *             matrix format using `csr_extract`.
 *          c. Applies the sparse matrix multiplication to the latent values in
               a sparse matrix multiplication.
 *          d. Converts the resulting values back to the log scale and adds the
 *             observational proportions for each group.
 * 
 * These steps account for different reporting delays and the distribution
 * of observations over time.
 * 
 * @see `csr_matrix` and `convolution_matrix` stan function and epinowcast R
 * function for details on sparse matrix construction and convolution matrix
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

/**
 * Compute log expected observations from latent values using an in-model PMF
 *
 * Variant of `log_expected_obs_from_latent` used when the latent reporting
 * delay is uncertain and its PMF is rebuilt for each posterior sample (and so
 * cannot be precomputed into a sparse convolution matrix in transformed data).
 * The convolution is performed directly using the supplied PMF. The PMF maps
 * delays 0 to (rd_n - 1), so observation at reference time s (1-indexed over
 * the latent series of length ft = t + rd_n - 1) is the dot product of the
 * preceding rd_n latent values with the reversed PMF.
 *
 * @param exp_llatent Array of vectors of log latent expected values (length
 * ft per group).
 *
 * @param pmf Latent reporting delay PMF (forward order, delays 0:(rd_n-1)).
 *
 * @param rd_n Length of the reporting delay PMF.
 *
 * @param t Number of modelled reference time points.
 *
 * @param g Number of groups.
 *
 * @param latent_obs_prop Vector of log latent-to-obs proportions.
 *
 * @return An array of vectors of log expected observations per group.
 */
array[] vector log_expected_obs_from_latent_pmf(
  array[] vector exp_llatent, vector pmf, int rd_n, int t, int g,
  vector latent_obs_prop
) {
  array[g] vector[t] exp_lobs;
  int ft = t + rd_n - 1;
  vector[rd_n] rpmf = reverse(pmf);
  for (k in 1:g) {
    vector[ft] latent = exp(exp_llatent[k]);
    vector[t] obs;
    for (s in 1:t) {
      // reference time s corresponds to latent index s + rd_n - 1; convolve
      // the preceding rd_n latent values with the reversed delay PMF.
      obs[s] = dot_product(segment(latent, s, rd_n), rpmf);
    }
    exp_lobs[k] = log(obs) + segment(latent_obs_prop, (k-1) * t + 1, t);
  }
  return(exp_lobs);
}

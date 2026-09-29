/**
 * Compute log of expected observations from latent values
 *
 * This function calculates the expected observations in log scale based on
 * latent expected values, a latent-to-observation reporting delay PMF, and
 * observational proportions.
 *
 * @param exp_llatent Array of vectors of log latent expected values.
 *
 * @param rd_n Length of the reporting delay (1 for immediate reporting).
 *
 * @param lrd_rev Reversed PMF of the latent-to-obs reporting delay, length
 * rd_n. Convolved with each group's latent expected values via
 * `convolve_with_rev_pmf()` (see that function for the maths, and its C++
 * implementation for the reverse-mode adjoint used when `rd_n > 1`).
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
 *          a. Directly adds the log latent values, log of the (scalar)
 *             delay weight, and observational proportions for each group.
 *       2. If `rd_n` > 1 (delayed reporting):
 *          a. Convolves each group's exponentiated latent values with the
 *             reversed delay PMF `lrd_rev` via `convolve_with_rev_pmf()`.
 *          b. Drops the first `rd_n - 1` (incomplete-window) outputs,
 *             converts the remainder back to the log scale and adds the
 *             observational proportions for each group.
 *
 * These steps account for different reporting delays and the distribution
 * of observations over time.
 *
 * @see `convolve_with_rev_pmf` for the convolution and its adjoint.
 */
array[] vector log_expected_obs_from_latent(
  array[] vector exp_llatent, int rd_n, vector lrd_rev, int t,
  int g, vector latent_obs_prop
) {
  array[g] vector[t] exp_lobs;
  if (rd_n == 1) {
    for (k in 1:g) {
      exp_lobs[k] = exp_llatent[k] + log(lrd_rev[1]) +
        segment(latent_obs_prop, (k-1) * t + 1, t);
    }
  } else {
    int ft = t + rd_n - 1;
    vector[ft] exp_obs;
    for (k in 1:g) {
      exp_obs = convolve_with_rev_pmf(exp(exp_llatent[k]), lrd_rev, ft);
      exp_lobs[k] = log(exp_obs[rd_n:ft]) +
        segment(latent_obs_prop, (k-1) * t + 1, t);
    }
  }
  return(exp_lobs);
}

/**
 * Compute log PDF for a zero-truncated normal distribution
 * 
 * Calculates the log probability density for a vector of observations assumed
 * to follow a zero-truncated normal distribution with specified mean and
 * standard deviation. This function is useful in contexts where the normal
 * distribution is truncated to exclude values below zero.
 * 
 * @param y Vector of observations.
 *
 * @param mu Mean of the zero-truncated normal distribution.
 *
 * @param sigma Standard deviation of the zero-truncated normal distribution.
 * 
 * @return The log probability density of the observations given the
 * zero-truncated normal distribution.
 * 
 * @note The function performs the following calculation:
 *  1. Computes the normal log PDF of `y` given `mu` and `sigma`.
 *  2. Subtracts the log cumulative complementary distribution function (LCCDF) 
 *     of zero under the normal distribution to account for truncation.
 *     The term `g * normal_lccdf(0 | mu, sigma)` adjusts for the probability 
 *     mass excluded by truncation, where `g` is the number of elements in `y`.
 * 
 * @seealso This function is used in `effect_priors_lp` for applying a
 * zero-truncated normal prior to the standard deviations of random effects in
 * a regression context.
 */
real zero_truncated_normal_lpdf(vector y, real mu, real sigma) {
  real tar;
  real g = num_elements(y);
  tar = normal_lpdf(y | mu, sigma)  -  g * normal_lccdf(0 | mu, sigma);
  return(tar);
}

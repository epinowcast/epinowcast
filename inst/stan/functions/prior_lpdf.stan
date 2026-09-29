/**
 * Log density of a prior selected by a distribution id
 *
 * Each model prior is passed as data as a location and scale together with
 * an integer id selecting the distribution family, so that the prior family
 * can be chosen in R (see `enw_priors_as_data_list()`). The location and
 * scale are the natural parameters of the family: the mean and standard
 * deviation of a normal, the log mean and log standard deviation of a
 * log-normal, the shape and rate of a gamma, and the rate (with the scale
 * ignored) of an exponential. Parameters with a lower bound of zero turn a
 * normal prior into a half-normal; the truncation constant depends only on
 * data and so is dropped.
 *
 * @param y Parameter the prior is placed on.
 *
 * @param dist Distribution id: 0 flat (no contribution), 1 normal,
 * 2 log-normal, 3 gamma, 4 exponential.
 *
 * @param loc Location (first natural parameter) of the prior.
 *
 * @param scale Scale (second natural parameter) of the prior.
 *
 * @return The log density of `y` under the selected prior.
 */
real prior_lpdf(real y, int dist, real loc, real scale) {
  if (dist == 0) {
    return 0;
  } else if (dist == 1) {
    return normal_lpdf(y | loc, scale);
  } else if (dist == 2) {
    return lognormal_lpdf(y | loc, scale);
  } else if (dist == 3) {
    return gamma_lpdf(y | loc, scale);
  } else if (dist == 4) {
    return exponential_lpdf(y | loc);
  }
  reject("Unsupported prior distribution id: ", dist);
}

/**
 * Log density of a prior selected by a distribution id (shared parameters)
 *
 * Vector variant of `prior_lpdf()` with a single location and scale shared
 * by all elements.
 *
 * @param y Vector of parameters the prior is placed on.
 *
 * @param dist Distribution id, see `prior_lpdf()`.
 *
 * @param loc Location (first natural parameter) of the prior.
 *
 * @param scale Scale (second natural parameter) of the prior.
 *
 * @return The summed log density of `y` under the selected prior.
 */
real prior_lpdf(vector y, int dist, real loc, real scale) {
  if (dist == 0) {
    return 0;
  } else if (dist == 1) {
    return normal_lpdf(y | loc, scale);
  } else if (dist == 2) {
    return lognormal_lpdf(y | loc, scale);
  } else if (dist == 3) {
    return gamma_lpdf(y | loc, scale);
  } else if (dist == 4) {
    return exponential_lpdf(y | loc);
  }
  reject("Unsupported prior distribution id: ", dist);
}

/**
 * Log density of a prior selected by a distribution id (elementwise
 * parameters)
 *
 * Vector variant of `prior_lpdf()` with a location and scale per element,
 * as used for vectorised priors such as the initial latent observations.
 *
 * @param y Vector of parameters the prior is placed on.
 *
 * @param dist Distribution id, see `prior_lpdf()`.
 *
 * @param loc Locations (first natural parameter) of the prior, one per
 * element of `y`.
 *
 * @param scale Scales (second natural parameter) of the prior, one per
 * element of `y`.
 *
 * @return The summed log density of `y` under the selected prior.
 */
real prior_lpdf(vector y, int dist, array[] real loc, array[] real scale) {
  if (dist == 0) {
    return 0;
  } else if (dist == 1) {
    return normal_lpdf(y | to_vector(loc), to_vector(scale));
  } else if (dist == 2) {
    return lognormal_lpdf(y | to_vector(loc), to_vector(scale));
  } else if (dist == 3) {
    return gamma_lpdf(y | to_vector(loc), to_vector(scale));
  } else if (dist == 4) {
    return exponential_lpdf(y | to_vector(loc));
  }
  reject("Unsupported prior distribution id: ", dist);
}

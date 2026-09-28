/**
 * Convert logit hazards to log probabilities (pure Stan)
 *
 * Reference implementation of `logit_hazard_to_log_prob()`, which the
 * package calls through a fused C++ implementation
 * (inst/include/epinowcast/logit_hazard_to_log_prob.hpp) when the C++
 * adjoint path is enabled (see `epinowcast.use_cpp` in `enw_model()`).
 * Used as the fallback implementation when the C++ path is disabled, and
 * by the tests to check that implementation's values and gradients.
 *
 * @param lh Vector of logit hazards.
 *
 * @param l Length of the vector lh.
 *
 * @return Vector of log probabilities corresponding to the input logit
 * hazards.
 *
 * Dependencies:
 *  - hazard_to_log_prob
 */
vector logit_hazard_to_log_prob_stan(vector lh, int l) {
  return hazard_to_log_prob(inv_logit(lh), l);
}

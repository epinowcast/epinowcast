/**
 * Convert logit hazards to log probabilities
 *
 * Fuses `inv_logit()` and `hazard_to_log_prob()` into a single call on
 * the hot path of `expected_obs()` (called once per snapshot, whenever a
 * report-date model is present). The implementation is in C++, with a
 * hand-derived reverse-mode adjoint: see
 * inst/include/epinowcast/logit_hazard_to_log_prob.hpp.
 *
 * When the C++ adjoint path is disabled (`epinowcast.use_cpp = FALSE`,
 * or `enw_model(use_cpp = FALSE)`), `enw_model()` swaps in a pure-Stan
 * definition of this same function, calling straight through to
 * `logit_hazard_to_log_prob_stan()` (logit_hazard_to_log_prob_stan.stan),
 * so the package still works without a working C++ toolchain for the
 * header.
 *
 * @param lh Vector of logit hazards.
 *
 * @param l Length of the vector lh; must equal `num_elements(lh)`.
 *
 * @return Vector of log probabilities corresponding to the input logit
 * hazards.
 *
 * @note For delay slot d (1-based), `log p_d = log(h_d) +
 * sum_{j=1}^{d-1} log(1 - h_j)`, with `h_d = inv_logit(lh_d)` — the same
 * identity `hazard_to_log_prob()` computes, but as one fused operation.
 * The C++ version works on the log scale, so it stays finite where `h`
 * rounds to 0 or 1 and `hazard_to_log_prob()` returns `-inf`.
 */
vector logit_hazard_to_log_prob(vector lh, int l);

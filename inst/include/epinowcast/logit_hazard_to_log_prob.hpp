#ifndef EPINOWCAST_LOGIT_HAZARD_TO_LOG_PROB_HPP
#define EPINOWCAST_LOGIT_HAZARD_TO_LOG_PROB_HPP

/**
 * Fused logit-hazard to log-probability conversion, with a reverse-mode
 * adjoint.
 *
 * Implements `logit_hazard_to_log_prob(lh, l)` from
 * inst/stan/functions/logit_hazard_to_log_prob.stan, which replaces
 * `hazard_to_log_prob(inv_logit(lh), l)` (inst/stan/functions/hazard.stan)
 * inside `expected_obs()`, on the hot path of every model with a
 * report-date model (`ref_as_p == 0`).
 *
 * Notation (1-based, as in the Stan code): lh is the vector of logit
 * hazards, length l, and h_d = inv_logit(lh_d).
 *
 * Forward:
 *   log p_d = log(h_d) + sum_{j=1}^{d-1} log(1 - h_j),  d = 1, ..., l,
 * with log(h_d) = log_inv_logit(lh_d) and log(1 - h_j) =
 * log1m_inv_logit(lh_j). Working on the log scale keeps log p finite
 * where h rounds to 0 or 1 in double precision (|lh| above about 37),
 * where the Stan composition returns -inf.
 *
 * Reverse: with pbar_d the adjoint of log p_d, and using
 * d log_inv_logit(x) / dx = 1 - inv_logit(x) and
 * d log1m_inv_logit(x) / dx = -inv_logit(x),
 *   lhbar_j = pbar_j * (1 - h_j) - h_j * sum_{d=j+1}^{l} pbar_d.
 * The suffix sum is accumulated in the same backward loop, so both passes
 * are O(l). There is no division, so no special case is needed at h = 0
 * or h = 1.
 *
 * Both passes run on doubles in one reverse_pass_callback, so the
 * conversion is one autodiff node rather than one node per Stan Math
 * builtin call. lh may be var or double. The function is put in
 * stan::math so that Stan-generated code finds it.
 *
 * Delete this file (and use logit_hazard_to_log_prob_stan() directly) if
 * the benchmark in touchstone/gradient_timing.R stops showing a gain.
 */

#include <stan/math.hpp>
#include <ostream>
#include <stdexcept>

namespace epinowcast {
namespace internal {

// Returns log p; writes h = inv_logit(lh) to h_out for the reverse pass.
inline Eigen::VectorXd logit_hazard_to_log_prob_forward(
    const Eigen::VectorXd& lh, Eigen::VectorXd& h_out) {
  const int l = lh.size();
  Eigen::VectorXd logp(l);
  h_out.resize(l);
  double log_surv = 0.0;
  for (int d = 0; d < l; ++d) {
    logp(d) = stan::math::log_inv_logit(lh(d)) + log_surv;
    log_surv += stan::math::log1m_inv_logit(lh(d));
    h_out(d) = stan::math::inv_logit(lh(d));
  }
  return logp;
}

// lhbar_j = pbar_j * (1 - h_j) - h_j * sum_{d > j} pbar_d.
inline Eigen::VectorXd logit_hazard_to_log_prob_reverse(
    const Eigen::VectorXd& h, const Eigen::VectorXd& logp_adj) {
  const int l = h.size();
  Eigen::VectorXd lhbar(l);
  double suffix_sum = 0.0;
  for (int d = l - 1; d >= 0; --d) {
    lhbar(d) = logp_adj(d) * (1.0 - h(d)) - h(d) * suffix_sum;
    suffix_sum += logp_adj(d);
  }
  return lhbar;
}

}  // namespace internal

/**
 * Convert a vector of logit hazards to log probabilities, fusing
 * `inv_logit()` and `hazard_to_log_prob()` into a single autodiff node.
 *
 * @param lh Vector of logit hazards (var or double), length l.
 * @param l Length of lh; must equal `lh.size()`.
 * @param pstream__ Stan's print stream argument; not used.
 * @throws std::invalid_argument if lh does not have exactly l elements.
 */
template <typename T0, stan::require_eigen_col_vector_t<T0>* = nullptr>
inline Eigen::Matrix<stan::return_type_t<T0>, Eigen::Dynamic, 1>
logit_hazard_to_log_prob(const T0& lh, const int& l,
                         std::ostream* /* pstream__ */) {
  using stan::arena_t;
  using stan::math::var;
  stan::math::check_size_match("logit_hazard_to_log_prob", "size of lh",
                               lh.size(), "l", l);
  Eigen::VectorXd h;
  if constexpr (!stan::is_var<stan::value_type_t<T0>>::value) {
    return internal::logit_hazard_to_log_prob_forward(
        stan::math::value_of(lh), h);
  } else {
    arena_t<Eigen::Matrix<var, Eigen::Dynamic, 1>> lh_arena = lh;
    const Eigen::VectorXd logp = internal::logit_hazard_to_log_prob_forward(
        stan::math::value_of(lh_arena), h);
    arena_t<Eigen::VectorXd> h_arena = h;
    arena_t<Eigen::Matrix<var, Eigen::Dynamic, 1>> res = logp;
    stan::math::reverse_pass_callback([lh_arena, h_arena, res]() mutable {
      lh_arena.adj() += internal::logit_hazard_to_log_prob_reverse(
          h_arena, res.adj());
    });
    return Eigen::Matrix<var, Eigen::Dynamic, 1>(res);
  }
}

}  // namespace epinowcast

namespace stan {
namespace math {
using ::epinowcast::logit_hazard_to_log_prob;
}  // namespace math
}  // namespace stan

#endif

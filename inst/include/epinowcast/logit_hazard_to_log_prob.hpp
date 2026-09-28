#ifndef EPINOWCAST_LOGIT_HAZARD_TO_LOG_PROB_HPP
#define EPINOWCAST_LOGIT_HAZARD_TO_LOG_PROB_HPP

/**
 * Fused logit-hazard to log-probability conversion, with a reverse-mode
 * adjoint.
 *
 * Implements `logit_hazard_to_log_prob(lh, l)` from
 * inst/stan/functions/logit_hazard_to_log_prob.stan, which replaces the
 * pair of calls `inv_logit(lh)` followed by `hazard_to_log_prob(p, l)`
 * (inst/stan/functions/hazard.stan) inside `expected_obs()`
 * (inst/stan/functions/expected_obs.stan), on the hot path for every model
 * with a report-date model (`ref_as_p == 0`).
 *
 * Notation (1-based, as in the Stan code): lh is the vector of logit
 * hazards, length l. Writing h_d = inv_logit(lh_d),
 *
 * Forward:
 *   log p_d = log(h_d) + sum_{j=1}^{d-1} log(1 - h_j),  d = 1, ..., l,
 * computed with a single running log-survival accumulator rather than the
 * separate `log1m`, `append_row`, `cumulative_sum`, `log`, `inv_logit`
 * calls the Stan composition uses.
 *
 * Reverse: with pbar_d the adjoint of log p_d and T_j = sum_{d=j+1}^{l}
 * pbar_d a suffix cumulative sum of the incoming cotangents (the mirror
 * image of the forward prefix sum),
 *   hbar_j = pbar_j / h_j - T_j / (1 - h_j),
 * then through the sigmoid, lhbar_d = hbar_d * h_d * (1 - h_d). T_j is
 * accumulated in the same backward pass that computes hbar_j, so both
 * passes are O(l) with no separate O(l) buffer for T.
 *
 * See speedup-hazards.md (the design document that motivated this
 * function) for the full derivation.
 *
 * Both passes run on doubles in one reverse_pass_callback, so the
 * conversion is one autodiff node rather than one node per Stan Math
 * builtin call. lh may be var or double. The function is put in
 * stan::math so that Stan-generated code finds it.
 */

#include <stan/math.hpp>
#include <ostream>
#include <stdexcept>

namespace epinowcast {
namespace internal {

inline void check_logit_hazard_len(int lh_size, int l) {
  if (lh_size != l) {
    throw std::domain_error(
        "logit_hazard_to_log_prob: lh must have exactly l elements");
  }
}

// h_d = inv_logit(lh_d); log p_d = log(h_d) + running log-survival.
//
// log1m(h_d) is skipped for the last element (d == l - 1): its
// contribution to log_surv is never read (the loop ends right after),
// and h_{l-1} is the one element of h that hazard_to_log_prob() never
// passes to log1m() either (cumulative_converse_log_hazard() only ever
// sees h[1:(l-1)] in Stan's 1-based indexing). Skipping it matters
// numerically, not just for avoiding wasted work: at a saturated hazard
// (h_{l-1} rounds to exactly 1 for a large enough lh_{l-1}), Stan Math's
// log1m() throws std::domain_error, which the Stan composition never
// triggers for this element and this function must not either.
inline Eigen::VectorXd logit_hazard_to_log_prob_forward(
    const Eigen::VectorXd& lh, Eigen::VectorXd* h_out) {
  const int l = lh.size();
  Eigen::VectorXd h(l);
  Eigen::VectorXd logp(l);
  double log_surv = 0.0;
  for (int d = 0; d < l; ++d) {
    h(d) = stan::math::inv_logit(lh(d));
    logp(d) = std::log(h(d)) + log_surv;
    if (d < l - 1) {
      log_surv += stan::math::log1m(h(d));
    }
  }
  if (h_out != nullptr) {
    *h_out = h;
  }
  return logp;
}

// hbar_j = pbar_j / h_j - T_j / (1 - h_j), T_j = sum_{d > j} pbar_d;
// lhbar_d = hbar_d * h_d * (1 - h_d).
//
// T_{l-1} is exactly 0 (no d > l - 1), so the 1 / (1 - h_{l-1}) term is
// skipped rather than computed and multiplied by a zero suffix_sum: at a
// saturated hazard (h_{l-1} == 1 exactly) that product is 0 * Inf = NaN
// in IEEE arithmetic, even though the true contribution is exactly zero.
// This mirrors the forward pass skipping log1m(h_{l-1}) for the same
// reason.
inline Eigen::VectorXd logit_hazard_to_log_prob_reverse(
    const Eigen::VectorXd& h, const Eigen::VectorXd& logp_adj) {
  const int l = h.size();
  Eigen::VectorXd lhbar(l);
  double suffix_sum = 0.0;
  for (int d = l - 1; d >= 0; --d) {
    double hbar_d = logp_adj(d) / h(d);
    if (suffix_sum != 0.0) {
      hbar_d -= suffix_sum / (1.0 - h(d));
    }
    lhbar(d) = hbar_d * h(d) * (1.0 - h(d));
    suffix_sum += logp_adj(d);
  }
  return lhbar;
}

}  // namespace internal

/**
 * Convert a vector of logit hazards to log probabilities, fusing
 * `inv_logit()` and `hazard_to_log_prob()` into a single autodiff node.
 *
 * The last argument is the output stream of the Stan calling convention,
 * which is not used.
 *
 * @param lh Vector of logit hazards (var or double), length l.
 * @param l Length of lh; must equal `lh.size()`.
 * @throws std::domain_error if lh does not have exactly l elements.
 */
template <typename T0, stan::require_eigen_col_vector_t<T0>* = nullptr>
inline Eigen::Matrix<stan::return_type_t<T0>, Eigen::Dynamic, 1>
logit_hazard_to_log_prob(const T0& lh, const int& l,
                         std::ostream* /* pstream__ */) {
  using stan::arena_t;
  using stan::math::var;
  constexpr bool lh_var = stan::is_var<stan::value_type_t<T0>>::value;
  internal::check_logit_hazard_len(lh.size(), l);
  if constexpr (!lh_var) {
    return internal::logit_hazard_to_log_prob_forward(
        stan::math::value_of(lh), nullptr);
  } else {
    arena_t<Eigen::Matrix<stan::value_type_t<T0>, Eigen::Dynamic, 1>>
        lh_arena = lh;
    arena_t<Eigen::VectorXd> lh_val = stan::math::value_of(lh_arena);
    Eigen::VectorXd h_val;
    const Eigen::VectorXd logp =
        internal::logit_hazard_to_log_prob_forward(lh_val, &h_val);
    arena_t<Eigen::VectorXd> h_arena = h_val;
    arena_t<Eigen::Matrix<var, Eigen::Dynamic, 1>> res(l);
    for (int i = 0; i < l; ++i) {
      res.coeffRef(i) = var(logp(i));
    }
    stan::math::reverse_pass_callback(
        [=]() mutable {
          const Eigen::VectorXd logp_adj = res.adj();
          const Eigen::VectorXd lhbar =
              internal::logit_hazard_to_log_prob_reverse(h_arena, logp_adj);
          lh_arena.adj() += lhbar;
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

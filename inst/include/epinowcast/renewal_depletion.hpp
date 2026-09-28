#ifndef EPINOWCAST_RENEWAL_DEPLETION_HPP
#define EPINOWCAST_RENEWAL_DEPLETION_HPP

/**
 * Renewal equation with optional susceptible depletion, with a
 * reverse-mode adjoint.
 *
 * Backs the Stan function `renewal_depletion(seed, R, rgt, pop, use_pop,
 * pop_floor)` declared in inst/stan/functions/renewal_depletion.stan,
 * which replaces the `gt_n > 1` loop in log_expected_latent_from_r()
 * (inst/stan/functions/log_expected_latent_from_r.stan) for a single
 * group. The pure-Stan reference is renewal_depletion_stan() in
 * inst/stan/functions/renewal_depletion_stan.stan. It follows EpiNow2's
 * renewal_infections() adjoint (epiforecasts/EpiNow2 PR #1545) with two
 * differences. The seeding period always equals the generation-time
 * length, so the window never grows. The floor pop_floor protects only
 * the rate denominator, not the output multiplier, so there are three
 * branch points per step rather than two.
 *
 * Notation (1-based, as in the Stan code): seed is the seeded latent
 * series, length n0 (equal to the generation-time length everywhere
 * this is called). R is the post-seed reproduction number / growth
 * multiplier series, length r_t. rgt is the generation-time weight
 * vector, length n0, in the order log_expected_latent_from_r() uses it
 * in its dot product (reversed relative to the generation time).
 *
 * Forward, for i = 1, ..., r_t with u = n0 + i:
 *   lambda_i = sum_{j=1}^{n0} rgt_j * I_{i - 1 + j}.
 * Without depletion (use_pop = 0):
 *   I_u = R_i * lambda_i.
 * With depletion (use_pop = 1), writing C_0 = sum(seed):
 *   remaining_i = fmax(0, pop - C_{i-1}),
 *   denom_i     = fmax(pop_floor, remaining_i),
 *   a_i         = R_i * lambda_i / denom_i,
 *   I_u         = fmax(1e-8, remaining_i * (1 - exp(-a_i))),
 *   C_i         = C_{i-1} + I_u.
 * The 1 - exp(-a_i) term is not separately clipped at 0 (unlike
 * EpiNow2's fmax(0, 1 - exp(-a_t))), as the Stan code does not clip it:
 * a_i >= 0 whenever R, lambda >= 0 and denom_i > 0. With pop_floor = 0
 * and an exhausted pool denom_i is 0. The value is then the 1e-8 floor
 * but the gradients are NaN, as they are in the Stan reference.
 *
 * Reverse. Write xbar for the adjoint of x. Walk i = r_t, ..., 1. When
 * step i is reached, Ibar_u already holds every contribution from
 * later times (through lambda and C). Then, without depletion:
 *   Rbar_i = Ibar_u * lambda_i,  lambdabar_i = Ibar_u * R_i;
 * with depletion, with e_i = exp(-a_i) (cached from the forward pass):
 *   raw_i        = remaining_i * (1 - e_i),
 *   raw_bar_i    = Ibar_u if raw_i >= 1e-8 else 0,
 *   adj_bar_i    = raw_bar_i * remaining_i,
 *   abar_i       = adj_bar_i * e_i,
 *   Rbar_i      += abar_i * lambda_i / denom_i,
 *   lambdabar_i  = abar_i * R_i / denom_i,
 *   denombar_i   = -abar_i * a_i / denom_i,
 *   remaining_bar_i = raw_bar_i * (1 - e_i)
 *                     + (denombar_i if remaining_i >= pop_floor else 0),
 *   and, only if pop - C_{i-1} >= 0: popbar += remaining_bar_i,
 *   Cbar -= remaining_bar_i (Cbar then feeds Ibar_{u-1} and, at i = 1,
 *   every seed element, since C_0 = sum(seed));
 * then, both branches:
 *   Ibar_{i:i+n0-1} += lambdabar_i * rgt,
 *   rgtbar          += lambdabar_i * I_{i:i+n0-1}.
 * The fmax() branches follow Stan's fmax(): the second argument is
 * taken, with its gradient, when it is at least the first and not NaN
 * (matching EpiNow2 PR #1545's documented convention for the same
 * function family).
 *
 * The forward pass and this reverse walk work on plain doubles, so the
 * whole loop is one autodiff node. Any of seed, R, rgt and pop may be
 * var or double; only the gradients of var inputs are computed. As
 * with logit_hazard_to_log_prob(), the function lives in namespace
 * epinowcast and is made visible in stan::math.
 */

#include <stan/math.hpp>
#include <cmath>
#include <ostream>
#include <stdexcept>

namespace epinowcast {
namespace internal {

inline void check_renewal_depletion_len(int seed_size, int rgt_size) {
  if (seed_size != rgt_size) {
    throw std::domain_error(
        "renewal_depletion: seed and rgt must have the same length");
  }
  if (seed_size < 1) {
    throw std::domain_error("renewal_depletion: seeding time must be >= 1");
  }
}

// Forward values kept for the reverse pass. C_before and e are only
// filled (and only meaningful) when use_pop is true.
struct renewal_depletion_state {
  Eigen::VectorXd I, lambda, C_before, e;
};

inline void renewal_depletion_forward(const Eigen::VectorXd& seed,
                                      const Eigen::VectorXd& R,
                                      const Eigen::VectorXd& rgt, double pop,
                                      int use_pop, double pop_floor,
                                      renewal_depletion_state& st) {
  const int n0 = seed.size();
  const int r_t = R.size();
  st.I = Eigen::VectorXd::Zero(n0 + r_t);
  st.I.head(n0) = seed;
  st.lambda.resize(r_t);
  if (use_pop) {
    st.C_before.resize(r_t);
    st.e.resize(r_t);
  }
  double C = use_pop ? seed.sum() : 0.0;
  for (int i = 0; i < r_t; ++i) {
    const double lambda = st.I.segment(i, n0).dot(rgt);
    st.lambda(i) = lambda;
    double val;
    if (use_pop) {
      st.C_before(i) = C;
      const double remaining = std::fmax(0.0, pop - C);
      const double denom = std::fmax(pop_floor, remaining);
      const double a = R(i) * lambda / denom;
      const double e = std::exp(-a);
      st.e(i) = e;
      val = std::fmax(1e-8, remaining * (1.0 - e));
      C += val;
    } else {
      val = R(i) * lambda;
    }
    st.I(n0 + i) = val;
  }
}

inline void renewal_depletion_reverse(
    const renewal_depletion_state& st, const Eigen::VectorXd& R,
    const Eigen::VectorXd& rgt, double pop, int use_pop, double pop_floor,
    const Eigen::VectorXd& Ibar_in, Eigen::VectorXd& seedbar,
    Eigen::VectorXd& Rbar, Eigen::VectorXd& rgtbar, double& popbar) {
  const int r_t = R.size();
  const int n0 = st.I.size() - r_t;
  Eigen::VectorXd Ibar = Ibar_in;
  Rbar = Eigen::VectorXd::Zero(r_t);
  rgtbar = Eigen::VectorXd::Zero(n0);
  popbar = 0.0;
  double Cbar = 0.0;
  for (int i = r_t - 1; i >= 0; --i) {
    if (use_pop && i < r_t - 1) {
      Ibar(n0 + i) += Cbar;
    }
    const double ib = Ibar(n0 + i);
    double lambdabar;
    if (use_pop) {
      const double remaining = std::fmax(0.0, pop - st.C_before(i));
      const double denom = std::fmax(pop_floor, remaining);
      const double e = st.e(i);
      const double adj = 1.0 - e;
      const double raw = remaining * adj;
      const double raw_bar = (raw >= 1e-8) ? ib : 0.0;
      const double remaining_bar_mult = raw_bar * adj;
      const double adj_bar = raw_bar * remaining;
      const double abar = adj_bar * e;
      const double a = R(i) * st.lambda(i) / denom;
      Rbar(i) += abar * st.lambda(i) / denom;
      lambdabar = abar * R(i) / denom;
      const double denombar = -abar * a / denom;
      const double remaining_bar =
          remaining_bar_mult + (remaining >= pop_floor ? denombar : 0.0);
      if (pop - st.C_before(i) >= 0.0) {
        popbar += remaining_bar;
        Cbar -= remaining_bar;
      }
    } else {
      Rbar(i) += ib * st.lambda(i);
      lambdabar = ib * R(i);
    }
    Ibar.segment(i, n0) += lambdabar * rgt;
    rgtbar += lambdabar * st.I.segment(i, n0);
  }
  seedbar = Ibar.head(n0);
  if (use_pop) {
    seedbar.array() += Cbar;
  }
}

}  // namespace internal

/**
 * Run the renewal equation with optional susceptible depletion.
 *
 * The last argument is the output stream of the Stan calling convention,
 * which is not used.
 *
 * @param seed Seeding latent values, length n0 >= 1 (var or double).
 * @param R Reproduction numbers / growth multipliers, length r_t (var or
 *   double).
 * @param rgt Generation-time weights, length n0 (var or double).
 * @param pop Initial susceptible population (var or double). Ignored
 *   when use_pop = 0.
 * @param use_pop Susceptible-depletion switch (0 off, 1 on).
 * @param pop_floor Minimum susceptible population (double), used only
 *   as a floor on the rate denominator when use_pop = 1.
 * @return The full latent series, length n0 + r_t, starting with seed.
 * @throws std::domain_error if seed and rgt differ in length, or seed
 *   is empty.
 */
template <typename T0, typename T1, typename T2, typename T3,
          stan::require_all_eigen_col_vector_t<T0, T1, T2>* = nullptr,
          stan::require_stan_scalar_t<T3>* = nullptr>
inline Eigen::Matrix<stan::return_type_t<T0, T1, T2, T3>, Eigen::Dynamic, 1>
renewal_depletion(const T0& seed, const T1& R, const T2& rgt, const T3& pop,
                  const int& use_pop, const double& pop_floor,
                  std::ostream* /* pstream__ */) {
  using stan::arena_t;
  using stan::math::var;
  using stan::math::value_of;
  constexpr bool seed_var = stan::is_var<stan::value_type_t<T0>>::value;
  constexpr bool R_var = stan::is_var<stan::value_type_t<T1>>::value;
  constexpr bool rgt_var = stan::is_var<stan::value_type_t<T2>>::value;
  constexpr bool pop_var = stan::is_var<T3>::value;
  internal::check_renewal_depletion_len(seed.size(), rgt.size());
  const double pop_d = value_of(pop);
  if constexpr (!seed_var && !R_var && !rgt_var && !pop_var) {
    internal::renewal_depletion_state st;
    internal::renewal_depletion_forward(value_of(seed), value_of(R),
                                        value_of(rgt), pop_d, use_pop,
                                        pop_floor, st);
    return st.I;
  } else {
    arena_t<Eigen::Matrix<stan::value_type_t<T0>, -1, 1>> seed_a = seed;
    arena_t<Eigen::Matrix<stan::value_type_t<T1>, -1, 1>> R_a = R;
    arena_t<Eigen::Matrix<stan::value_type_t<T2>, -1, 1>> rgt_a = rgt;
    arena_t<Eigen::VectorXd> R_val = value_of(R_a);
    arena_t<Eigen::VectorXd> rgt_val = value_of(rgt_a);
    arena_t<Eigen::VectorXd> seed_val = value_of(seed_a);
    internal::renewal_depletion_state fwd;
    internal::renewal_depletion_forward(seed_val, R_val, rgt_val, pop_d,
                                        use_pop, pop_floor, fwd);
    arena_t<Eigen::VectorXd> I_a = fwd.I;
    arena_t<Eigen::VectorXd> lambda_a = fwd.lambda;
    arena_t<Eigen::VectorXd> C_before_a = fwd.C_before;
    arena_t<Eigen::VectorXd> e_a = fwd.e;
    const int n = fwd.I.size();
    arena_t<Eigen::Matrix<var, -1, 1>> res(n);
    for (int i = 0; i < n; ++i) {
      res.coeffRef(i) = var(fwd.I(i));
    }
    T3 pop_v = pop;
    stan::math::reverse_pass_callback([=]() mutable {
      internal::renewal_depletion_state st{I_a, lambda_a, C_before_a, e_a};
      Eigen::VectorXd seedbar, Rbar, rgtbar;
      double popbar = 0.0;
      internal::renewal_depletion_reverse(st, R_val, rgt_val, pop_d, use_pop,
                                          pop_floor, res.adj(), seedbar,
                                          Rbar, rgtbar, popbar);
      if constexpr (seed_var) {
        seed_a.adj() += seedbar;
      }
      if constexpr (R_var) {
        R_a.adj() += Rbar;
      }
      if constexpr (rgt_var) {
        rgt_a.adj() += rgtbar;
      }
      if constexpr (pop_var) {
        pop_v.adj() += popbar;
      }
    });
    return Eigen::Matrix<var, -1, 1>(res);
  }
}

}  // namespace epinowcast

namespace stan {
namespace math {
using ::epinowcast::renewal_depletion;
}  // namespace math
}  // namespace stan

#endif

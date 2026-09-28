/**
 * Renewal equation with optional susceptible depletion
 *
 * Replaces the `gt_n > 1` loop in log_expected_latent_from_r()
 * (log_expected_latent_from_r.stan) for a single group, with or
 * without susceptible depletion. The implementation is in C++, with a
 * hand-derived reverse-mode adjoint:
 * see inst/include/epinowcast/renewal_depletion.hpp.
 *
 * When the C++ adjoint path is disabled (`epinowcast.use_cpp = FALSE`,
 * or `enw_model(use_cpp = FALSE)`), `enw_model()` swaps in a pure-Stan
 * definition of this same function, calling straight through to
 * `renewal_depletion_stan()` (renewal_depletion_stan.stan), so the
 * package still works without a working C++ toolchain for the header.
 *
 * @param seed Seeding latent values, length n0 (equal to the
 * generation-time length everywhere this is called, since epinowcast's
 * seeding period is always sized to match).
 *
 * @param r Reproduction numbers / growth multipliers for the post-seed
 * series, length r_t.
 *
 * @param rgt Generation-time weight vector, length n0, in the same
 * order log_expected_latent_from_r() already passes to its
 * `dot_product()` call.
 *
 * @param pop Initial susceptible population. Ignored when `use_pop ==
 * 0`.
 *
 * @param use_pop Susceptible-depletion switch (0 off, 1 on).
 *
 * @param pop_floor Minimum susceptible population, floored on the
 * transmission-rate denominator only (never on the output multiplier;
 * see the note below). Only used when `use_pop == 1`.
 *
 * @return Vector of length `n0 + r_t`: the seeding values followed by
 * the post-seed latent series, all on the natural scale.
 *
 * @note For step `i` (1-based), writing `lambda_i` for the
 * generation-time-weighted sum of the preceding `n0` values: without
 * depletion, `I_u = r_i * lambda_i`. With depletion, writing `C_0 =
 * sum(seed)`, `remaining_i = fmax(0, pop - C_{i-1})`, `denom_i =
 * fmax(pop_floor, remaining_i)`, `I_u = fmax(1e-8, remaining_i * (1 -
 * exp(-r_i * lambda_i / denom_i)))`, `C_i = C_{i-1} + I_u`. The
 * `pop_floor` guard protects only `denom_i` (the rate denominator);
 * `remaining_i` itself (the output multiplier) is never floored above
 * zero, so depletion cannot report more cases than physically remain
 * in the pool once the floor binds harder than the raw remaining
 * count. See inst/include/epinowcast/renewal_depletion.hpp for the
 * full forward/reverse derivation.
 */
vector renewal_depletion(vector seed, vector r, vector rgt, real pop,
                         int use_pop, data real pop_floor);

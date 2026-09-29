/**
 * Convolve a vector with a reversed probability mass function
 *
 * Discrete convolution of `x` with the already-reversed delay PMF `y`,
 * used by `log_expected_obs_from_latent()` to convolve a group's latent
 * expected values with the latent-to-observation reporting delay. The
 * implementation is in C++, with a hand-derived reverse-mode adjoint: see
 * inst/include/epinowcast/convolve_with_rev_pmf.hpp.
 *
 * When the C++ adjoint path is disabled (`epinowcast.use_cpp = FALSE`, or
 * `enw_model(use_cpp = FALSE)`), `enw_model()` swaps in a pure-Stan
 * definition of this same function, calling straight through to
 * `convolve_with_rev_pmf_stan()` (convolve_with_rev_pmf_stan.stan), so the
 * package still works without a working C++ toolchain for the header.
 *
 * @param x The input vector to be convolved, length n.
 *
 * @param y The already-reversed PMF vector, length D.
 *
 * @param len The desired length of the output vector; n <= len <= n + D - 1.
 *
 * @return A vector of length `len` containing the convolution result:
 * for `t = 1, ..., len`, `z_t = sum_{d=0}^{D-1} w_d x_{t-d}`, with
 * `w_d = y_{D-d}` (`x_s = 0` outside `1, ..., n`).
 *
 * @throws If `len` is longer than the full convolution (n + D - 1) or
 * shorter than `x`.
 */
vector convolve_with_rev_pmf(vector x, vector y, int len);

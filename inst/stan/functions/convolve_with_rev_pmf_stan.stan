/**
 * Convolve a vector with a reversed probability mass function (pure Stan)
 *
 * Reference implementation of `convolve_with_rev_pmf()`, which the
 * package calls through a C++ implementation
 * (inst/include/epinowcast/convolve_with_rev_pmf.hpp) when the C++
 * adjoint path is enabled (see `epinowcast.use_cpp` in `enw_model()`).
 * Used as the fallback implementation when the C++ path is disabled, and
 * by the tests to check that implementation's values and gradients.
 *
 * @param x The input vector to be convolved, length n.
 *
 * @param y The already-reversed PMF vector, length D.
 *
 * @param len The desired length of the output vector; n <= len <= n + D - 1.
 *
 * @return A vector of length `len` containing the convolution result.
 *
 * @throws If `len` is longer than the full convolution (n + D - 1) or
 * shorter than `x`.
 */
vector convolve_with_rev_pmf_stan(vector x, vector y, int len) {
  int xlen = num_elements(x);
  int ylen = num_elements(y);

  if (xlen + ylen - 1 < len) {
    reject("convolve_with_rev_pmf: len is longer than x and y convolved");
  }
  if (xlen > len) {
    reject("convolve_with_rev_pmf: len is shorter than x");
  }

  vector[len] z = rep_vector(0, len);
  for (d in 0:(ylen - 1)) {
    int m = min(xlen, len - d);
    if (m <= 0) {
      break;
    }
    z[(d + 1):(d + m)] += y[ylen - d] * x[1:m];
  }
  return z;
}

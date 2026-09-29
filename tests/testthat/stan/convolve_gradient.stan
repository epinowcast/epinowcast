// Test model comparing the C++ convolve_with_rev_pmf() with the pure Stan
// reference convolve_with_rev_pmf_stan(). x and the reversed PMF y are
// each either parameters or data, so every var/double combination of the
// use_cpp flag switches which one the model block uses, so
// log_prob()/grad_log_prob() (via cmdstan_log_prob()) can be diffed
// directly between the two branches of the same compiled model. conv_mat
// is the convolution matrix the model used before the adjoint (built in R
// with convolution_matrix()), so z_matrix checks the new convolution
// against the previous matrix-product implementation.
functions {
#include functions/convolve_with_rev_pmf_stan.stan
#include functions/convolve_with_rev_pmf.stan

  vector conv(vector x, vector y, int len, int use_cpp) {
    if (use_cpp) {
      return convolve_with_rev_pmf(x, y, len);
    }
    return convolve_with_rev_pmf_stan(x, y, len);
  }
}

data {
  int n;
  int D;
  int len;
  vector[n] x_data;
  vector[D] y_data;
  vector[len] r;
  matrix[len, n] conv_mat;
  int<lower = 0, upper = 1> x_param;
  int<lower = 0, upper = 1> y_param;
  int<lower = 0, upper = 1> use_cpp;
}

parameters {
  vector[x_param ? n : 0] x_par;
  vector[y_param ? D : 0] y_par;
}

transformed parameters {
  vector[len] z;
  if (x_param && y_param) {
    z = conv(x_par, y_par, len, use_cpp);
  } else if (x_param) {
    z = conv(x_par, y_data, len, use_cpp);
  } else if (y_param) {
    z = conv(x_data, y_par, len, use_cpp);
  } else {
    z = conv(x_data, y_data, len, use_cpp);
  }
}

model {
  target += dot_product(r, z) - 0.5 * dot_self(z);
}

generated quantities {
  vector[len] z_cpp = convolve_with_rev_pmf(x_data, y_data, len);
  vector[len] z_stan = convolve_with_rev_pmf_stan(x_data, y_data, len);
  vector[len] z_matrix = conv_mat * x_data;
}

// Stan-only-call-site test model for the C++ renewal_depletion() adjoint,
// mirroring test_renewal_depletion_stan.stan but calling only the C++
// function (no runtime dispatch). Kept separate from the use_cpp-flagged
// dispatcher in test_renewal_depletion.stan because cmdstanr's
// compile_model_methods = TRUE (needed for log_prob()/grad_log_prob() in
// the gradient-parity tests) does not build correctly against that
// file's runtime `if (ctrl[2]) { ... } return ...;` dispatch — a
// cmdstanr/Rcpp standalone-build limitation, not a problem with
// renewal_depletion() itself (the plain, non-model-methods compile of
// the dispatcher succeeds; see test-stan_renewal_depletion.R).
functions {
#include functions/renewal_depletion.stan
}

data {
  int n0;
  int r_t;
  int use_pop;
  real pop_floor;
  vector[n0] seed_data;
  vector[r_t] R_data;
  vector[n0] rgt_data;
  real pop_data;
  vector[n0 + r_t] r;
  int<lower = 0, upper = 1> seed_param;
  int<lower = 0, upper = 1> R_param;
  int<lower = 0, upper = 1> rgt_param;
  int<lower = 0, upper = 1> pop_param;
}

parameters {
  vector[seed_param ? n0 : 0] log_seed;
  vector[R_param ? r_t : 0] log_R;
  vector[rgt_param ? n0 : 0] log_rgt;
  array[pop_param] real log_pop;
}

model {
  vector[n0] seed_v = seed_param ? exp(log_seed) : seed_data;
  vector[r_t] R_v = R_param ? exp(log_R) : R_data;
  vector[n0] rgt_v = rgt_param ? exp(log_rgt) : rgt_data;
  real pop_v = pop_param ? exp(log_pop[1]) : pop_data;
  vector[n0 + r_t] z = renewal_depletion(
    seed_v, R_v, rgt_v, pop_v, use_pop, pop_floor
  );
  target += dot_product(r, log1p(z));
}

generated quantities {
  vector[n0 + r_t] z_data = renewal_depletion(
    seed_data, R_data, rgt_data, pop_data, use_pop, pop_floor
  );
}

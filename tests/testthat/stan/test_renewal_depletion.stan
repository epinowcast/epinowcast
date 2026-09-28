// Test model comparing the C++ renewal_depletion() adjoint with the pure
// Stan reference renewal_depletion_stan(). Each of seed, R, rgt and pop is
// a parameter (on the log scale) or data, so every var/double combination
// of the adjoint's inputs is exercised by log_prob()/grad_log_prob().
//
// renewal_depletion() is declared without a body here. Until the
// inst/include C++ plumbing (branch feat/cpp-adjoints) is merged and the
// header wired in via a user_header at compile time, only use_cpp = 0
// (the pure Stan reference) can actually be sampled from this model.
functions {
#include renewal_depletion_stan.stan

  vector renewal_depletion(vector seed, vector r, vector rgt, real pop,
                           int use_pop, data real pop_floor);

  // ctrl holds use_pop and use_cpp.
  vector ren(vector seed, vector r, vector rgt, real pop, real pop_floor,
             array[] int ctrl) {
    if (ctrl[2]) {
      return renewal_depletion(seed, r, rgt, pop, ctrl[1], pop_floor);
    }
    return renewal_depletion_stan(seed, r, rgt, pop, ctrl[1], pop_floor);
  }
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
  int<lower = 0, upper = 1> use_cpp;
}

transformed data {
  array[2] int ctrl = {use_pop, use_cpp};
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
  vector[n0 + r_t] z = ren(seed_v, R_v, rgt_v, pop_v, pop_floor, ctrl);
  target += dot_product(r, log1p(z));
}

generated quantities {
  vector[n0 + r_t] z_data = ren(
    seed_data, R_data, rgt_data, pop_data, pop_floor, ctrl
  );
}

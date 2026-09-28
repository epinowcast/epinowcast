// Test model comparing the C++ renewal_depletion() with the pure-Stan
// reference renewal_depletion_stan(), both included from the package's
// inst/stan/functions/. A use_cpp data flag picks the implementation, so
// log densities and gradients can be compared within one compiled model.
// Each of seed, R, rgt and pop is a parameter (on the log scale) or data,
// and the model block has one call per combination, because model-block
// locals are always autodiff variables. This compiles and exercises every
// var/double instantiation of the C++ function. generated quantities
// covers the all-double path.
functions {
#include functions/renewal_depletion_stan.stan
#include functions/renewal_depletion.stan

  vector ren(vector seed, vector R, vector rgt, real pop, int use_pop,
             data real pop_floor, int use_cpp) {
    if (use_cpp) {
      return renewal_depletion(seed, R, rgt, pop, use_pop, pop_floor);
    }
    return renewal_depletion_stan(seed, R, rgt, pop, use_pop, pop_floor);
  }
}

data {
  int<lower = 1> n0;
  int<lower = 0> r_t;
  int<lower = 0, upper = 1> use_pop;
  real<lower = 0> pop_floor;
  vector[n0] seed_data;
  vector[r_t] R_data;
  vector[n0] rgt_data;
  real pop_data;
  vector[n0 + r_t] w;
  int<lower = 0, upper = 1> seed_param;
  int<lower = 0, upper = 1> R_param;
  int<lower = 0, upper = 1> rgt_param;
  int<lower = 0, upper = 1> pop_param;
  int<lower = 0, upper = 1> use_cpp;
}

parameters {
  vector[seed_param ? n0 : 0] log_seed;
  vector[R_param ? r_t : 0] log_R;
  vector[rgt_param ? n0 : 0] log_rgt;
  array[pop_param] real log_pop;
}

model {
  vector[n0 + r_t] z;
  if (seed_param && R_param && rgt_param && pop_param) {
    z = ren(exp(log_seed), exp(log_R), exp(log_rgt),
            exp(log_pop[1]), use_pop, pop_floor, use_cpp);
  } else if (!seed_param && R_param && rgt_param && pop_param) {
    z = ren(seed_data, exp(log_R), exp(log_rgt),
            exp(log_pop[1]), use_pop, pop_floor, use_cpp);
  } else if (seed_param && !R_param && rgt_param && pop_param) {
    z = ren(exp(log_seed), R_data, exp(log_rgt),
            exp(log_pop[1]), use_pop, pop_floor, use_cpp);
  } else if (!seed_param && !R_param && rgt_param && pop_param) {
    z = ren(seed_data, R_data, exp(log_rgt),
            exp(log_pop[1]), use_pop, pop_floor, use_cpp);
  } else if (seed_param && R_param && !rgt_param && pop_param) {
    z = ren(exp(log_seed), exp(log_R), rgt_data,
            exp(log_pop[1]), use_pop, pop_floor, use_cpp);
  } else if (!seed_param && R_param && !rgt_param && pop_param) {
    z = ren(seed_data, exp(log_R), rgt_data,
            exp(log_pop[1]), use_pop, pop_floor, use_cpp);
  } else if (seed_param && !R_param && !rgt_param && pop_param) {
    z = ren(exp(log_seed), R_data, rgt_data,
            exp(log_pop[1]), use_pop, pop_floor, use_cpp);
  } else if (!seed_param && !R_param && !rgt_param && pop_param) {
    z = ren(seed_data, R_data, rgt_data,
            exp(log_pop[1]), use_pop, pop_floor, use_cpp);
  } else if (seed_param && R_param && rgt_param && !pop_param) {
    z = ren(exp(log_seed), exp(log_R), exp(log_rgt),
            pop_data, use_pop, pop_floor, use_cpp);
  } else if (!seed_param && R_param && rgt_param && !pop_param) {
    z = ren(seed_data, exp(log_R), exp(log_rgt),
            pop_data, use_pop, pop_floor, use_cpp);
  } else if (seed_param && !R_param && rgt_param && !pop_param) {
    z = ren(exp(log_seed), R_data, exp(log_rgt),
            pop_data, use_pop, pop_floor, use_cpp);
  } else if (!seed_param && !R_param && rgt_param && !pop_param) {
    z = ren(seed_data, R_data, exp(log_rgt),
            pop_data, use_pop, pop_floor, use_cpp);
  } else if (seed_param && R_param && !rgt_param && !pop_param) {
    z = ren(exp(log_seed), exp(log_R), rgt_data,
            pop_data, use_pop, pop_floor, use_cpp);
  } else if (!seed_param && R_param && !rgt_param && !pop_param) {
    z = ren(seed_data, exp(log_R), rgt_data,
            pop_data, use_pop, pop_floor, use_cpp);
  } else if (seed_param && !R_param && !rgt_param && !pop_param) {
    z = ren(exp(log_seed), R_data, rgt_data,
            pop_data, use_pop, pop_floor, use_cpp);
  } else {
    z = ren(seed_data, R_data, rgt_data,
            pop_data, use_pop, pop_floor, use_cpp);
  }
  // The model logs the latent series after the renewal step.
  target += dot_product(w, log(z));
}

generated quantities {
  vector[n0 + r_t] z_cpp = renewal_depletion(
    seed_data, R_data, rgt_data, pop_data, use_pop, pop_floor
  );
  vector[n0 + r_t] z_stan = renewal_depletion_stan(
    seed_data, R_data, rgt_data, pop_data, use_pop, pop_floor
  );
}

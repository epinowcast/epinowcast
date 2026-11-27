// Test model comparing the C++ logit_hazard_to_log_prob() with the pure
// Stan reference logit_hazard_to_log_prob_stan(). A use_cpp data flag
// switches which one the model block uses, so log_prob()/grad_log_prob()
// (via $diagnose()) can be diffed directly between the two branches of the
// same compiled model. generated quantities always computes both, for a
// direct value comparison via a single fixed_param sample.
functions {
#include functions/hazard.stan
#include functions/logit_hazard_to_log_prob_stan.stan
#include functions/logit_hazard_to_log_prob.stan

  vector conv(vector lh, int l, int use_cpp) {
    if (use_cpp) {
      return logit_hazard_to_log_prob(lh, l);
    }
    return logit_hazard_to_log_prob_stan(lh, l);
  }
}

data {
  int l;
  vector[l] r;
  int<lower = 0, upper = 1> use_cpp;
}

parameters {
  vector[l] lh;
}

transformed parameters {
  vector[l] logp = conv(lh, l, use_cpp);
}

model {
  target += dot_product(r, logp) - 0.5 * dot_self(logp);
}

generated quantities {
  vector[l] logp_cpp = logit_hazard_to_log_prob(lh, l);
  vector[l] logp_stan = logit_hazard_to_log_prob_stan(lh, l);
}

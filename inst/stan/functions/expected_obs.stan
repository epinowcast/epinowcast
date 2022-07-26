// Calculate expected observations
// 
// Calculate expected observations (on the log scale) over time from a
// combination of final expected observations, the probability of reporting
// on a given day (or alternatively the logit hazard of this). 
// 
// @param tar_obs The log of final expected observations that will be reported
// for a given date on the log scale.
// 
// @param lh A vector of conditional log probabilities a report occurs on a
// given day. Optionally when ref_as_p = 0 this should be transformed first
// into the logit hazard.
// 
// @param ref_as_p Logical (0/1), should the reference date input be treatsd as 
// a probability. Useful when no report date effects are present.
// @return A vector of expected observations for a given date by date of report
// 
// @examples
// # compile function for use in R
// source(here::here("R", "utils.R"))
// expose_stan_fns(c("hazard.stan", "expected-observations.stan"),
//                 "inst/stan/functions")
//
// tar_obs <- log(1)
// date_p <- log(
//  plnorm(1:30, 1.5, 2) - plnorm(0:29, 1.5, 2)) / plnorm(30, 1.5, 2)
// )
// rep_lh <- rep(0, 30)
//
// Example with no reporting day effect
// eobs <- exp(expected_obs(tar_obs, date_p + rep(0, 30), 1))
// all.equal(eobs, date_p)
//
// Example with hazard effect only on last day of report
// ref_lh <- logit(hazard_to_log_prob(date_p))
// eobs <- exp(expected_obs(tar_obs, ref_lh, c(rep(0, 29), 0.1), 0))
// all.equal(eobs, date_p)
//
// Example with a single day of additional reporting hazard and
// no differential probability due to the reference date.
// rep_lh <- rep(0, 30); rep_lh[7] = 2
// equal_lh <- logit(hazard_to_log_prob(rep(1/30, 30)))
// round(exp(expected_obs(tar_obs, equal_lh + rep_lh, 0)), 3)
// # 0.033 0.033 0.033 0.033 0.033 0.033 0.195 0.026 0.026 0.026 0.026 0.026
// # 0.026 0.026 0.026 0.026 0.026 0.026 0.026 0.026 0.026 0.026 0.026 0.026
// # 0.026 0.026 0.026 0.026 0.026 0.026
//
// Example combining multiple hazards and no differential prob due to reference
// date
// rep_lh <- rep(0, 30)
// rep_lh[c(6, 12, 16)] = 2
// rep_lh[c(2, 20)] = -2
// round(exp(expected_obs(tar_obs, equal_lh + rep_lh, 0)), 3)
// # 0.033 0.005 0.034 0.034 0.034 0.202 0.027 0.027 0.027 0.027 0.027 0.151
// # 0.021 0.021 0.021 0.106 0.014 0.014 0.014 0.002 0.016 0.016 0.016 0.016
// # 0.016 0.016 0.016 0.016 0.016 0.016
//
// Example combining both date of reference and date of report effects
// eobs <- exp(expected_obs(tar_obs, ref_lh + rep_lh, 0))
// round(sum(eobs - 1e-4), 5) == 1
// round(eobs, 3)
// # 0.273 0.023 0.112 0.082 0.065 0.221 0.025 0.021 0.019 0.016 0.014 0.058
// # 0.007 0.007 0.006 0.024 0.003 0.003 0.003 0.000 0.003 0.002 0.002 0.002
// # 0.002 0.002 0.002 0.002 0.002 0.002
vector expected_obs(real tar_obs, vector lh, int ref_as_p) {
  int t = num_elements(lh);
  vector[t] exp_obs;
  if (ref_as_p == 1) {
    profile("model_likelihood_expected_obs_prod_p") {
    exp_obs = tar_obs + lh;
    }
  }else{
    vector[t] p;
    profile("model_likelihood_expected_obs_inv_logit") {
    p = inv_logit(lh);
    }
    profile("model_likelihood_expected_obs_hazard_to_prob") {
    p = hazard_to_log_prob(p);
    }
    profile("model_likelihood_expected_obs_prod_p") {
    exp_obs = tar_obs + p;
    }
  }
  return(exp_obs);
}

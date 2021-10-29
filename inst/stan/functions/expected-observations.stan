// Calculate expected observations
// 
// Calculate expected observations over time from a combination of final
// expected observations, the probability of reporting on a given day effects
// that occured the reference day (or alternatively the logit hazard of this),
// and the hazard of reporting on a given day given reporting day effects. 
// 
// @param tar_obs The final expected observations that will be reported for
// a given date.
// 
// @param ref_lh A vector of conditional probabilities a report occurs on a
// given day. Designed to take a input based on when the observation occurred.
// Optionally when ref_as_p = 0 this should be transformed first into the logit
// hazard.
// 
// @param rep_lh A vector of logit hazards (i.e conditional probabilities) 
// for day of report effects
// 
// @param ref_as_p Logical (0/1), should the reference date input be treated as 
// a probability. Useful when no report date effects are present.
// @return A vector of expected observations for a given date by date of report
// 
// @examples
// # compile function for use in R
// source(here::here("R", "utils.R"))
// expose_stan_fns(c("hazard.stan", "expected-observations.stan"),
//                 "stan/functions")
//
// tar_obs <- 1
// date_p <- (plnorm(1:30, 1.5, 2) - plnorm(0:29, 1.5, 2)) / plnorm(30, 1.5, 2)
// rep_lh <- rep(0, 30)
//
// Example with no reporting day effect
// eobs <- expected_obs(tar_obs, date_p, rep(0, 30), 1)
// all.equal(eobs - 1e-4, date_p)
//
// Example with hazard effect only on last day of report
// ref_lh <- logit(prob_to_hazard(date_p))
// eobs <- expected_obs(tar_obs, ref_lh, c(rep(0, 29), 0.1), 0)
// all.equal(eobs - 1e-4, date_p)
//
// Example with a single day of additional reporting hazard and
// no differential probability due to the reference date.
// rep_lh <- rep(0, 30); rep_lh[7] = 2
// equal_lh <- logit(prob_to_hazard(rep(1/30, 30)))
// round(expected_obs(tar_obs, equal_lh, rep_lh, 0), 3)
// # 0.033 0.033 0.033 0.033 0.033 0.033 0.195 0.026 0.026 0.026 0.026 0.026
// # 0.026 0.026 0.026 0.026 0.026 0.026 0.026 0.026 0.026 0.026 0.026 0.026
// # 0.026 0.026 0.026 0.026 0.026 0.026
//
// Example combining multiple hazards and no differential prob due to reference
// date
// rep_lh <- rep(0, 30)
// rep_lh[c(6, 12, 16)] = 2
// rep_lh[c(2, 20)] = -2
// round(expected_obs(tar_obs, equal_lh, rep_lh, 0), 3)
// # 0.033 0.005 0.034 0.034 0.034 0.202 0.027 0.027 0.027 0.027 0.027 0.151
// # 0.021 0.021 0.021 0.106 0.014 0.014 0.014 0.002 0.016 0.016 0.016 0.016
// # 0.016 0.016 0.016 0.016 0.016 0.016
//
// Example combining both date of reference and date of report effects
// eobs <- expected_obs(tar_obs, ref_lh , rep_lh, 0)
// round(sum(eobs - 1e-4), 5) == 1
// round(eobs, 3)
// # 0.273 0.023 0.112 0.082 0.065 0.221 0.025 0.021 0.019 0.016 0.014 0.058
// # 0.007 0.007 0.006 0.024 0.003 0.003 0.003 0.000 0.003 0.002 0.002 0.002
// # 0.002 0.002 0.002 0.002 0.002 0.002
vector expected_obs(real tar_obs, vector ref_lh, vector rep_lh, int ref_as_p) {
  int t = num_elements(ref_lh);
  vector[t] exp_obs;
  if (ref_as_p == 1) {
    exp_obs = tar_obs * ref_lh + 1e-4;
  }else{
    vector[t] p;
    p = inv_logit(ref_lh + rep_lh);
    p = hazard_to_prob(p);
    exp_obs = tar_obs * p + 1e-4;
  }
  return(exp_obs);
}

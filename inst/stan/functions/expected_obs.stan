/**
 * Calculate expected observations on the log scale
 * 
 * Computes expected observations over time based on final expected
 * observations and reporting probabilities. It handles both probabilities and
 * logit hazards for reporting on each day.
 * 
 * @param tar_obs The logarithm of the final expected observations for a given
 * date. It should be a real number representing logged observations.
 * 
 * @param lh A vector of conditional log probabilities of a report occurring on
 * a given day. When `ref_as_p` is 0, this should be the logit hazard instead
 * of probability.
 * 
 * @param ref_as_p An integer flag (0 or 1) indicating whether the reference date input should be treated as a logit hazard or probability. Set to 1 when
 * no report date effects are present, otherwise 0.
 *
 * @param agg_probs An integer flag (0 or 1) indicating whether the reporting probabilities should be aggregated. Set to 1 when the probabilities should be aggregated, otherwise 0.
 *
 * @param agg_indicator A matrix of integer flags (0 or 1) representing the aggregation of reporting probabilities,
 * designed to be left-multiplied to a column vector of reporting probabilities. 
 * Presence of a 1 in a column indicates that that index in the probability column vector will be aggregated,
 * and presence of a 1 in a row indicates that aggregated probability will be placed on that index in the new probability vector.
 * 
 * @return A vector representing the expected observations for each date by
 * date of report. The length of the vector matches the length of `lh`.
 * 
 * @note
 * Dependencies:
 * - `inv_logit`: Used to convert logit hazards to probabilities.
 * - `hazard_to_log_prob`: Used for converting hazards to log probabilities.
 *
 * @examples
 * # compile function for use in R
 * source(here::here("R", "utils.R"))
 * enw_stan_to_r(c("hazard.stan", "expected_obs.stan"),
 *                 "inst/stan/functions")
 *
 * tar_obs <- log(1)
 * date_p <- log(
 *  plnorm(1:30, 1.5, 2) - plnorm(0:29, 1.5, 2)) / plnorm(30, 1.5, 2)
 * )
 * rep_lh <- rep(0, 30)
 *
 * Example with no reporting day effect
 * eobs <- exp(expected_obs(tar_obs, date_p + rep(0, 30), 1, 0, [0]))
 * all.equal(eobs, date_p)
 *
 * Example with hazard effect only on last date of report
 * ref_lh <- logit(hazard_to_log_prob(date_p))
 * eobs <- exp(expected_obs(tar_obs, ref_lh, c(rep(0, 29), 0.1), 0, 0, [0]))
 * all.equal(eobs, date_p)
 *
 * Example with a single day of additional reporting hazard and
 * no differential probability due to the reference date.
 * rep_lh <- rep(0, 30); rep_lh[7] = 2
 * equal_lh <- logit(hazard_to_log_prob(rep(1/30, 30)))
 * round(exp(expected_obs(tar_obs, equal_lh + rep_lh, 0, 0, [0])), 3)
 * # 0.033 0.033 0.033 0.033 0.033 0.033 0.195 0.026 0.026 0.026 0.026 0.026
 * # 0.026 0.026 0.026 0.026 0.026 0.026 0.026 0.026 0.026 0.026 0.026 0.026
 * # 0.026 0.026 0.026 0.026 0.026 0.026
 *
 * Example combining multiple hazards and no differential prob due to reference
 * date
 * rep_lh <- rep(0, 30)
 * rep_lh[c(6, 12, 16)] = 2
 * rep_lh[c(2, 20)] = -2
 * round(exp(expected_obs(tar_obs, equal_lh + rep_lh, 0, 0, [0])), 3)
 * # 0.033 0.005 0.034 0.034 0.034 0.202 0.027 0.027 0.027 0.027 0.027 0.151
 * # 0.021 0.021 0.021 0.106 0.014 0.014 0.014 0.002 0.016 0.016 0.016 0.016
 * # 0.016 0.016 0.016 0.016 0.016 0.016
 *
 * Example combining both date of reference and date of report effects
 * eobs <- exp(expected_obs(tar_obs, ref_lh + rep_lh, 0, 0, [0]))
 * round(sum(eobs - 1e-4), 5) == 1
 * round(eobs, 3)
 * # 0.273 0.023 0.112 0.082 0.065 0.221 0.025 0.021 0.019 0.016 0.014 0.058
 * # 0.007 0.007 0.006 0.024 0.003 0.003 0.003 0.000 0.003 0.002 0.002 0.002
 * # 0.002 0.002 0.002 0.002 0.002 0.002
 *
 * Example with aggregation of probabilities where aggregation occurs on every fifth day
 * agg_probs <- matrix(c(rep(0, times = 30 * 4),
 *                       rep(c(rep(1, times = 5),
 *                             rep(0, times = 6 * 5 + 30 * 4)),
 *                           times = 5),
 *                       rep(1, times = 5)), ncol = 30, byrow = TRUE)
 * eobs <- exp(expected_obs(tar_obs, date_p + rep(0, 30), 1, 1, agg_probs))
 * # -Inf -Inf -Inf -Inf -0.4630154 -Inf -Inf -Inf -Inf -1.8219081
 * # -Inf -Inf -Inf -Inf -2.4549990 -Inf -Inf -Inf -Inf -2.8994851
 * # -Inf -Inf -Inf -Inf -3.2477183 -Inf -Inf -Inf -Inf -3.5362414
 * # Can visualize what this does to the probabilities with
 * eobs |> exp() |> plot()
 */
vector expected_obs(real tar_obs, vector lh, int ref_as_p, int agg_probs, matrix agg_indicator) {
  int t = num_elements(lh);
  vector[t] exp_obs;
  vector[t] p;
  if (ref_as_p == 1) {
    p = lh;
  }else{
    profile("model_likelihood_expected_obs_inv_logit") {
    p = inv_logit(lh);
    }
    profile("model_likelihood_expected_obs_hazard_to_prob") {
    p = hazard_to_log_prob(p);
    }
  }
  if (agg_probs == 1) {
    p = log(agg_indicator * exp(p));
  }
  profile("model_likelihood_expected_obs_prod_p") {
    exp_obs = tar_obs + p;
    }
  return(exp_obs);
}

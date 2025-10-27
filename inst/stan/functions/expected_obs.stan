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
 * @param l Length of the vector lh.
 * 
 * @param ref_as_p An integer flag (0 or 1) indicating whether the reference date input should be treated as a logit hazard or probability. Set to 1 when
 * no report date effects are present, otherwise 0.
 *
 * @param rep_agg_p An integer flag (0 or 1) indicating whether the reporting probabilities should be aggregated. Set to 1 when the probabilities should be aggregated, otherwise 0.
 *
 * @param n_selected Array of counts of selected indices per row
 *
 * @param selected_idx Array of column indices for aggregation
 * 
 * @return A vector representing the expected observations for each date by
 * date of report. The length of the vector matches the length of `lh`.
 * 
 * @note
 * Dependencies:
 * - `inv_logit`: Used to convert logit hazards to probabilities.
 * - `hazard_to_log_prob`: Used for converting hazards to log probabilities.
 *
 * @code
 * # compile function for use in R
 * source(here::here("R", "utils.R"))
 * enw_stan_to_r(c("hazard.stan", "expected_obs.stan"),
 *                 "inst/stan/functions")
 *
 * tar_obs <- log(1)
 * date_p <- log(
 *   (plnorm(1:30, 1.5, 2) - plnorm(0:29, 1.5, 2)) / plnorm(30, 1.5, 2)
 * )
 * rep_lh <- rep(0, 30)
 *
 * Example with no reporting day effect
 * eobs <- exp(expected_obs(
 *   tar_obs, date_p + rep(0, 30), 30, 1, 0, matrix(0, nrow = 0, ncol = 0)
 * ))
 *
 * Example with hazard effect only on last date of report
 * ref_lh <- qlogis(prob_to_hazard(exp(date_p)))
 * eobs <- exp(
 *   expected_obs(
 *     tar_obs, ref_lh, 30, 0, 0,
 *     matrix(numeric(0), nrow = 0, ncol = 0)
 *   )
 * )
 *
 * Example with a single day of additional reporting hazard
 * rep_lh <- rep(0, 30)
 * rep_lh[7] <- 2
 * equal_lh <- plogis(hazard_to_log_prob(rep(1/30, 30), 30))
 * eobs <- round(exp(
 *   expected_obs(
 *     tar_obs, equal_lh + rep_lh, 30, 0, 0,
 *     matrix(numeric(0), nrow = 0, ncol = 0)
 *   )
 * ), 3)
 * expected <- c(0.508, 0.250, 0.123, 0.060, 0.030, 0.015, 0.013, 0.001)
 *
 * Example combining multiple hazards and no differential prob due to reference
 * date
 * rep_lh <- rep(0, 30)
 * rep_lh[c(6, 12, 16)] <- 2
 * rep_lh[c(2, 20)] <- -2
 * equal_lh <- plogis(hazard_to_log_prob(rep(1 / 30, 30), 30))
 * eobs <- round(exp(
 *   expected_obs(
 *     tar_obs, equal_lh + rep_lh, 30, 0, 0,
 *     matrix(numeric(0), nrow = 0, ncol = 0)
 *   )
 * ), 3)
 * expected <- c(0.508, 0.060, 0.219, 0.108, 0.053, 0.046, 0.003, 0.002, 0.001,
 *               rep(0.000, 21))
 *
 * Example with aggregation of probabilities where aggregation occurs on every fifth day
 * rep_agg_p <- matrix(c(rep(0, times = 30 * 4),
 *                       rep(c(rep(1, times = 5),
 *                             rep(0, times = 6 * 5 + 30 * 4)),
 *                           times = 5),
 *                       rep(1, times = 5)), ncol = 30, byrow = TRUE)
 * eobs <- exp(expected_obs(tar_obs, date_p + rep(0, 30), 30, 1, 1, rep_agg_p))
 * # -Inf -Inf -Inf -Inf -0.4630154 -Inf -Inf -Inf -Inf -1.8219081
 * # -Inf -Inf -Inf -Inf -2.4549990 -Inf -Inf -Inf -Inf -2.8994851
 * # -Inf -Inf -Inf -Inf -3.2477183 -Inf -Inf -Inf -Inf -3.5362414
 * # Can visualize what this does to the probabilities with
 * eobs |> exp() |> plot()
 * @endcode
 */
vector expected_obs(
  real tar_obs, vector lh, int l, int ref_as_p, int rep_agg_p,
  array[] int n_selected, array[,] int selected_idx
) {
  vector[l] p;
  if (ref_as_p == 1) {
    p = lh;
  }else{
    profile("model_likelihood_expected_obs_inv_logit") {
    p = inv_logit(lh);
    }
    profile("model_likelihood_expected_obs_hazard_to_prob") {
    p = hazard_to_log_prob(p, l);
    }
  }
  if (rep_agg_p == 1) {
    vector[l] p_aggregated = rep_vector(negative_infinity(), l);
    for (i in 1:l) {
      if (n_selected[i] > 0) {
        p_aggregated[i] = log_sum_exp(p[selected_idx[i, 1:n_selected[i]]]);
      }
    }
    p = p_aggregated;
  }
  return(tar_obs + p);
}

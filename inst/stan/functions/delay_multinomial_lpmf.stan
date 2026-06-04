/**
 * (Truncated) multinomial delay-only likelihood for one snapshot
 *
 * Computes the conditional log probability of the observed reporting-delay
 * cells of a single reference date given their total, treating the total as
 * fixed truth. This is the delay-only likelihood of Kalbfleisch & Lawless
 * (1989) and Hoehle & an der Heiden (2014): the cell counts follow a
 * multinomial whose probabilities are the reporting-delay PMF renormalised
 * over the observed delay range.
 *
 * When every delay cell of a reference date is observed this is the plain
 * multinomial (issue #775). When only delays up to the observation horizon
 * `T - t` are observed the renormalisation divides by `F(T - t)`, the delay
 * CDF over the observed range, giving the truncated multinomial (issue #776).
 * The renormalisation falls out of subtracting `log_sum_exp` of the cell
 * log-intensities, so the same code covers both cases and the supplied total
 * enters only through the cells (which sum to it).
 *
 * @param obs Observed cell counts for the snapshot (one per observed delay).
 *
 * @param log_exp_obs Log expected cell counts for the snapshot, i.e.
 * `log(total) + log(p_d)` as returned by `expected_obs_from_snaps`. The
 * `log(total)` offset is constant across the cells and cancels in the
 * renormalisation, so only the relative delay intensities matter.
 *
 * @return Log probability mass of the cells under the (truncated) multinomial.
 *
 * @note Vectorised: a single `log_softmax` and `multinomial_logit_lpmf` per
 * snapshot, no per-cell loop.
 */
real delay_multinomial_lpmf(array[] int obs, vector log_exp_obs) {
  // Renormalise the delay intensities to a simplex over the observed cells.
  // log_softmax subtracts log_sum_exp(log_exp_obs); the shared log(total)
  // offset cancels, leaving the (truncated) delay PMF on the log scale.
  return multinomial_logit_lpmf(obs | log_softmax(log_exp_obs));
}

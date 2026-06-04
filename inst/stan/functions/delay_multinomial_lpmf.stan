/**
 * (Truncated) multinomial delay-only likelihood for one snapshot
 *
 * Conditional log probability of a reference date's observed delay cells
 * given their total. Renormalising the delay intensities over the observed
 * cells gives the plain multinomial when the row is complete and the
 * truncated multinomial when only early delays are observed. The shared
 * log(total) offset cancels, so the total enters only through the cells.
 *
 * @param obs Observed cell counts (one per observed delay).
 * @param log_exp_obs Log expected cells, `log(total) + log(p_d)`.
 * @return Log probability mass under the (truncated) multinomial.
 */
real delay_multinomial_lpmf(array[] int obs, vector log_exp_obs) {
  return multinomial_logit_lpmf(obs | log_softmax(log_exp_obs));
}

/**
 * Delay-only multinomial likelihood over a range of snapshots
 *
 * Sums `delay_multinomial_lpmf` over each snapshot in a range, treating its
 * observed cells as one (truncated) multinomial conditional on the total.
 * `nsl`/`cnsl` and `obs_lookup` select the observed cells, so an observation
 * indicator (gaps in the triangle) renormalises over exactly the observed
 * delays. With no indicator `nsl == sl` and this is the full row.
 *
 * @param start First snapshot in the range.
 * @param end Last snapshot in the range.
 * @param obs Flat observed cell counts.
 * @param log_exp_obs Gap-filled log expected cells for the range.
 * @param exp_offset Flat index of the first gap-filled cell of the range.
 * @param obs_lookup Maps each observed cell to its gap-filled position.
 * @param nsl Observed cells per snapshot.
 * @param cnsl Cumulative `nsl`.
 *
 * @return Summed log probability mass over the snapshots.
 */
real delay_multinomial_snaps(int start, int end, array[] int obs,
                             vector log_exp_obs, int exp_offset,
                             array[] int obs_lookup,
                             array[] int nsl, array[] int cnsl) {
  real tar = 0;
  for (i in start:end) {
    if (nsl[i]) {
      array[3] int o = filt_obs_indexes(i, i, cnsl, nsl);
      array[nsl[i]] int cells = segment(obs, o[1], nsl[i]);
      vector[nsl[i]] lexp;
      for (j in 1:nsl[i]) {
        lexp[j] = log_exp_obs[obs_lookup[o[1] + j - 1] - exp_offset + 1];
      }
      tar += delay_multinomial_lpmf(cells | lexp);
    }
  }
  return tar;
}

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
 * Sums a (truncated) multinomial over each snapshot, conditioning on the
 * known total. The delay probabilities are renormalised over every slot up
 * to the observation cutoff (`lsl`), so interior cells that are unobserved
 * but before the cutoff keep their weight; only right-truncated slots beyond
 * the cutoff are excluded. With an observation indicator the unobserved
 * before-cutoff cells are marginalised into a single residual category whose
 * count is the known total minus the observed counts, leaving the observed
 * cells plus that residual as the multinomial categories.
 *
 * @param start First snapshot in the range.
 * @param end Last snapshot in the range.
 * @param obs Flat observed cell counts.
 * @param log_exp_obs Gap-filled log expected cells over the cutoff range.
 * @param exp_offset Flat index of the first cutoff cell of the range.
 * @param total Known integer total by snapshot (the cutoff running total).
 * @param obs_lookup Maps each observed cell to its cutoff-block position.
 * @param lsl Cutoff slots per snapshot (max consecutive observed + 1).
 * @param clsl Cumulative `lsl`.
 * @param nsl Observed cells per snapshot.
 * @param cnsl Cumulative `nsl`.
 *
 * @return Summed log probability mass over the snapshots.
 */
real delay_multinomial_snaps(int start, int end, array[] int obs,
                             vector log_exp_obs, int exp_offset,
                             array[] int total, array[] int obs_lookup,
                             array[] int lsl, array[] int clsl,
                             array[] int nsl, array[] int cnsl) {
  real tar = 0;
  for (i in start:end) {
    if (lsl[i]) {
      // Cutoff block of expected cells; renormalise over all slots up to the
      // cutoff (log_softmax) so before-cutoff interior cells keep weight.
      array[3] int c = filt_obs_indexes(i, i, clsl, lsl);
      vector[lsl[i]] lprob = log_softmax(
        segment(log_exp_obs, c[1] - exp_offset + 1, lsl[i])
      );
      array[3] int o = filt_obs_indexes(i, i, cnsl, nsl);
      if (nsl[i] == lsl[i]) {
        // Fully observed up to the cutoff: plain (truncated) multinomial.
        tar += multinomial_lpmf(segment(obs, o[1], nsl[i]) | exp(lprob));
      } else {
        // Some before-cutoff cells unobserved: marginalise them into one
        // residual category (count = total - observed, prob = 1 - observed).
        vector[nsl[i] + 1] cat_lprob;
        array[nsl[i] + 1] int cat_obs;
        int obs_sum = 0;
        for (j in 1:nsl[i]) {
          int local = obs_lookup[o[1] + j - 1] - c[1] + 1;
          cat_lprob[j] = lprob[local];
          cat_obs[j] = obs[o[1] + j - 1];
          obs_sum += cat_obs[j];
        }
        // Residual probability = 1 - sum(observed probs), on the log scale.
        cat_lprob[nsl[i] + 1] = log1m_exp(log_sum_exp(cat_lprob[1:nsl[i]]));
        cat_obs[nsl[i] + 1] = max(total[i] - obs_sum, 0);
        tar += multinomial_lpmf(cat_obs | exp(cat_lprob));
      }
    }
  }
  return tar;
}

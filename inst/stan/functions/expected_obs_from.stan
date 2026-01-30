/**
 * Calculate expected observations for a given index
 *
 * Computes the expected observations for a specific time index by combining
 * final observed/imputed expected observation with time effects. This function
 * integrates various hazard effects and reference adjustments to produce the
 * expected observations.
 *
 * @copydoc common_parameters_delay_lpmf_funcs
 *
 * @param i Index for accessing elements in various arrays.
 *
 * @param g Group index for data access.
 * @param t Time index for data access.
 * @param l Length parameter for data processing.
 * @param p Position parameter for data access.
 *
 * @return A vector of expected observations for the given index.
 * 
 * @note This function performs several steps:
 *       1. Retrieves the final observed/imputed expected observation for the 
 *          given group and time.
 *       2. Aggregates various hazard effects using `combine_logit_hazards`.
 *       3. Combines the final expected observation with the time-varying
 *          effects  to compute the expected observations using `expected_obs`.
 *
 * Dependencies:
 *  - `combine_logit_hazards`
 *  - `expected_obs`
 *
 */
vector expected_obs_from_index(
  int i, array[] vector imp_obs,
  array[,] int rdlurd, vector srdlh,
  matrix refp_lh, array[] int dpmfs, int ref_p,
  int rep_h, int ref_as_p, int g, int t, int l,
  vector refnp_lh, int ref_np, int p,
  int rep_agg_p,
  array[,,] int rep_agg_n_selected,
  array[,,,] int rep_agg_selected_idx
) {
  vector[l] lh;
  profile("model_likelihood_hazard_allocations") {
    lh = combine_logit_hazards(
      i, rdlurd, srdlh, refp_lh, dpmfs, ref_p, rep_h, g, t, l, refnp_lh, ref_np, p
    );
  }
  // Extract precomputed selected indices for this group/time
  array[l] int n_sel;
  array[l, l] int sel_idx;
  if (rep_agg_p == 1) {
    n_sel = rep_agg_n_selected[g, t, 1:l];
    sel_idx = rep_agg_selected_idx[g, t, 1:l, 1:l];
  }
  return expected_obs(imp_obs[g][t], lh, l, ref_as_p, rep_agg_p, n_sel, sel_idx);
}

/**
 * Calculate expected observations for a set of indexes
 *
 * Computes expected observations for a range of time indexes, effectively
 * aggregating individual calculations over a specified range. This function
 * considers various factors like hazard effects, reference adjustments, and
 * grouping to produce expected observations for each index within the range.
 *
 * @copydoc common_parameters_delay_lpmf_funcs
 *
 * @param n Number of discrete points for observations.
 *
 * @return A vector of expected observations across the specified range of
 *         indexes.
 * 
 * @note This function executes the following steps:
 *       1. Iteratively processes each index in the specified range.
 *       2. For each index, it identifies the relevant group, time, and length 
 *          parameters necessary for the calculation.
 *       3. Calls `expected_obs_from_index` for each index to compute the 
 *          expected observations.
 *       4. Aggregates these individual expected observations into a single 
 *          vector corresponding to the entire range.
 * 
 * Dependencies:
 *  - `expected_obs_from_index`
 */
vector expected_obs_from_snaps(
  int start, int end, array[] vector imp_obs,
  array[,] int rdlurd, vector srdlh,
  matrix refp_lh, array[] int dpmfs,
  int ref_p, int rep_h, int ref_as_p,
  array[] int sl, array[] int csl,
  array[] int sg, array[] int st, int n,
  vector refnp_lh, int ref_np, array[] int sdmax,
  array[] int csdmax, int rep_agg_p,
  array[,,] int rep_agg_n_selected,
  array[,,,] int rep_agg_selected_idx
) {
  vector[n] log_exp_obs;
  int ssnap = 1;
  int esnap = 0;
  int l;

  for (i in start:end) {
    l = sl[i];
    profile("expected_obs_from_index") {
    if (l) {
      esnap += l;
      log_exp_obs[ssnap:esnap] = expected_obs_from_index(
        i, imp_obs, rdlurd, srdlh, refp_lh, dpmfs, ref_p, rep_h, ref_as_p,
        sg[i], st[i], l, refnp_lh, ref_np, csdmax[i] - sdmax[i] + 1,
        rep_agg_p, rep_agg_n_selected, rep_agg_selected_idx
      );
      ssnap += l;
    }
    }
  }
  return(log_exp_obs);
}

/**
 * Batched expected observations for a set of indexes
 *
 * Pure-Stan alternative to `expected_obs_from_snaps()`. Instead of calling
 * `expected_obs_from_index()` once per snapshot in `start:end` -- each call
 * paying its own `inv_logit()`, `log1m()` and `cumulative_sum()` dispatch
 * overhead on a short, snapshot-length vector -- this builds one flat
 * logit-hazard vector spanning every snapshot in the range and converts it
 * to log probabilities with a single `inv_logit()`, a single `log1m()` and a
 * single `cumulative_sum()` over the whole batch.
 *
 * The within-snapshot hazard-to-probability recurrence
 * (`hazard_to_log_prob()`, `hazard.stan`) needs the cumulative sum of
 * `log1m(hazard)` to restart at 0 at the first delay slot of every
 * snapshot. This is reproduced here by resetting the flat, one-step-shifted
 * hazard vector to 0 at each snapshot's own start (instead of carrying over
 * the previous snapshot's last hazard), and by subtracting, from the global
 * cumulative sum, the value it held immediately before that snapshot
 * started. Because `cumulative_sum(a)[j] - cumulative_sum(a)[i]` telescopes
 * to `sum(a[(i+1):j])` regardless of what precedes index `i`, this gives
 * exactly the same per-snapshot survival term as the per-snapshot path, to
 * floating-point precision.
 *
 * `combine_logit_hazards()` is not fused into this batching: its gather
 * (`srdlh[rdlurd[g, t:(t + l - 1)]]`) is already a single vectorised Stan
 * Math call per snapshot, and fusing it would couple a general hazard-math
 * primitive to this specific hazard-source layout for no measured benefit.
 *
 * @copydoc common_parameters_delay_lpmf_funcs
 *
 * @param n Number of discrete points for observations.
 *
 * @return A vector of expected observations across the specified range of
 *         indexes, identical (to floating-point precision) to the result of
 *         `expected_obs_from_snaps()` called with the same arguments.
 *
 * If a hazard rounds to 1 before the final delay of a snapshot, the shared
 * cumulative sum becomes -Inf for the rest of the range. The function then
 * falls back to `expected_obs_from_snaps()` so that the -Inf stays within
 * that snapshot, as it does on the per-snapshot path.
 *
 * Dependencies:
 *  - `combine_logit_hazards`
 *  - `expected_obs_from_snaps`
 */
vector expected_obs_from_snaps_batched(
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

  // Retrospective mode: see `expected_obs_from_snaps()` for the rationale.
  if (ref_p == 0 && ref_np == 0 && rep_h == 0) {
    for (i in start:end) {
      log_exp_obs[i - start + 1] = imp_obs[sg[i], st[i]];
    }
    return(log_exp_obs);
  }

  int nsnaps = end - start + 1;
  // Local (chunk-relative) start/end offsets and lengths per snapshot.
  array[nsnaps] int len;
  array[nsnaps] int seg_start;
  array[nsnaps] int seg_end;
  {
    int pos = 1;
    for (k in 1:nsnaps) {
      int l = sl[start + k - 1];
      len[k] = l;
      seg_start[k] = pos;
      seg_end[k] = pos + l - 1;
      pos += l;
    }
  }

  // Build the flat logit-hazard vector. Each snapshot's slice-adds /
  // gather stay per-snapshot (see note above); only the assignment into
  // the flat vector is new relative to `expected_obs_from_snaps()`.
  vector[n] lh;
  profile("model_likelihood_hazard_allocations") {
  for (k in 1:nsnaps) {
    int i = start + k - 1;
    int l = len[k];
    if (l) {
      lh[seg_start[k]:seg_end[k]] = combine_logit_hazards(
        i, rdlurd, srdlh, refp_lh, dpmfs, ref_p, rep_h, sg[i], st[i], l,
        refnp_lh, ref_np, csdmax[i] - sdmax[i] + 1
      );
    }
  }
  }

  vector[n] p;
  if (ref_as_p == 1) {
    p = lh;
  } else {
    vector[n] h;
    int saturated = 0;
    profile("model_likelihood_expected_obs_inv_logit") {
    h = inv_logit(lh);
    }
    profile("model_likelihood_expected_obs_hazard_to_prob") {
    // One global one-step shift, reset to 0 at every snapshot start (no
    // slot-0 survival term within a snapshot).
    vector[n] shifted = n > 1 ? append_row(0.0, h[1:(n - 1)]) : h;
    for (k in 1:nsnaps) {
      if (len[k]) shifted[seg_start[k]] = 0.0;
    }
    vector[n] cs = cumulative_sum(log1m(shifted));
    // A hazard that rounds to 1 before a snapshot's final delay makes
    // log1m() return -Inf. The global cumulative sum then stays -Inf, and
    // the baseline subtraction below would turn every later snapshot into
    // NaN. A NaN hazard spreads the same way. The per-snapshot path keeps
    // either within its own snapshot, so fall back to it.
    if (n > 0) {
      saturated = is_inf(cs[n]) || is_nan(cs[n]);
    }
    // Per-snapshot baseline so the cumulative sum restarts at 0 at each
    // snapshot's own first slot.
    vector[n] base;
    for (k in 1:nsnaps) {
      if (len[k]) {
        real b = seg_start[k] > 1 ? cs[seg_start[k] - 1] : 0.0;
        base[seg_start[k]:seg_end[k]] = rep_vector(b, len[k]);
      }
    }
    p = log(h) + cs - base;
    }
    if (saturated) {
      return expected_obs_from_snaps(
        start, end, imp_obs, rdlurd, srdlh, refp_lh, dpmfs, ref_p, rep_h,
        ref_as_p, sl, csl, sg, st, n, refnp_lh, ref_np, sdmax, csdmax,
        rep_agg_p, rep_agg_n_selected, rep_agg_selected_idx
      );
    }
  }

  if (rep_agg_p == 1) {
    for (k in 1:nsnaps) {
      int i = start + k - 1;
      int l = len[k];
      if (l) {
        vector[l] p_local = segment(p, seg_start[k], l);
        array[l] int n_sel = rep_agg_n_selected[sg[i], st[i], 1:l];
        array[l, l] int sel_idx = rep_agg_selected_idx[sg[i], st[i], 1:l, 1:l];
        vector[l] p_aggregated = rep_vector(negative_infinity(), l);
        for (j in 1:l) {
          if (n_sel[j] > 0) {
            p_aggregated[j] = log_sum_exp(p_local[sel_idx[j, 1:n_sel[j]]]);
          }
        }
        p[seg_start[k]:seg_end[k]] = p_aggregated;
      }
    }
  }

  for (k in 1:nsnaps) {
    int i = start + k - 1;
    int l = len[k];
    if (l) {
      log_exp_obs[seg_start[k]:seg_end[k]] =
        imp_obs[sg[i]][st[i]] + segment(p, seg_start[k], l);
    }
  }
  return(log_exp_obs);
}

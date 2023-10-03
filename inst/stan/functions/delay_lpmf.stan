real delay_snap_lpmf(array[] int dummy, int start, int end, array[] int obs,
                     array[] int sl, array[] int csl,
                     array[] int nsl, array[] int cnsl, array[] int obs_lookup,
                     array[] vector imp_obs, array[] int sg,
                     array[] int st, array[,] int rdlurd,
                     vector srdlh, matrix refp_lh, array[] int dpmfs,
                     int ref_p, int rep_h, int ref_as_p, array[] real phi,
                     int model_obs, vector refnp_lh, int ref_np,
                     array[] int sdmax, array[] int csdmax) {
  real tar = 0;
  // Where am I in the observed data?
  array[3] int nc = filt_obs_indexes(start, end, cnsl, nsl);
  // Where am I in the observed data filling in gaps?
  array[3] int n = filt_obs_indexes(start, end, csl, sl);

  // Filter observed data and observed data lookup
  array[nc[3]] int filt_obs = segment(obs, nc[1], nc[3]);
  array[nc[3]] int filt_obs_lookup = segment(obs_lookup, nc[1], nc[3]);

  // Index lookup to start from where we currently are
  array[nc[3]] int filt_obs_local_lookup;
  for (i in 1:nc[3]) {
      filt_obs_local_lookup[i] = filt_obs_lookup[i] - n[1] + 1;
  } 

  // What is going to be used for storage
  vector[n[3]] log_exp_obs;

  // combine expected final obs and time effects to get expected obs
  log_exp_obs = expected_obs_from_snaps(
    start, end, imp_obs, rdlurd, srdlh, refp_lh, dpmfs, ref_p, rep_h, ref_as_p,
    sl, csl, sg, st, n[3], refnp_lh, ref_np, sdmax, csdmax
  );

  // observation error model (across all reference dates and groups)
  profile("model_likelihood_neg_binomial") {
  tar = obs_lpmf(
    filt_obs | log_exp_obs[filt_obs_local_lookup], phi, model_obs
  );
  }
  return(tar);
}

real delay_group_lpmf(array[] int groups, int start, int end, array[] int obs,
                      array[] int sl, array[] int csl, array[] int nsl,
                      array[] int cnsl, array[] int obs_lookup,
                      array[] vector imp_obs, int t, array[] int sg,
                      array[,] int ts, array[] int st,
                      array[,] int rdlurd, vector srdlh, matrix refp_lh,
                      array[] int dpmfs, int ref_p, int rep_h, int ref_as_p,
                      array[] real phi, int model_obs, int model_miss,
                      int miss_obs, array[] int missing_reference,
                      array[,] int obs_by_report, vector miss_ref_lprop,
                      array[] int sdmax, array[] int csdmax,
                      array[] int miss_st, array[] int miss_cst,
                      vector refnp_lh, int ref_np) {
  // Where am I?
  real tar = 0;
  int i_start = ts[1, start];
  int i_end = ts[t, end];
  // Where am I in the observed data?
  array[3] int nc = filt_obs_indexes(i_start, i_end, cnsl, nsl);
  // Where am I in the observed data filling in gaps?
  array[3] int n = filt_obs_indexes(i_start, i_end, csl, sl);

  // Filter observed data and observed data lookup
  array[nc[3]] int filt_obs = segment(obs, nc[1], nc[3]);
  array[nc[3]] int filt_obs_lookup = segment(obs_lookup, nc[1], nc[3]);
  
  // Index lookup to start from where we currently are
  array[nc[3]] int filt_obs_local_lookup;
  for (i in 1:nc[3]) {
    filt_obs_local_lookup[i] = filt_obs_lookup[i] - n[1] + 1;
  } 

  // What is going to be used for storage
  vector[n[3]] log_exp_obs;
  vector[model_miss ? miss_obs : 0]  log_exp_obs_miss;

  // Combine expected final obs and time effects to get expected obs
  // If missing reference module in place calculate all expected obs vs 
  // just those observed and allocate if missing or not.
  if (model_miss) {
    array[3] int f = filt_obs_indexes(i_start, i_end, csdmax, sdmax);
    array[3] int l = filt_obs_indexes(start, end, miss_cst, miss_st);
    vector[f[3]] log_exp_all;

    // Calculate all expected observations
    log_exp_all = expected_obs_from_snaps(
      i_start, i_end, imp_obs, rdlurd, srdlh, refp_lh, dpmfs, ref_p, rep_h, ref_as_p, sdmax, csdmax, sg, st, f[3], refnp_lh, ref_np, sdmax, csdmax
    );

    // Allocate to just those actually observed
    log_exp_obs = allocate_observed_obs(
      i_start, i_end, log_exp_all, sl, csl, sdmax, csdmax
    );
    log_exp_obs = apply_missing_reference_effects(
      i_start, i_end, log_exp_obs, sl, csl, log1m_exp(miss_ref_lprop)
    );

    // Allocate expected cases by reporting time
    if (miss_obs) {
      log_exp_all = apply_missing_reference_effects(
        i_start, i_end, log_exp_all, sdmax, csdmax, miss_ref_lprop
      );
      log_exp_obs_miss = log_expected_by_report(
        log_exp_all, obs_by_report[l[1]:l[2]]
      );
    }
  }else{
    log_exp_obs = expected_obs_from_snaps(
      i_start, i_end, imp_obs, rdlurd, srdlh, refp_lh, dpmfs, ref_p, rep_h, ref_as_p, sl, csl, sg, st, n[3], refnp_lh, ref_np, sdmax, csdmax
    );
  }
  // Observation error model (across all reference dates and groups)
  profile("model_likelihood_neg_binomial") {
  tar = obs_lpmf(
    filt_obs | log_exp_obs[filt_obs_local_lookup], phi, model_obs
  );
  if (model_miss && miss_obs) {
    array[3] int l = filt_obs_indexes(start, end, miss_cst, miss_st);
    array[l[3]] int filt_miss_ref = segment(missing_reference, l[1], l[3]);
    tar += obs_lpmf(filt_miss_ref | log_exp_obs_miss, phi, model_obs);
  }
  }
  return(tar);
}

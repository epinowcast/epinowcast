real delay_snap_lpmf(array[] int dummy, int start, int end, array[] int obs,
                     array[] int sl, array[] int csl, array[] vector imp_obs,
                     array[] int sg, array[] int st, array[,] int rdlurd, vector srdlh, matrix refp_lh, array[] int dpmfs, int ref_p,
                     int rep_h, int ref_as_p, array[] real phi, int model_obs,
                     vector refnp_lh, int ref_np) {
  real tar = 0;
  // Where am I?
  array[3] int n = filt_obs_indexes(start, end, csl, sl);
  array[n[3]] int filt_obs = segment(obs, n[1], n[3]);
  vector[n[3]] filt_refnp_lh = segment(refnp_lh, n[1], n[3]);

  // What is going to be used for storage
  vector[n[3]] log_exp_obs;

  // combine expected final obs and time effects to get expected obs
  log_exp_obs = expected_obs_from_snaps(
    start, end, imp_obs, rdlurd, srdlh, refp_lh, dpmfs, ref_p, rep_h, ref_as_p,
    sl, csl, sg, st, n[3], filt_refnp_lh, ref_np
  );

  // observation error model (across all reference dates and groups)
  profile("model_likelihood_neg_binomial") {
  tar = obs_lpmf(filt_obs | log_exp_obs, phi, model_obs);
  }
  return(tar);
}

real delay_group_lpmf(array[] int groups, int start, int end, array[] int obs,
                      array[] int sl, array[] int csl, array[] vector imp_obs,
                      int t, array[] int sg, array[,] int ts, array[] int st,
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
  array[3] int n = filt_obs_indexes(i_start, i_end, csl, sl);
  array[n[3]] int filt_obs = segment(obs, n[1], n[3]);
  vector[n[3]] filt_refnp_lh = segment(refnp_lh, n[1], n[3]);

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
      i_start, i_end, imp_obs, rdlurd, srdlh, refp_lh, dpmfs, ref_p, rep_h, ref_as_p, sdmax, csdmax, sg, st, f[3], filt_refnp_lh, ref_np
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
      i_start, i_end, imp_obs, rdlurd, srdlh, refp_lh, dpmfs, ref_p, rep_h, ref_as_p, sl, csl, sg, st, n[3], filt_refnp_lh, ref_np
    );
  }
  // Observation error model (across all reference dates and groups)
  profile("model_likelihood_neg_binomial") {
  tar = obs_lpmf(filt_obs | log_exp_obs, phi, model_obs);
  if (model_miss && miss_obs) {
    array[3] int l = filt_obs_indexes(start, end, miss_cst, miss_st);
    array[l[3]] int filt_miss_ref = segment(missing_reference, l[1], l[3]);
    tar += obs_lpmf(filt_miss_ref | log_exp_obs_miss, phi, model_obs);
  }
  }
  return(tar);
}

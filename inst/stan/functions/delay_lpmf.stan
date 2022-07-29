real delay_snap_lpmf(array[] int dummy, int start, int end, array[] int obs,
                     array[] int sl, array[] int csl, array[] vector imp_obs,
                     array[] int sg, array[] int st, array[,] int rdlurd, vector srdlh, matrix ref_lh, array[] int dpmfs, int ref_p,
                     int rep_h, int ref_as_p, array[] real phi, int model_obs) {
  real tar = 0;
  // Where am I?
  array[3] int n = filt_obs_indexes(start, end, csl, sl);
  array[n[3]] int filt_obs = obs[(n[1] + 1):n[2]];
  vector[n[3]] log_exp_obs;

  // combine expected final obs and date effects to get expected obs
  log_exp_obs = expected_obs_from_snaps(
    start, end, imp_obs, rdlurd, srdlh, ref_lh, dpmfs, ref_p, rep_h, ref_as_p,
    sl, csl, sg, st, n[3]
  );

  // observation error model (across all reference times and groups)
  profile("model_likelihood_neg_binomial") {
  tar = obs_lpmf(filt_obs | log_exp_obs, phi, model_obs);
  }
  return(tar);
}

real delay_group_lpmf(array[] int groups, int start, int end, array[] int obs,
                      array[] int sl, array[] int csl, array[] vector imp_obs,
                      int t, array[] int sg, array[,] int ts, array[] int st,
                      array[,] int rdlurd, vector srdlh, matrix ref_lh,
                      array[] int dpmfs, int ref_p, int rep_h, int ref_as_p,
                      array[] real phi, int model_obs, int model_miss) {
  // For missing model
  // Passing in missing prop
  // Pass in missing obs
  // Make model optional
  // need to know which report date data is linked (i.e we need a new vector
  // look-up) by group
  // sum by this look-up to get cases by report date and group (can also make
  // this a matrix)
  // scale all data by missing proportion or 1 minus missing proportion
  
  // Where am I?
  real tar = 0;
  int i_start = ts[1, start];
  int i_end = ts[t, end];
  array[3] int n = filt_obs_indexes(i_start, i_end, csl, sl);
  array[n[3]] int filt_obs = obs[(n[1] + 1):n[2]];
  vector[n[3]] log_exp_obs;

  // Combine expected final obs and date effects to get expected obs
  log_exp_obs = expected_obs_from_snaps(
    i_start, i_end, imp_obs, rdlurd, srdlh, ref_lh, dpmfs, ref_p, rep_h, ref_as_p, sl, csl, sg, st, n[3]
  );

  // Observation error model (across all reference times and groups)
  profile("model_likelihood_neg_binomial") {
  tar = obs_lpmf(filt_obs | log_exp_obs, phi, model_obs);
  }
  return(tar);
}

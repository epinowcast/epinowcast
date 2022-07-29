array[] int filter_obs(array[] int obs, int start, int end,
                       array[] int csl, array[] int sl) {
  int start_n = csl[start] - sl[start];
  int end_n = csl[end];
  int n = end_n - start_n;
  array[n] filt_obs = obs[(start_n + 1):end_n];
  return(filt_obs);
}

real delay_snap_lpmf(array[] int dummy, int start, int end, array[] int obs,
                     array[] int sl, array[] int csl, array[] vector imp_obs,
                     array[] int sg, array[] int st, array[,] int rdlurd, vector srdlh,
                     matrix ref_lh, array[] int dpmfs, int ref_p, int rep_h,
                     int ref_as_p, array[] real phi, int model_obs) {
  real tar = 0;
  array[n] int snap_obs = filt_obs(obs, start, end, csl, sl);
  int n = num_elements(snap_obs);
  vector[n] log_exp_obs;
  int g;
  int t;
  int l;
  int ssnap = 1;
  int esnap = 0;

  for (i in start:end) {
    profile("model_likelihood_allocations") {
    g = sg[i];
    t = st[i];
    l = sl[i];
    }
    // combine expected final obs and date effects to get expected obs
    profile("model_likelihood_expected_obs_from_index") {
    esnap += l;
    log_exp_obs[ssnap:esnap] = expected_obs_from_index(
      i, imp_obs, rdlurd, srdlh, ref_lh, dpmfs, ref_p, rep_h, ref_as_p, g, t, l
    );
    ssnap += l;
    }
  }
  // observation error model (across all reference times and groups)
  profile("model_likelihood_neg_binomial") {
  tar = obs_lpmf(snap_obs | log_exp_obs, phi, model_obs);
  }
  return(tar);
}

real delay_group_lpmf(array[] int groups, int start, int end, array[] int obs,
                      array[] int sl, array[] int csl, array[] vector imp_obs,
                      int t, array[,] int ts, array[] int st,
                      array[,] int rdlurd, vector srdlh, matrix ref_lh,
                      array[] int dpmfs, int ref_p, int rep_h, int ref_as_p,
                      array[] real phi, int model_obs, int model_miss) {
  real tar = 0;
  array[n] int snap_obs = filt_obs(obs, ts[1, start], ts[t, end], csl, sl);
  int n = num_elements(snap_obs);
  vector[n] log_exp_obs;
  int i;
  int l;
  int ssnap = 1;
  int esnap = 0;

  for (g in start:end) {
    for (s in 1:t) {
      profile("model_likelihood_allocations") {
      i = ts[s, g];
      l = sl[i];
      }
      // combine expected final obs and date effects to get expected obs
      profile("model_likelihood_expected_obs_from_index") {
      esnap += l;
      log_exp_obs[ssnap:esnap] = expected_obs_from_index(
        i, imp_obs, rdlurd, srdlh, ref_lh, dpmfs, ref_p, rep_h, ref_as_p, g, t, l
      );
      ssnap += l;
      }
    }
  }
  // observation error model (across all reference times and groups)
  profile("model_likelihood_neg_binomial") {
  tar = obs_lpmf(snap_obs | log_exp_obs, phi, model_obs);
  }
  return(tar);
}

real delay_lpmf(array[] int dummy, int start, int end, array[] int obs,
                array[] int sl, array[] int csl, array[] vector imp_obs,
                array[] int sg, array[] int st, array[,] int rdlurd, vector srdlh,
                matrix ref_lh, array[] int dpmfs, int ref_p, int rep_h,
                int ref_as_p, array[] real phi, int model_obs) {
  real tar = 0;
  int start_n = csl[start] - sl[start];
  int end_n = csl[end];
  int n = end_n - start_n;
  array[n] int snap_obs = obs[(start_n + 1):end_n];
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

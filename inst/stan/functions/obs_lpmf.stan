real obs_lpmf(array[] int dummy, int start, int end, array[] int obs,
              array[] int sl, array[] int csl, array[] vector imp_obs,
              array[] int sg, array[] int st, array[,] int rdlurd, vector srdlh,
              matrix ref_lh, array[] int dpmfs, int ref_p, real phi) {
  real tar = 0;
  real tar_obs;
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
  vector[l] rdlh;
  vector[l] ref_lh_i;

  for (i in start:end) {
    profile("model_likelihood_allocations") {
    g = sg[i];
    t = st[i];
    l = sl[i];
    }
    profile("model_likelihood_allocations") {
    // Find final observed/imputed expected observation
    tar_obs = imp_obs[g][t];
    // allocate reference day effects
    ref_lh_i = ref_lh[1:l, dpmfs[i]];
    // allocate report day effects
    rdlh = srdlh[rdlurd[t:(t + l - 1), g]];
    }
    // combine expected final obs and date effects to get expected obs
    profile("model_likelihood_expected_obs") {
    esnap += l;
    log_exp_obs[ssnap:esnap] = expected_obs(
      tar_obs, ref_lh_i, rdlh, ref_p
    );
    ssnap += l;
    }
  }
  // observation error model (across all reference times and groups)
  profile("model_likelihood_neg_binomial") {
  tar = neg_binomial_2_log_lupmf(snap_obs | log_exp_obs, phi);
  }
  return(tar);
}

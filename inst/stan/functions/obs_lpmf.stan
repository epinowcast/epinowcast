real obs_lpmf(int[] dummy, int start, int end, int[] obs, int[] sl, int[] csl,
              vector[] imp_obs, int[] sg, int[] st, int[,] rdlurd,
              vector srdlh, matrix ref_lh, int[] dpmfs, int ref_p, real phi) {
  real tar = 0;
  real tar_obs;
  int init_cl = sl[start];
  int start_n = csl[start] - sl[start];
  int end_n = csl[end];
  int n = end_n - start_n;
  int snap_obs[n] = obs[(start_n + 1):end_n];
  vector[n] exp_obs;
  int start_snap, g, t, l;

  for (i in start:end) {
    g = sg[i];
    t = st[i];
    l = sl[i];
    start_snap = csl[i] - start_n - l;
    vector[l] exp_obs_by_rep;
    vector[l] rdlh;
    // Find final observed/imputed expected observation
    tar_obs = imp_obs[g][t];
    // allocate report day effects
    rdlh = srdlh[rdlurd[t:(t + l - 1), g]];
    // combine expected final obs and date effects to get expected obs
    exp_obs_by_rep = expected_obs(tar_obs, ref_lh[1:l, dpmfs[i]], rdlh, ref_p);
    exp_obs[(start_snap + 1):(start_snap + l)] = exp_obs_by_rep;
  }
  // observation error model (across all reference times and groups)
  tar = neg_binomial_2_lupmf(snap_obs | exp_obs, phi);
  return(tar);
}

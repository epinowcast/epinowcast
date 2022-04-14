real obs_lpmf(int[] dummy, int start, int end, int[] obs, int[] sl, int[] csl,
              vector[] imp_obs, int[] sg, int[] st, int[,] rdlurd,
              vector srdlh, matrix ref_lh, int[] dpmfs, int ref_p, real phi) {
  real tar = 0;
  real tar_obs;
  int start_n = csl[start] - sl[start];
  int end_n = csl[end];
  int n = end_n - start_n;
  int snap_obs[n] = obs[(start_n + 1):end_n];
  vector[n] exp_obs;
  int g, t, l;
  int ssnap = 1;
  int esnap = 0;

  for (i in start:end) {
    g = sg[i];
    t = st[i];
    l = sl[i];
    vector[l] rdlh;
    // Find final observed/imputed expected observation
    tar_obs = imp_obs[g][t];
    // allocate report day effects
    rdlh = srdlh[rdlurd[t:(t + l - 1), g]];
    // combine expected final obs and date effects to get expected obs
    esnap += l;
    exp_obs[ssnap:esnap] = expected_obs(
      tar_obs, ref_lh[1:l, dpmfs[i]], rdlh, ref_p
    );
    ssnap += l;
  }
  // observation error model (across all reference times and groups)
  tar = neg_binomial_2_lupmf(snap_obs | exp_obs, phi);
  return(tar);
}

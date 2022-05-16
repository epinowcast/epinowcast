real obs_lpmf(int[] obs, int[] sl, int[] csl,
              vector[] imp_obs, int[] sg, int[] st, int[,] rdlurd,
              vector srdlh, matrix ref_lh, int[] dpmfs, int ref_p, real phi) {
  real tar = 0;
  real tar_obs;
  int n_snaps = num_elements(st);
  int n_obs = num_elements(obs);
  vector[n_obs] exp_obs;
  int g, t, l;
  int ssnap = 1;
  int esnap = 0;

  for (i in 1:n_snaps) {
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
  tar = neg_binomial_2_lupmf(obs | exp_obs, phi);
  return(tar);
}

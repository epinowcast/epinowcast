real obs_lpmf(int[] dummy, int start, int end, int[,] obs, int[] sl,
              vector[] imp_obs, int[] sg, int[] st, int[,] rdlurd,
              vector srdlh, matrix ref_lh, int[] dpmfs, int ref_p, real phi) {
  real tar = 0;
  real tar_obs;
  int t;
  for (i in start:end) {
    vector[sl[i]] exp_obs;
    vector[sl[i]] rdlh;
    // Find final observed/imputed expected observation
    tar_obs = imp_obs[sg[i]][st[i]];
    // allocate report day effects
    rdlh = srdlh[rdlurd[st[i]:(st[i] + sl[i] - 1), sg[i]]];
    // combine expected final obs and date effects to get expected obs
    exp_obs = expected_obs(tar_obs, ref_lh[1:sl[i], dpmfs[i]], rdlh, ref_p);
    // observation error model
    tar += neg_binomial_2_lupmf(obs[i, 1:sl[i]] | exp_obs, phi);
  }
  return(tar);
}

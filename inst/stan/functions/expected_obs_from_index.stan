vector expected_obs_from_index(int i, array[] vector imp_obs,
                               array[,] int rdlurd, vector srdlh,
                               matrix ref_lh, array[] int dpmfs, int ref_p,
                               int rep_h, int ref_as_p, int g, int t, int l) {
  real tar_obs;
  vector[l] rdlh;
  vector[l] ref_lh_i;
  vector[l] log_exp_obs;
  profile("model_likelihood_allocations") {
  // Find final observed/imputed expected observation
  tar_obs = imp_obs[g][t];
  // allocate reference day effects
  if (rep_h) {
    ref_lh_i = ref_lh[1:l, dpmfs[i]];
  }else{
    ref_lh_i = rep_vector(0, l);
  }
  // allocate report day effects
  if (ref_p) {
    rdlh = srdlh[rdlurd[g, t:(t + l - 1)]];
  }else{
    rdlh = rep_vector(0, l);
  }
  }
  // combine expected final obs and date effects to get expected obs
  profile("model_likelihood_expected_obs") {
  log_exp_obs = expected_obs(tar_obs, ref_lh_i, rdlh, ref_as_p);
  }
  return(log_exp_obs);
}

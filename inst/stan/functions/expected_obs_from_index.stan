vector expected_obs_from_index(int i, array[] vector imp_obs,
                               array[,] int rdlurd, vector srdlh,
                               matrix ref_lh, array[] int dpmfs, int ref_p,
                               int rep_h, int ref_as_p, int g, int t, int l) {
  real tar_obs;
  vector[l] lh;
  vector[l] log_exp_obs;
  profile("model_likelihood_expectation_allocations") {
  // Find final observed/imputed expected observation
  tar_obs = imp_obs[g][t];
  }
  profile("model_likelihood_hazard_allocations") {
    lh = combine_logit_hazards(
      i, rdlurd, srdlh, ref_lh, dpmfs, ref_p, rep_h, g, t, l
    );
  }
  // combine expected final obs and date effects to get expected obs
  profile("model_likelihood_expected_obs") {
  log_exp_obs = expected_obs(tar_obs, lh, ref_as_p);
  }
  return(log_exp_obs);
}

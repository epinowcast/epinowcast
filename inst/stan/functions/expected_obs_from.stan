// Calculate  expected observations for a given index
vector expected_obs_from_index(int i, array[] vector imp_obs,
                               array[,] int rdlurd, vector srdlh,
                               matrix refp_lh, array[] int dpmfs, int ref_p,
                               int rep_h, int ref_as_p, int g, int t, int l,
                               vector refnp_lh, int ref_np, int p) {
  real tar_obs;
  vector[l] lh;
  vector[l] log_exp_obs;
  profile("model_likelihood_expectation_allocations") {
  // Find final observed/imputed expected observation
  tar_obs = imp_obs[g][t];
  }
  profile("model_likelihood_hazard_allocations") {
    lh = combine_logit_hazards(
      i, rdlurd, srdlh, refp_lh, dpmfs, ref_p, rep_h, g, t, l, refnp_lh, ref_np,
      p
    );
  }
  // combine expected final obs and time effects to get expected obs
  profile("model_likelihood_expected_obs") {
  log_exp_obs = expected_obs(tar_obs, lh, ref_as_p);
  }
  return(log_exp_obs);
}

// Calculate  expected observations for a set of indexes
vector expected_obs_from_snaps(int start, int end, array[] vector imp_obs,
                               array[,] int rdlurd, vector srdlh,
                               matrix refp_lh, array[] int dpmfs,
                               int ref_p, int rep_h, int ref_as_p,
                               array[] int sl, array[] int csl,
                               array[] int sg, array[] int st, int n,
                               vector refnp_lh, int ref_np, array[] int sdmax,
                               array[] int csdmax) {
  vector[n] log_exp_obs;
  int ssnap = 1;
  int esnap = 0;
  int g; 
  int t;
  int l;
  int p;

  for (i in start:end) {
    profile("allocations") {
    g = sg[i];
    t = st[i];
    l = sl[i];
    p = csdmax[i] - sdmax[i] + 1;
    }
    // combine expected final obs and time effects to get expected obs
    profile("expected_obs_from_index") {
    if (l) {
      esnap += l;
      log_exp_obs[ssnap:esnap] = expected_obs_from_index(
        i, imp_obs, rdlurd, srdlh, refp_lh, dpmfs, ref_p, rep_h, ref_as_p, g, t,
        l, refnp_lh, ref_np, p
      );
      ssnap += l;
    }
    }
  }
  return(log_exp_obs);
}

real obs_delay_lpmf(array[] int dummy, int start, int end, array[] int obs,
                    array[] int sl, array[] int csl, array[] vector imp_obs,
                    array[] int sg, array[] int st, array[,] int rdlurd,
                    vector srdlh,  matrix ref_lh, array[] int dpmfs, int ref_p,
                    int rep_h, int ref_as_p, array[] real phi, int model_obs) {
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
  // observation error model (across all reference times and groups)
  profile("model_likelihood_obs_model") {
  if (model_obs) {
    tar = neg_binomial_2_log_lpmf(snap_obs | log_exp_obs, phi[1]);
  }else{
    tar = poisson_log_lpmf(snap_obs | log_exp_obs);
  }
  }
  return(tar);
}


obs_delay_miss_lpmf(array[] int dummy, int start, int end, array[] int obs,
                    array[] int sl, array[] int csl, array[] vector imp_obs,
                    array[] int sg, array[] int st, array[,] int rdlurd,
                    vector srdlh,  matrix ref_lh, array[] int dpmfs, int ref_p,
                    int rep_h, int ref_as_p, array[] real phi, int model_obs) {
                    

}


<<<<<<< HEAD
real obs_lpmf(int[] obs, int[,] obs_miss, int dmax, int[] sl, int[] csl, int n_groups,
              vector[] imp_obs, int[] sg, int[] st, int[,] rdlurd,
              vector srdlh, matrix ref_lh, int[] dpmfs, int ref_p, vector[] alpha, real phi) {
  real tar = 0;
  real tar_obs;
  real tar_alpha;
  int n_snaps = num_elements(st);
  int n_obs = num_elements(obs);
  int n_obs_miss = num_elements(obs_miss[1]);
  vector[n_obs] exp_obs;
  vector[n_obs_miss] exp_obs_miss[n_groups] = rep_array(rep_vector(0, n_obs_miss), n_groups);
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
    // allocate share of cases with known reference date
    tar_alpha = alpha[g][t];
=======
real obs_lpmf(array[] int dummy, int start, int end, array[] int obs,
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
>>>>>>> develop
    // combine expected final obs and date effects to get expected obs
    profile("model_likelihood_expected_obs_from_index") {
    esnap += l;
<<<<<<< HEAD
    vector[l] exp_obs_all = expected_obs(
      tar_obs, ref_lh[1:l, dpmfs[i]], rdlh, ref_p
=======
    log_exp_obs[ssnap:esnap] = expected_obs_from_index(
      i, imp_obs, rdlurd, srdlh, ref_lh, dpmfs, ref_p, rep_h, ref_as_p, g, t, l
>>>>>>> develop
    );
    // compute expected final obs with known and missing reference date
    exp_obs[ssnap:esnap] = exp_obs_all * tar_alpha;
    if(t+l-1>=1+dmax){
      exp_obs_miss[g][max(1 + dmax, t):(t + l - 1)] += exp_obs_all[max(2 + dmax - t, 1):l] * (1 - tar_alpha);
    }
    ssnap += l;
    }
  }
<<<<<<< HEAD
  // observation error model with known reference dates (across all reference times and groups)
  tar = neg_binomial_2_lupmf(obs | exp_obs, phi);
  // observation error model with missing reference dates
  for (k in 1:n_groups) {
    tar += neg_binomial_2_lupmf(obs_miss[k][(1 + dmax):n_obs_miss] | exp_obs_miss[k][(1 + dmax):n_obs_miss], phi);
=======
  // observation error model (across all reference times and groups)
  profile("model_likelihood_neg_binomial") {
<<<<<<< HEAD
  tar = neg_binomial_2_log_lupmf(snap_obs | log_exp_obs, phi);
>>>>>>> develop
=======
  if (model_obs) {
    tar = neg_binomial_2_log_lupmf(snap_obs | log_exp_obs, phi[1]);
  }else{
    tar = poisson_log_lupmf(snap_obs | log_exp_obs);
  }
>>>>>>> develop
  }
  return(tar);
}

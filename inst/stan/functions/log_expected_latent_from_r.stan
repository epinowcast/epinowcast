array[] vector log_expected_latent_from_r(
  matrix lexp_latent_int, vector r, array[] int r_g, int r_t,
  int r_seed, int gt_n, vector lrgt, int t, int g
) {
  array[g] vector[t] exp_lobs;
  vector[gt_n] rgt = exp(lrgt);

  for (k in 1:g) {
    vector[r_t] local_r = segment(r, r_g[k] + 1, r_t);
    if (gt_n == 1) {
      exp_lobs[k][1] = lexp_latent_int[1, k];
      exp_lobs[k][(r_seed + 1):t] = exp_lobs[k][1] + cumulative_sum(local_r);
    } else {
      vector[t] exp_obs;
      exp_obs[1:r_seed] = exp(lexp_latent_int[1:r_seed, k]);
      vector[r_t] local_R = exp(local_r);
      for (i in 1:r_t) {
        exp_obs[r_seed + i] = local_R[i] * dot_product(
            segment(exp_obs, r_seed + i - gt_n, gt_n), rgt
          );
      }
      exp_lobs[k] = log(exp_obs);
    }
  }
  return(exp_lobs);
}
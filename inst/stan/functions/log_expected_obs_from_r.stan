  array[] vector log_expected_obs_from_r(
    matrix lexp_obs_int, vector r, array[] int r_g, int r_t,
    int r_seed, int gt_n, vector lrgt, int t, int g
  ) {
    array[g] vector[t] exp_lobs;
    for (k in 1:g) {
      vector[r_t] local_r = segment(r, r_g[k], r_t);
      vector[t] local_lobs;
      local_lobs[1:r_seed] = lexp_obs_int[1:r_seed, k];

      if (gt_n == 1) {
      local_lobs[(r_seed + 1):t] = local_lobs[1] + cumulative_sum(local_r);
      }else{
        for (i in 1:r_t){
          local_lobs[r_seed + i] = local_r[i] +
            log_sum_exp(
              segment(local_lobs, i - gt_n, gt_n) + lrgt
            );
        }
      }
      exp_lobs[g] = local_lobs; 
    }
    return(exp_lobs);
  }

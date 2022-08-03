  array[] vector log_expected_obs_from_r(
    matrix lexp_obs_int, vector r, array[] int r_g, int r_t,
    int r_seed, int gt_n, vector lrgt, int t, int g
  ) {
    array[g] vector[t] exp_lobs;
    for (k in 1:g) {
      vector[r_t] local_r = segment(r, r_g[k], r_t);
      exp_lobs[k][1:r_seed] = lexp_obs_int[1:r_seed, k];
      if (gt_n == 1) {
        exp_lobs[k][(r_seed + 1):t] = exp_lobs[k][1] + cumulative_sum(local_r);
      }else{
        for (i in 1:r_t){
          exp_lobs[k][r_seed + i] = local_r[i] +
            log_sum_exp(
              segment(exp_lobs[k], i - gt_n, gt_n) + lrgt
            );
        }
      }
    }
    return(exp_lobs);
  }

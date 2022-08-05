  array[] vector log_expected_obs_from_latent_obs(
    array[] vector exp_latent_lobs, int rd_n, vector lrrd, int t,
    int g, vector modifier
  ) {
    array[g] vector[t] exp_lobs;
    for (k in 1:g) {
      if (rd_n == 1) {
        exp_lobs[k] = exp_latent_lobs[k] + rep_vector(lrrd[1], t);
      }else{
        for (i in 1:t){
          exp_lobs[k][i] = 
            log_sum_exp(
              segment(exp_latent_lobs[k], i, rd_n) + lrrd
            );
        }
      }
      exp_lobs[k] = exp_lobs[k] + segment(modifier, (k-1) * t + 1, t);
    }
    return(exp_lobs);
  }

  array[] vector log_expected_robs_from_iobs(array[] vector exp_liobs, int rd_n,
                                             vector lrrd, int seed_exp, int t,
                                             int g) {
    array[g] vector[t] exp_lobs;
    for (k in 1:g) {
      if (rd_n == 1) {
        exp_lobs[k] = exp_liobs[k] + lrrd;
      }else{
        for (i in 1:t){
          exp_lobs[k][i] = 
            log_sum_exp(
              segment(exp_lobs[k], seed_exp + i - rd_n, rd_n) + lrrd
            );
        }
      }
      exp_lobs[k] = exp_lobs[k] + segment(rep_effects, (k-1) * t + 1, t) 
    }
    return(exp_lobs);
  }

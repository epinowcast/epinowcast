array[] vector log_expected_obs_from_latent(
  array[] vector exp_llatent, int rd_n, vector lrrd, int t,
  int g, vector latent_obs_prop
) {
  array[g] vector[t] exp_lobs;
  vector[rd_n] rrd = exp(lrrd);
  for (k in 1:g) {
    if (rd_n == 1) {
      exp_lobs[k] = exp_llatent[k] + rep_vector(lrrd[1], t);
      exp_lobs[k] = exp_lobs[k] + segment(latent_obs_prop, (k-1) * t + 1, t);
    } else {
      vector[t] exp_obs;
      vector[t] exp_latent = exp(exp_llatent[k]);
      for (i in 1:t) {
        exp_obs[i] = dot_product(segment(exp_latent, i, rd_n), rrd);
      }
      exp_lobs[k] = log(exp_obs) + segment(latent_obs_prop, (k-1) * t + 1, t);
    }
    
  }
  return(exp_lobs);
}

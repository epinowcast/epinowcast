array[] vector log_expected_obs_from_latent(
  array[] vector exp_llatent, int rd_n, vector lrrd, int t,
  int g, vector latent_obs_prop
) {
  array[g] vector[t] exp_lobs;
  for (k in 1:g) {
    if (rd_n == 1) {
      exp_lobs[k] = exp_llatent[k] + rep_vector(lrrd[1], t);
    } else {
      for (i in 1:t) {
        exp_lobs[k][i] = log_dot_product(segment(exp_llatent[k], i, rd_n), lrrd);
      }
    }
    exp_lobs[k] = exp_lobs[k] + segment(latent_obs_prop, (k-1) * t + 1, t);
  }
  return(exp_lobs);
}

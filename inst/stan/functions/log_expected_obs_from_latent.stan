array[] vector log_expected_obs_from_latent(
  array[] vector exp_llatent, int rd_n, vector w, array[] int v,
  array[] int u, int t,
  int g, vector latent_obs_prop
) {
  array[g] vector[t] exp_lobs;
  int ft = t + rd_n - 1;
  for (k in 1:g) {
    if (rd_n == 1) {
      exp_lobs[k] = exp_llatent[k] + log(w) +
        segment(latent_obs_prop, (k-1) * t + 1, t);
    } else {
      vector[ft] exp_obs = csr_matrix_times_vector(
        ft, ft, w, v, u, exp(exp_llatent[k])
      );
      exp_lobs[k] = log(exp_obs[rd_n:ft]) +
        segment(latent_obs_prop, (k-1) * t + 1, t);
    }
    
  }
  return(exp_lobs);
}

functions {
#include functions/hazard.stan
#include functions/expected_obs.stan
}
data {
  int l;
  real tar_obs;
  vector[l] lh;
  int ref_as_p;
  int rep_agg_p;
  array[l] int n_selected;
  array[l, l] int selected_idx;
}
generated quantities {
  vector[l] result = expected_obs(tar_obs, lh, l, ref_as_p, rep_agg_p, n_selected, selected_idx);
}

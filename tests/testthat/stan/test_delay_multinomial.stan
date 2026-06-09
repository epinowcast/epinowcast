functions {
#include functions/filt_obs_indexes.stan
#include functions/delay_multinomial_lpmf.stan
}
data {
  int n;
  array[n] int obs;
  vector[n] log_exp_obs;
}
generated quantities {
  real lpmf = delay_multinomial_lpmf(obs | log_exp_obs);
}

functions {
#include functions/calculate_secondary.stan
}
data {
  int t;
  vector[t] scaled_reports;
  vector[t] conv_reports;
  array[t] int obs;
  int cumulative;
  int historic;
  int primary_hist_additive;
  int current;
  int primary_current_additive;
  int predict;
}
generated quantities {
  vector[t] result = calculate_secondary(
    scaled_reports, conv_reports, obs, cumulative, historic,
    primary_hist_additive, current, primary_current_additive, predict
  );
}

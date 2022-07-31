vector log_expected_by_report(vector log_exp, array[,] int obs_by_report) {
  int t = size(obs_by_report);
  vector[t] log_exp_rep;
  for (i in 1:t) {
    log_exp_rep[i] = log_sum_exp(log_exp[obs_by_report[i]]);
  }
  return(log_exp_rep);
}

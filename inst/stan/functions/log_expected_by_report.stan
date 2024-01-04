/**
 * Calculate log of expected values by report date
 * 
 * Computes the logarithm of expected values aggregated by report date. This 
 * function takes a vector of logarithmic expected values and an array 
 * indicating observations by report date, and then calculates the log of the 
 * sum of exponentials of expected values for each report date.
 * 
 * @param log_exp Vector of log expected values.
 *
 * @param obs_by_report Array indicating which observations correspond to each 
 * report date.
 * 
 * @return Vector of log expected values aggregated by report date.
 * 
 * @note The computation for a report date i is given by:
 *  @f[ \text{log\_exp\_rep}_i = 
    \log\left(\sum_{j \in \text{obs\_by\_report}[i]} 
    \exp(\text{log\_exp}_j)\right) @f]
 *  This represents the log-sum-exp operation over the expected values 
 *  corresponding to the observations reported on date i.
 */
vector log_expected_by_report(vector log_exp, array[,] int obs_by_report) {
  int t = size(obs_by_report);
  vector[t] log_exp_rep;
  for (i in 1:t) {
    log_exp_rep[i] = log_sum_exp(log_exp[obs_by_report[i]]);
  }
  return(log_exp_rep);
}

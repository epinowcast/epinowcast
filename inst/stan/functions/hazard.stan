/**
 * Convert probabilities to hazards
 * 
 * Transforms a vector of probabilities into hazards. This function calculates 
 * the hazard for each time point based on the given probabilities.
 * 
 * @param p Vector of probabilities.
 * 
 * @return Vector of hazards corresponding to the input probabilities.
 * 
 * @note The hazard at time i is defined as:
 *  @f[ h_i = \frac{p_i}{1 - \sum_{j=1}^{i-1} p_j} @f]
 *  The final hazard (h_l) is set to 1.
 */
vector prob_to_hazard(vector p) {
  int l = num_elements(p);
  int i = l - 1;
  vector[l] h;
  vector[i] cum_p;
  cum_p[1] = 0;
  cum_p[2:i] = cumulative_sum(p[1:(i-1)]);
  h[1:i] = p[1:i] ./ (1 - cum_p);
  h[l] = 1;
  return(h);
}

/**
 * Compute the cumulative converse log hazard
 * 
 * Calculates the cumulative sum of the converse of log hazards. This function 
 * shifts the hazard vector by one time unit, applies the converse log 
 * transformation, and then computes the cumulative sum.
 * 
 * @param h Vector of hazards.
 * 
 * @return Vector of cumulative converse log hazards.
 * 
 * @note The cumulative converse log hazard is defined as:
 *  @f[ ch_i = \sum_{j=1}^{i} \log(1 - h_{j-1}) @f]
 *  where @f[ h_{0} @f] is considered to be 0.
 */
vector cumulative_converse_log_hazard(vector h) {
  int l = num_elements(h);
  vector[l] h_shifted;
  vector[l] ch;
  h_shifted[1] = 0;
  if (l > 1) {
    h_shifted[2:l] = h[1:(l-1)];
  }
  ch = log1m(h_shifted);
  ch = cumulative_sum(ch);
  return(ch);
}

/**
 * Convert hazards to log probabilities
 * 
 * Transforms a vector of hazards into log probabilities. This function uses
 * the hazards to compute the log probabilities for each time point. Internally
 * it calls `cumulative_converse_log_hazard` to compute part of the log
 * probability.
 * 
 * @param h Vector of hazards.
 * 
 * @return Vector of log probabilities corresponding to the input hazards.
 * 
 * @note The log probability at time i is defined as:
 *  @f[ p_i = \log(h_i) + \text{cumulative_converse_log_hazard}(h_i) @f]
 *  This function calls `cumulative_converse_log_hazard` for part of its
 *  computation.
 *
 * Dependencies:
 *  - cumulative_converse_log_hazard
 */
vector hazard_to_log_prob(vector h) {
  int l = num_elements(h);
  vector[l] p;
  p[1:l] = log(h[1:l]) + cumulative_converse_log_hazard(h[1:l]);
  return(p);
}

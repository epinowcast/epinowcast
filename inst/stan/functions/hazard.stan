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
  // h[i] = p[i] / (1 - sum(p[1:(i-1)])), with h[l] = 1 by definition
  return append_row(
    p[1:(l-1)] .* inv(1 - append_row(0.0, cumulative_sum(p[1:(l-2)]))),
    1.0
  );
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
 * @param l Length of the vector.
 * 
 * @return Vector of cumulative converse log hazards.
 * 
 * @note The cumulative converse log hazard is defined as:
 *  @f[ ch_i = \sum_{j=1}^{i} \log(1 - h_{j-1}) @f]
 *  where @f[ h_{0} @f] is considered to be 0.
 */
vector cumulative_converse_log_hazard(vector h, int l) {
  // Shift hazards by one time unit: [0, h[1], h[2], ..., h[l-1]]
  // Then compute cumulative sum of log(1 - h_shifted) for survival probability
  return cumulative_sum(log1m(append_row(0.0, h[1:(l-1)])));
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
 * @param l Length of the vector.
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
vector hazard_to_log_prob(vector h, int l) {
  return(log(h) + cumulative_converse_log_hazard(h, l));
}

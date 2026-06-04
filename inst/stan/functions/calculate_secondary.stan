/**
 * Calculate a secondary observation from a primary series
 *
 * Builds the expected secondary observation as a delayed, scaled convolution
 * of a primary series, optionally accumulated over time for prevalence-type
 * targets (e.g. bed occupancy). The five binary switches control how the
 * historic (convolved) and current (scaled) primary contributions combine,
 * matching the `EpiNow2` secondary parameterisation.
 *
 * The convolution of the primary series is supplied pre-computed (as a sparse
 * matrix-vector product done by the caller) so the only per-time work here is
 * the optional cumulative accumulation; the scaled current term and the
 * convolution are otherwise vectorised by the caller.
 *
 * @param scaled_reports Vector of scaled current primary reports (natural
 *   scale), already multiplied by the ascertainment scaling.
 *
 * @param conv_reports Vector of convolved historic primary reports (natural
 *   scale).
 *
 * @param obs Array of observed secondary reports, used to seed the cumulative
 *   target before the prediction window.
 *
 * @param cumulative Whether to carry the previous secondary value forward (1)
 *   for a prevalence target, or not (0) for an incidence target.
 *
 * @param historic Whether to include the convolved historic primary term (1)
 *   or not (0).
 *
 * @param primary_hist_additive Whether the historic term is additive (1) or
 *   subtractive (0).
 *
 * @param current Whether to include the scaled current primary term (1) or not
 *   (0).
 *
 * @param primary_current_additive Whether the current term is additive (1) or
 *   subtractive (0).
 *
 * @param predict Number of time points to predict (the cumulative target is
 *   seeded from `obs` before this window and carried forward within it).
 *
 * @return A vector of expected secondary reports (natural scale).
 *
 * @note Adapted from `EpiNow2`
 *   (https://github.com/epiforecasts/EpiNow2, MIT licensed). The accumulation
 *   recursion is inherently sequential; all other terms are vectorised by the
 *   caller before this function is called.
 */
vector calculate_secondary(
  vector scaled_reports, vector conv_reports, array[] int obs,
  int cumulative, int historic, int primary_hist_additive,
  int current, int primary_current_additive, int predict
) {
  int t = num_elements(scaled_reports);
  vector[t] secondary_reports;

  // Combine the historic (convolved) and current (scaled) primary terms in a
  // single vectorised pass; signs follow the additive/subtractive switches.
  vector[t] increment = rep_vector(0.0, t);
  if (historic) {
    increment += primary_hist_additive ? conv_reports : -conv_reports;
  }
  if (current) {
    increment += primary_current_additive ? scaled_reports : -scaled_reports;
  }

  if (!cumulative) {
    // Incidence target: no accumulation, just floor at a small positive value
    secondary_reports = fmax(rep_vector(1e-6, t), increment);
    return secondary_reports;
  }

  // Prevalence target: accumulate contributions, seeding the prediction window
  // from observed data. This recursion is inherently sequential.
  secondary_reports[1] = fmax(1e-6, increment[1]);
  for (i in 2:t) {
    real prev = i > predict ? secondary_reports[i - 1] : obs[i - 1];
    secondary_reports[i] = fmax(1e-6, prev + increment[i]);
  }
  return secondary_reports;
}

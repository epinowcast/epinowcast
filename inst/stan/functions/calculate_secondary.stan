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
 * matrix-vector product done by the caller). The incidence (non-cumulative)
 * path is fully vectorised; the prevalence (cumulative) path follows the
 * sequential EpiNow2 per-element ordering exactly, clamping the subtractive
 * historic term at 0 before adding the current term.
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
 *   (https://github.com/epiforecasts/EpiNow2, MIT licensed), reproducing its
 *   per-element combination ordering for the cumulative path (subtractive
 *   historic clamped at 0 before the current term; additive 1e-6 at the end).
 *   The incidence path is the algebraic equivalent vectorised over time.
 */
vector calculate_secondary(
  vector scaled_reports, vector conv_reports, array[] int obs,
  int cumulative, int historic, int primary_hist_additive,
  int current, int primary_current_additive, int predict
) {
  int t = num_elements(scaled_reports);
  vector[t] secondary_reports = rep_vector(0.0, t);

  if (!cumulative) {
    // Incidence target: no carry-forward, so each element starts from 0 and
    // the historic / current terms vectorise. The subtractive-historic clamp
    // at 0 (before the current term) and the additive 1e-6 at the end exactly
    // match the per-element EpiNow2 logic when there is no accumulation.
    if (historic) {
      secondary_reports = primary_hist_additive
        ? conv_reports
        : fmax(rep_vector(0.0, t), -conv_reports);
    }
    if (current) {
      secondary_reports += primary_current_additive
        ? scaled_reports
        : -scaled_reports;
    }
    secondary_reports += 1e-6;
    return secondary_reports;
  }

  // Prevalence / cumulative target: accumulate contributions, seeding the
  // prediction window from observed data. This recursion is inherently
  // sequential and reproduces the EpiNow2 ordering exactly: clamp the
  // subtractive historic (outflow) term at 0 BEFORE adding the current
  // (inflow) term, then add 1e-6 at the end (allowing a negative result when
  // the current term is subtractive).
  for (i in 1:t) {
    if (i > 1) {
      secondary_reports[i] = i > predict ? secondary_reports[i - 1] : obs[i - 1];
    }
    if (historic) {
      if (primary_hist_additive) {
        secondary_reports[i] += conv_reports[i];
      } else {
        secondary_reports[i] = fmax(0, secondary_reports[i] - conv_reports[i]);
      }
    }
    if (current) {
      if (primary_current_additive) {
        secondary_reports[i] += scaled_reports[i];
      } else {
        secondary_reports[i] -= scaled_reports[i];
      }
    }
    secondary_reports[i] += 1e-6;
  }
  return secondary_reports;
}

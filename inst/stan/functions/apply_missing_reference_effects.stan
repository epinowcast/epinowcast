/**
 * Apply missing reference effects to observations
 * 
 * This function adjusts observed data for missing reference effects over a 
 * specified time range. It applies a correction based on missing reference 
 * log probabilities for each period in the time range.
 * 
 * @param start The start index for the application range.
 * 
 * @param end The end index for the application range.
 * 
 * @param obs A vector of observations to be adjusted.
 * 
 * @param sl Array of start index for each observation period.
 * 
 * @param csl Array of cumulative start indices.
 * 
 * @param miss_ref_lprop Vector of missing reference log probabilities, applied
 * to each period.
 * 
 * @return A vector of adjusted observations, with missing reference effects
 * applied.
 * 
 * @note
 * Dependencies:
 *   - filt_obs_indexes
 */
vector apply_missing_reference_effects(int start, int end, vector obs,
                                       array[] int sl, array[] int csl,
                                       vector miss_ref_lprop) {
  array[3] int n = filt_obs_indexes(start, end, csl, sl);
  vector[n[3]] alloc_obs;
  // Declare once outside loop to avoid repeated allocation
  array[3] int l;
  for (i in start:end) {
    l = filt_obs_indexes(i, i, csl, sl);
    alloc_obs[l[1]:l[2]] =
      segment(obs, l[1], l[3]) + miss_ref_lprop[i];
  }
  return(alloc_obs);
}

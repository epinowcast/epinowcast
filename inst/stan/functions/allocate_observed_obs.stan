/**
 * Allocate observed observations for a given time range
 * 
 * This function allocates observed observations within a specified time range
 * based on input observation data (either vector or integer array) and 
 * various supporting arrays. This function is overloaded to support both
 * vector and array[int] types for observed data.
 * 
 * @param start The start index for the allocation range.
 *
 * @param end The end index for the allocation range.
 *
 * @param obs Observations to be allocated. Can be a vector (for continuous 
 * data) or an array of integers (for count data).
 *
 * @param sl Array of start index for each observation period.
 *
 * @param csl Array of cumulative start indices.
 *
 * @param sdmax Array of maximum start dates for each period.
 *
 * @param csdmax Array of cumulative start dates.
 * 
 * @return Allocated observations within the specified time range. The return 
 *         type matches the type of `obs` (either vector or array[int]).
 */
vector allocate_observed_obs(int start, int end, vector obs, 
                             array[] int sl, array[] int csl,
                             array[] int sdmax, array[] int csdmax) {
  array[3] int n = filt_obs_indexes(start, end, csl, sl);
  vector[n[3]] alloc_obs;
  for (i in start:end) {
    array[3] int l = filt_obs_indexes(i, i, csl, sl);
    array[3] int f = filt_obs_indexes(i, i, csdmax, sdmax);
    alloc_obs[l[1]:l[2]] = segment(obs, f[1], sl[i]);
  }
  return(alloc_obs);
}

array[] int allocate_observed_obs(int start, int end, array[] int obs, 
                             array[] int sl, array[] int csl,
                             array[] int sdmax, array[] int csdmax) {
  array[3] int n = filt_obs_indexes(start, end, csl, sl);
  array[n[3]] int alloc_obs;
  for (i in start:end) {
    array[3] int l = filt_obs_indexes(i, i, csl, sl);
    array[3] int f = filt_obs_indexes(i, i, csdmax, sdmax);
    alloc_obs[l[1]:l[2]] = segment(obs, f[1], sl[i]);
  }
  return(alloc_obs);
}

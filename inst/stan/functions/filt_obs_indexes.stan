/**
 * Find the contiguous interval of flattened observations
 * 
 * Identifies the range of contiguous observation indexes in a flattened 
 * observation array between two specified snapshot IDs. The function calculates
 * the starting and ending indexes of the observations corresponding to the 
 * snapshots and determines the length of this interval.
 * 
 * @param start The ID of the starting snapshot.
 *
 * @param end The ID of the ending snapshot.
 *
 * @param csl Array of cumulative start indexes for each snapshot.
 *
 * @param sl Array of start index for each observation period.
 * 
 * @return An array containing three elements: the index of the first
 * observation in the starting snapshot, the index of the last observation in
 * the ending snapshot, and the total number of observations in the interval.
 * 
 * @note This function is particularly useful in contexts where data is
 * segmented into snapshots and needs to be processed or analyzed over
 * continuous intervals.
 */
array[] int filt_obs_indexes(int start, int end, array[] int csl,
                             array[] int sl) {
  array[3] int n;
  n[1] = csl[start] - sl[start] + 1; // index of first obs in snapshot start
  n[2] = csl[end]; // index of last obs in snapshot end
  n[3] = n[2] - n[1] + 1; // total number of flattened obs / length of interval
  return(n);
}

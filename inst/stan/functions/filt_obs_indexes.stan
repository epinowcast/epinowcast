// Find the contiguous interval of flattened observations between snapshot
// with id `start` and snapshot with id `end`
array[] int filt_obs_indexes(int start, int end, array[] int csl,
                             array[] int sl) {
  array[3] int n;
  n[1] = csl[start] - sl[start] + 1; // index of first obs in snapshot start
  n[2] = csl[end]; // index of last obs in snapshot end
  n[3] = n[2] - n[1] + 1; // total number of flattened obs / length of interval
  return(n);
}

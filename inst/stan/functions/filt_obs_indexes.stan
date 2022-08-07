// Where am I in flattened observations based on snapshot ids and known
// look-ups
array[] int filt_obs_indexes(int start, int end, array[] int csl,
                             array[] int sl) {
  array[3] int n;
  n[1] = csl[start] - sl[start];
  n[2] = csl[end];
  n[3] = n[2] - n[1];
  return(n);
}

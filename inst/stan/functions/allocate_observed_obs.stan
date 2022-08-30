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

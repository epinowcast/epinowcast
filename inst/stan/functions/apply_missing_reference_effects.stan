vector apply_missing_reference_effects(int start, int end, vector obs, 
                                       array[] int sl, array[] int csl,
                                       vector miss_ref_lprop) {
  array[3] int n = filt_obs_indexes(start, end, csl, sl);
  vector[n[3]] alloc_obs;
  for (i in start:end) {
    array[3] int l = filt_obs_indexes(i, i, csl, sl);
    alloc_obs[l[1]:l[2]] =
      segment(obs, l[1], l[3]) + miss_ref_lprop[i];
  }
  return(alloc_obs);        
}

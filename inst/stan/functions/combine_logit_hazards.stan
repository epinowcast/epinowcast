vector combine_logit_hazards(int i, array[,] int rdlurd, vector srdlh,
                             matrix ref_lh, array[] int dpmfs, int ref_p,
                             int rep_h, int g, int t, int l) {
  vector[l] lh;
  // allocate reference day effects
  if (ref_p) {
    lh = ref_lh[1:l, dpmfs[i]];
  }else{
    lh = rep_vector(0, l);
  }
  // allocate report day effects
  if (rep_h) {
    vector[l] rlh = srdlh[rdlurd[g, t:(t + l - 1)]];
    lh = lh + rlh;
  }
  return(lh);
}

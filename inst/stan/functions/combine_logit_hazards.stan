vector combine_logit_hazards(int i, array[,] int rdlurd, vector srdlh,
                             matrix refp_lh, array[] int dpmfs, int ref_p,
                             int rep_h, int g, int t, int l, vector refnp_lh, int refnp_p) {
  vector[l] lh;
  // allocate reference date effects
  if (ref_p) {
    lh = refp_lh[1:l, dpmfs[i]];
  }else{
    lh = rep_vector(0, l);
  }
  // allocate reference non-parametric effects
  if (refnp_p) {
    lh = lh + refnp_lh;
  }
  // allocate reporting time effects
  if (rep_h) {
    vector[l] rlh = srdlh[rdlurd[g, t:(t + l - 1)]];
    lh = lh + rlh;
  }
  return(lh);
}

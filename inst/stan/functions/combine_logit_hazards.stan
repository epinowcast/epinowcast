/**
 * Combine logit hazards from multiple sources
 * 
 * This function combines logit hazards from various sources for a given
 * time period. It integrates parametric reference date effects,
 * non-parametric reference effects, and reporting time effects into a single
 * logit hazard vector.
 * 
 * @param i Index for accessing elements in `dpmfs`.
 * 
 * @param rdlurd Array indicating reporting dates lookup reference data.
 * 
 * @param srdlh Vector of standardized reporting date log hazards.
 * 
 * @param refp_lh Matrix of reference date logit hazards.
 * 
 * @param dpmfs Array of indices for accessing reference date effects in 
 * `refp_lh`.
 * 
 * @param ref_p Flag indicating if reference date effects are present (1) or 
 * not (0).
 * 
 * @param rep_h Flag indicating if reporting date hazards are to be used (1) or 
 * not (0).
 * 
 * @param g Group index for accessing elements in `rdlurd`.
 * 
 * @param t Time index for accessing elements in `rdlurd`.
 * 
 * @param l Length of the period for which hazards are calculated.
 * 
 * @param refnp_lh Vector of non-parametric reference log hazards.
 * 
 * @param refnp_p Flag indicating if non-parametric reference effects are 
 * present (1) or not (0).
 * 
 * @param p Start index for segmenting `refnp_lh`.
 * 
 * @return A vector of combined logit hazards for the specified time period.
 */
vector combine_logit_hazards(int i, array[,] int rdlurd, vector srdlh,
                             matrix refp_lh, array[] int dpmfs, int ref_p,
                             int rep_h, int g, int t, int l, vector refnp_lh, int refnp_p, int p) {
  vector[l] lh;
  // set reference date effects (or zero if none)
  if (ref_p) {
    lh = refp_lh[1:l, dpmfs[i]];
  } else {
    lh = rep_vector(0, l);
  }
  // add non-parametric reference effects
  if (refnp_p) {
    lh += segment(refnp_lh, p, l);
  }
  // add reporting time effects
  if (rep_h) {
    lh += srdlh[rdlurd[g, t:(t + l - 1)]];
  }
  return(lh);
}

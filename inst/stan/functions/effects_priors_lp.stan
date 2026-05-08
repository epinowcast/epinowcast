/**
 * Specify priors for regression effects (centred parameterisation variant).
 *
 * EXPERIMENT: this worktree hardcodes the centred parameterisation. The
 * production code uses the non-centred parameterisation, where `beta` is
 * unit-scale and is rescaled in `combine_effects.stan` via
 * `beta .* (rdesign * ext_beta_sd)`. Here `beta` is sampled directly at
 * data scale, with element-wise scale `rdesign * ext_beta_sd`, and
 * `combine_effects.stan` no longer multiplies. See issue #800.
 *
 * @param beta Vector of regression effects (data-scale under centred).
 * @param beta_sd Vector of standard deviations for the random effects.
 * @param beta_sd_p Parameters for the normal prior on beta_sd.
 * @param rdesign Dense matrix relating effect sizes to standard deviations.
 * @param fixed Number of fixed (i.e. column) effects in beta.
 * @param random Number of random-effect SDs in beta_sd.
 */
void effect_priors_lp(vector beta, vector beta_sd, array[,] real beta_sd_p,
                      matrix rdesign, int fixed, int random) {
  if (fixed) {
    if (random) {
      beta_sd ~ normal(beta_sd_p[1, 1], beta_sd_p[2, 1]);
      // Centred: beta ~ normal(0, per-element sd) where the per-element sd is
      // 1.0 for fixed effects (rdesign first column = 1, ext_beta_sd[1] = 1)
      // and beta_sd[k] for random-effect entries mapped via rdesign.
      vector[1 + num_elements(beta_sd)] ext_beta_sd =
        append_row(1.0, beta_sd);
      vector[fixed] per_elem_sd = rdesign * ext_beta_sd;
      beta ~ normal(0, per_elem_sd);
    } else {
      beta ~ std_normal();
    }
  }
}

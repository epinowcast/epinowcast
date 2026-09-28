/**
 * Specify priors for regression effects
 * 
 * This function sets priors for the regression effects and their standard
 * deviations. It allows for the specification of both fixed and random effects,
 * with the option to apply a normal distribution to the
 * standard deviations of the random effects.
 * 
 * @param beta Vector of regression effects.
 *
 * @param beta_sd Vector of standard deviations for the regression effects.
 *
 * @param beta_sd_p Parameters for the prior on beta_sd.
 * The first row indicates the location, and the second row the scale.
 *
 * @param beta_sd_p_dist Distribution id of the prior on beta_sd, see
 * `prior_lpdf()`.
 *
 * @param fixed Binary flag indicating if fixed effect priors are to be set (1) 
 * or not (0).
 *
 * @param random Binary flag indicating if random effect priors are to be set
 * (1) or not (0).
 * 
 * @note The function applies the following priors based on the flags:
 *  1. If `fixed` is true, a standard normal prior is applied to `beta`.
 *  2. If both `fixed` and `random` are true, the prior selected by
 *     `beta_sd_p_dist` is applied to `beta_sd`, with parameters specified
 *     in `beta_sd_p`.
 *     This allows for flexible prior specification depending on the nature
*      of the regression effects being modeled.
 */
void effect_priors_lp(vector beta, vector beta_sd, array[,] real beta_sd_p,
                      int beta_sd_p_dist, int fixed, int random) {
  if (fixed) {
    beta ~ std_normal();
    if (random) {
      target += prior_lpdf(
        beta_sd | beta_sd_p_dist, beta_sd_p[1, 1], beta_sd_p[2, 1]
      );
    }
  }
}

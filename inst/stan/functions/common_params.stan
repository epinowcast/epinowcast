/**
 * \page common_parameters_page Common Parameters
 * @section Common Parameters for `delay_snap_lpmf` and `delay_group_lpmf`
 *
 * @param obs Array of observed data, stored as a flat vector.
 *
 * @param sl Array of start index for each observation period.
 *
 * @param csl Array of cumulative start indexes.
 *
 * @param nsl Array of next start indexes, indicating the start of the next
 * period.
 *
 * @param cnsl Array of cumulative next start indexes.
 *
 * @param obs_lookup Array of indexes linking observed data to modeled
 * expectations.
 *
 * @param imp_obs Array of imputed observed data, organized by group and time.
 *
 * @param sg Array indicating group index for each observation.
 *
 * @param st Array indicating time index for each observation.
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
 * @param ref_p Binary flag for reference date effects presence.
 *
 * @param rep_h Binary flag for reporting hazard effects presence.
 *
 * @param ref_as_p Binary flag indicating if reference date input should be
 * treated as probability.
 *
 * @param phi Array of dispersion parameters for negative binomial distribution.
 *
 * @param model_obs Binary flag indicating if a negative binomial model is used.
 *
 * @param refnp_lh Vector of non-parametric reference log hazards.
 *
 * @param ref_np Binary flag for non-parametric reference effects presence.
 *
 * @param sdmax Array of maximum start dates for each period.
 *
 * @param csdmax Array of cumulative start dates.
 *
 */

functions {
#include functions/zero_truncated_normal.stan
#include functions/regression.stan
#include functions/discretised_logit_hazard.stan
#include functions/hazard.stan
#include functions/expected_obs.stan
#include functions/combine_logit_hazards.stan
#include functions/expected_obs_from.stan
#include functions/filt_obs_indexes.stan
#include functions/obs_lpmf.stan
#include functions/delay_lpmf.stan
}

data {
  // Indexes and lookups
  int n; // total observations
  int t; // time range over which data is available 
  int s; // number of snapshots there are
  int g; // number of data groups
  array[g] int groups; // array of group ids
  array[s] int st; // when in this time snapshots are from
  array[t, g] int ts; // snapshot related to time and group
  array[s] int sl; // how many days of reported data does each snapshot have
  array[s] int csl; // cumulative version of the above
  array[s] int sg; // how snapshots are related
  int dmax; // maximum possible report date
  array[s] int sdmax; // Array of maximum reported dates
  array[s] int csdmax; // Arraay of maximum cumulative reported dates

  // Observations
  array[s, dmax] int obs; // obs for each primary date (row) and report date (column)
  array[n] int flat_obs; // obs stored as a flat vector
  array[t, g] int latest_obs; // latest obs for each snapshot group

  // Expectation model
  array[2] real eobs_lsd_p; // Standard deviation for expected final observations

  // Reference day model
  int model_refp;
  int refp_fnrow;
  array[s] int refp_findex;
  int refp_fncol;
  matrix[refp_fnrow, refp_fncol + 1] refp_fdesign;
  int refp_rncol;
  matrix[refp_fncol, refp_rncol + 1] refp_rdesign; 
  array[2] real refp_mean_int_p;
  array[2] real refp_sd_int_p;
  array[2] real refp_mean_beta_sd_p;
  array[2] real refp_sd_beta_sd_p; 

  // Reporting day model
  int model_rep;
  int rep_t; // how many reporting days are there (t + dmax - 1)
  int rep_fnrow; 
  array[g, rep_t] int rep_findex; 
  int rep_fncol;
  matrix[rep_fnrow, rep_fncol + 1] rep_fdesign;
  int rep_rncol; 
  matrix[rep_fncol, rep_rncol + 1] rep_rdesign; 
  array[2] real rep_beta_sd_p;

  // Missing reference date model
  int model_miss;
  int miss_fnindex;
  int miss_fncol;
  int miss_rncol;
  matrix[miss_fnindex, miss_fncol + 1] miss_fdesign;
  matrix[miss_fncol, model_miss ? miss_rncol + 1 : 0] miss_rdesign;
  array[model_miss ? g : 0, miss_fnindex] int missing_ref;
  array[2] real miss_int_p;
  array[2] real miss_beta_sd_p;

  // Observation model
  int model_obs; // Control parameter for the observation model
  array[2] real sqrt_phi_p; // 1/sqrt(overdispersion)

  // Control parameters
  int debug; // should debug information be shown
  int likelihood; // should the likelihood be included
  // type of aggregation scheme (0 = snaps, 1 = groups)
  int likelihood_aggregation;
  int pp; // should posterior predictions be produced
  int cast; // should a nowcast be produced
  int ologlik; // Should the pointwise log likelihood be calculated
}

transformed data{
  real logdmax = 5*log(dmax); // scaled maxmimum delay to log for crude bounds
  // prior mean of cases based on thoose observed
  vector[g] eobs_init = log(to_vector(latest_obs[1, 1:g]) + 1);
  // if no reporting day effects use native probability for reference day
  // effects, i.e. do not convert to logit hazard
  int ref_as_p = (model_rep > 0 || model_refp == 0) ? 0 : 1; 
  // Type of likelihood aggregation to use
  int ll_aggregation = likelihood_aggregation + model_miss;
}

parameters {
  // Expectation model
  array[g] real leobs_init; // First time point for expected observations
  vector<lower=0>[g] eobs_lsd; // standard deviation of rw for primary obs
  array[g] vector[t - 1] leobs_resids; // unscaled rw for primary obs

  // Reference model
  array[model_refp ? 1 : 0] real<lower=-10, upper=logdmax> refp_mean_int;
  array[model_refp > 1 ? 1 : 0]real<lower=1e-3, upper=2*dmax> refp_sd_int; 
  vector[model_refp ? refp_fncol : 0] refp_mean_beta; 
  vector[model_refp > 1 ? refp_fncol : 0] refp_sd_beta; 
  vector<lower=0>[refp_rncol] refp_mean_beta_sd;
  vector<lower=0>[model_refp ? refp_rncol : 0] refp_sd_beta_sd; 

  // Report model
  vector[rep_fncol] rep_beta;
  vector<lower=0>[rep_rncol] rep_beta_sd; 

  // Missing reference date model
  array[model_miss] real miss_int;
  vector[miss_fncol] miss_beta; 
  vector<lower=0>[miss_rncol] miss_beta_sd; 

  // Observation model
  array[model_obs > 0 ? 1 : 0] real<lower=0> sqrt_phi; // Overall dispersion
}

transformed parameters{
  // Expectation model
  array[g] vector[t] imp_obs; // Expected final observations
  // Reference model
  vector[refp_fnrow] refp_mean;
  vector[refp_fnrow] refp_sd;
  matrix[dmax, refp_fnrow] ref_lh; // sparse report logit hazards
  // Report model
  vector[rep_fnrow] srdlh; // sparse report day logit hazards
  // Missing model
  vector[miss_fnindex] miss_ref_lprop;

  // Observation model
  array[model_obs > 0 ? 1 : 0] real phi; // Transformed overdispersion

  // Expectation model
  profile("transformed_expected_final_observations") {
  for (k in 1:g) {
    real llast_obs;
    imp_obs[k][1] = leobs_init[k];
    imp_obs[k][2:t] = 
      leobs_init[k] + eobs_lsd[k] * cumulative_sum(leobs_resids[k]);
  }
  }

  // Reference model
  profile("transformed_delay_reference_date_total") {
  if (model_refp) {
    // calculate sparse reference date effects
    profile("transformed_delay_reference_date_effects") {
    refp_mean = combine_effects(refp_mean_int[1], refp_mean_beta, refp_fdesign,
                                refp_mean_beta_sd, refp_rdesign, 1);
    if (model_refp > 1) {
      refp_sd = combine_effects(log(refp_sd_int[1]), refp_sd_beta, refp_fdesign,
                                refp_sd_beta_sd, refp_rdesign, 1); 
      refp_sd = exp(refp_sd);
    }
    }
    // calculate reference date logit hazards (unless no reporting effects)
    profile("transformed_delay_reference_date_hazards") {
    for (i in 1:refp_fnrow) {
      ref_lh[, i] = discretised_logit_hazard(
        refp_mean[i], refp_sd[i], dmax, model_refp, 2, ref_as_p
      );
    }
    }
  }  
  }

  // Report model
  profile("transformed_delay_reporting_date_effects") {
  srdlh =
    combine_effects(0, rep_beta, rep_fdesign, rep_beta_sd, rep_rdesign, 1);
  }

  // Missing reference model
  if (model_miss) {
    miss_ref_lprop = log_inv_logit(
      combine_effects(miss_int[1], miss_beta, miss_fdesign, miss_beta_sd, miss_rdesign, 1)
    );
  }
  
  // Observation model
  if (model_obs) {
    profile("transformed_delay_missing_effects") {
    phi = inv_square(sqrt_phi);
  }
  } 
  // debug issues in truncated data if/when they appear
  if (debug) {
#include /chunks/debug.stan
  }
} 
  
model {
  profile("model_priors") {
  // priors for unobserved expected reported cases
  leobs_init ~ normal(eobs_init, 1);
  eobs_lsd ~ zero_truncated_normal(eobs_lsd_p[1], eobs_lsd_p[2]);
  for (i in 1:g) {
    leobs_resids[i] ~ std_normal();
  }

  // priors for the intercept of the log mean truncation distribution
  if (model_refp) {
    refp_mean_int ~ normal(refp_mean_int_p[1], refp_mean_int_p[2]);
    if (model_refp > 1) {
      refp_sd_int ~ normal(refp_sd_int_p[1], refp_sd_int_p[2]);
    }
    effect_priors_lp(
      refp_mean_beta, refp_mean_beta_sd, refp_mean_beta_sd_p, refp_fncol,
       refp_rncol
    );
    if (model_refp > 1) {
      effect_priors_lp(
        refp_sd_beta, refp_sd_beta_sd, refp_sd_beta_sd_p, refp_fncol,
        refp_rncol
      );
    }
  }
  // priors and scaling for date of report effects
  effect_priors_lp(rep_beta, rep_beta_sd, rep_beta_sd_p, rep_fncol, rep_rncol);
  
  // priors for missing reference date effects
  if (model_miss) {
    miss_int ~ normal(miss_int_p[1], miss_int_p[2]);
    effect_priors_lp(
      miss_beta, miss_beta_sd, miss_beta_sd_p, miss_fncol, miss_rncol
    );
  }

  // reporting overdispersion (1/sqrt)
  if (model_obs) {
    sqrt_phi[1] ~ normal(sqrt_phi_p[1], sqrt_phi_p[2]) T[0,];
  }
  }
  // log density: observed vs model
  if (likelihood) {
    profile("model_likelihood") {
    if (ll_aggregation) {
      target += reduce_sum(
        delay_snap_lupmf, st, 1, flat_obs, sl, csl, imp_obs, sg, st, rep_findex,
        srdlh, ref_lh, refp_findex, model_refp, rep_fncol, ref_as_p, phi,
        model_obs
      );
    } else {
      target += reduce_sum(
        delay_group_lupmf, groups, 1, flat_obs, sl, csl, imp_obs, t, sg, ts, st,
        rep_findex, srdlh, ref_lh, refp_findex, model_refp, rep_fncol, ref_as_p, phi, model_obs, model_miss, miss_ref_lprop
      );
    }
    }
  }
}

generated quantities {
  array[pp ? sum(sl) : 0] int pp_obs;
  vector[ologlik ? s : 0] log_lik;
  array[cast ? dmax : 0, cast ? g : 0] int pp_inf_obs;
  profile("generated_total") {
  if (cast) {
    vector[csdmax[s]] log_exp_obs;
    array[csdmax[s]] int pp_obs_tmp;

    // Posterior predictions for observations
    profile("generated_obs") {
    log_exp_obs = expected_obs_from_snaps(
      1, s, imp_obs, rep_findex, srdlh, ref_lh, refp_findex, model_refp,
      rep_fncol, ref_as_p, sdmax, csdmax, sg, st, csdmax[s]
    );
    pp_obs_tmp = obs_rng(log_exp_obs, phi, model_obs);
    } 
    
    // Likelihood by snapshot (rather than by observation)
    for (i in 1:s) {
      profile("generated_loglik") {
      if (ologlik) {
        array[3] int l = filt_obs_indexes(i, i, csl, sl);
        array[3] int f = filt_obs_indexes(i, i, csdmax, sdmax);
        log_lik[i] = 0;
        for (j in 1:sl[i]) {
          log_lik[i] += obs_lpmf(
            flat_obs[l[1] + j]  | log_exp_obs[f[1] + j], phi, model_obs
          );
        }
      }
      }
    }
    // Posterior prediction for final reported data (i.e at t = dmax + 1)
    // Organise into a grouped and time structured array
    profile("generated_obs") {
    for (k in 1:g) {
      int start_t = t - dmax;
      for (i in 1:dmax) {
        int i_start = ts[start_t + i, k];
        array[3] int l = filt_obs_indexes(i_start, i_start, csl, sl);
        array[3] int f = filt_obs_indexes(i_start, i_start, csdmax, sdmax);
        pp_inf_obs[i, k] = sum(flat_obs[(l[1] + 1):l[2]]);
        if (sl[i_start] < dmax) {
          pp_inf_obs[i, k] += sum(pp_obs_tmp[(f[1] + sl[i_start] + 1):f[2]]);
        }
      }
    }
    // If posterior predictions for all observations are needed copy
    // from a temporary object to a permanent one
    // drop predictions without linked observations
    if (pp) {
      for (i in 1:s) {
        array[3] int l = filt_obs_indexes(i, i, csl, sl);
        array[3] int f = filt_obs_indexes(i, i, csdmax, sdmax);
        pp_obs[(l[1] + 1):l[2]] = pp_obs_tmp[(f[1] + 1):(f[1] + sl[i])];
      }
    }
    }
  }
}
}

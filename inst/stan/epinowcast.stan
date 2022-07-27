functions {
#include functions/zero_truncated_normal.stan
#include functions/regression.stan
#include functions/discretised_logit_hazard.stan
#include functions/hazard.stan
#include functions/expected_obs.stan
#include functions/combine_logit_hazards.stan
#include functions/expected_obs_from_index.stan
#include functions/obs_lpmf.stan
#include functions/delay_lpmf.stan
}

data {
  // Indexes and lookups
  int n; // total observations
  int t; // time range over which data is available 
  int s; // number of snapshots there are
  int g; // number of data groups
  array[s] int st; // when in this time snapshots are from
  array[t, g] int ts; // snapshot related to time and group
  array[s] int sl; // how many days of reported data does each snapshot have
  array[s] int csl; // cumulative version of the above
  array[s] int sg; // how snapshots are related
  int dmax; // maximum possible report date
  // Observations
  array[s, dmax] int obs; // obs for each primary date (row) and report date (column)
  array[n] int flat_obs; // obs stored as a flat vector
  array[t, g] int latest_obs; // latest obs for each snapshot group
  // Reference day model
  int refp_fnrow; // how many unique pmfs there are
  array[s] int refp_findex; // how each date links to a pmf
  int refp_fncol; // number of effects to apply
  matrix[refp_fnrow, refp_fncol + 1] refp_fdesign; // design matrix for pmfs
  int refp_rncol; // number of standard deviations to use for pooling
  matrix[refp_fncol, refp_rncol + 1] refp_rdesign; // Pooling pmf design matrix 
  int model_refp; // parametric distribution (0 = none, 1 = exp, 2 = lognormal, 3 = gamma, 4 = loglogistic)
  // Reporting day model
  int model_rep; // Reporting day model in use
  int rep_t; // how many reporting days are there (t + dmax - 1)
  int rep_fnrow; // how many unique reporting days are there
  array[g, rep_t] int rep_findex; // how each report date links to a sparse report effect
  int rep_fncol; // number of report day effects to apply
  matrix[rep_fnrow, rep_fncol + 1] rep_fdesign; // design matrix for report dates
  int rep_rncol; // number of standard deviations to use for pooling for rds
  matrix[rep_fncol, rep_rncol + 1] rep_rdesign; // Pooling pmf design matrix 
  // Observation model
  int model_obs; // Control parameter for the observation model (0 = Poisson, 1 = Negbin)
  // Control parameters
  int debug; // should debug information be shown
  int likelihood; // should the likelihood be included
  int pp; // should posterior predictions be produced
  int cast; // should a nowcast be produced
  int ologlik; // Should the pointwise log likelihood be calculated
  // Priors (1st index = mean, 2nd index = standard deviation)
  array[2] real eobs_lsd_p; // Standard deviation for expected final observations
  array[2] real refp_mean_int_p; // log mean intercept for reference date delay
  array[2] real refp_sd_int_p; // log standard deviation for the reference date delay
  array[2] real refp_mean_beta_sd_p; // standard deviation of scaled pooled logmean effects
  array[2] real refp_sd_beta_sd_p; // standard deviation of scaled pooled logsd effects
  array[2] real rep_beta_sd_p; //standard deviation of scaled pooled report date effects
  array[2] real sqrt_phi_p; // 1/sqrt(overdispersion)
}

transformed data{
  real logdmax = 5*log(dmax); // scaled maxmimum delay to log for crude bounds
  // prior mean of cases based on thoose observed
  vector[g] eobs_init = log(to_vector(latest_obs[1, 1:g]) + 1);
  // if no reporting day effects use native probability for reference day
  // effects, i.e. do not convert to logit hazard
  int ref_as_p = (model_rep > 0 || model_refp == 0) ? 0 : 1; 
}

parameters {
  array[g] real leobs_init; // First time point for expected observations
  vector<lower=0>[g] eobs_lsd; // standard deviation of rw for primary obs
  array[g] vector[t - 1] leobs_resids; // unscaled rw for primary obs
  array[model_refp ? 1 : 0] real<lower=-10, upper=logdmax> refp_mean_int; // logmean intercept
  array[model_refp > 1 ? 1 : 0]real<lower=1e-3, upper=2*dmax> refp_sd_int; // logsd intercept
  vector[model_refp ? refp_fncol : 0] refp_mean_beta; // unscaled modifiers to log mean
  vector[model_refp > 1 ? refp_fncol : 0] refp_sd_beta; // unscaled modifiers to log sd
  vector[rep_fncol] rep_beta; // unscaled modifiers to report date hazard
  vector<lower=0>[refp_rncol] refp_mean_beta_sd; // pooled modifiers to logmean
  vector<lower=0>[model_refp ? refp_rncol : 0] refp_sd_beta_sd; // pooled modifiers to logsd
  vector<lower=0>[rep_rncol] rep_beta_sd; // pooled modifiers to report date
  array[model_obs > 0 ? 1 : 0] real<lower=0> sqrt_phi; // Overall dispersion by group
}

transformed parameters{
  vector[refp_fnrow] refp_mean;
  vector[refp_fnrow] refp_sd;
  matrix[dmax, refp_fnrow] ref_lh; // sparse report logit hazards
  vector[rep_fnrow] srdlh; // sparse report day logit hazards
  array[g] vector[t] imp_obs; // Expected final observations
  array[model_obs > 0 ? 1 : 0] real phi; // Transformed overdispersion (joint across all observations)
  // calculate log mean and sd parameters for each dataset from design matrices
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
  // calculate sparse report date effects with forced 0 intercept
  profile("transformed_delay_reporting_date_effects") {
  srdlh =
    combine_effects(0, rep_beta, rep_fdesign, rep_beta_sd, rep_rdesign, 1);
  }
  // estimate unobserved expected final reported cases for each group
  // this could be any forecasting model but here its a 
  // first order random walk for each group on the log scale.
  profile("transformed_expected_final_observations") {
  for (k in 1:g) {
    real llast_obs;
    imp_obs[k][1] = leobs_init[k];
    imp_obs[k][2:t] = 
      leobs_init[k] + eobs_lsd[k] * cumulative_sum(leobs_resids[k]);
  }
  } 
  // transform phi to overdispersion scale
  if (model_obs) {
    phi = inv_square(sqrt_phi);
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

  // reporting overdispersion (1/sqrt)
  if (model_obs) {
    sqrt_phi[1] ~ normal(sqrt_phi_p[1], sqrt_phi_p[2]) T[0,];
  }
  }
  // log density: observed vs model
  if (likelihood) {
    profile("model_likelihood") {
    target += reduce_sum(
      delay_lupmf, st, 1, flat_obs, sl, csl, imp_obs, sg, st, rep_findex, srdlh,
      ref_lh, refp_findex, model_refp, rep_fncol, ref_as_p, phi, model_obs
    );
    }
  }
}

generated quantities {
  array[pp ? sum(sl) : 0] int pp_obs;
  vector[ologlik ? s : 0] log_lik;
  array[cast ? dmax : 0, cast ? g : 0] int pp_inf_obs;
  profile("generated_total") {
  if (cast) {
    vector[dmax] lexp_obs;
    array[s, dmax] int pp_obs_tmp;
    // Posterior predictions for observations
    for (i in 1:s) {
      profile("generated_obs") {
      lexp_obs = expected_obs_from_index(
        i, imp_obs, rep_findex, srdlh, ref_lh, refp_findex, model_refp,
        rep_fncol, ref_as_p, sg[i], st[i], dmax
      );
      pp_obs_tmp[i, 1:dmax] = obs_rng(lexp_obs, phi, model_obs);
      }
      profile("generated_loglik") {
      if (ologlik) {
        log_lik[i] = 0;
        for (j in 1:sl[i]) {
          log_lik[i] += obs_lpmf(obs[i, j]  | lexp_obs[j], phi, model_obs);
        }
      }
      }
    }
    // Posterior prediction for final reported data (i.e at t = dmax + 1)
    profile("generated_obs") {
    for (k in 1:g) {
      int start_t = t - dmax;
      for (i in 1:dmax) {
        int snap = ts[start_t + i, k];
        pp_inf_obs[i, k] = sum(obs[snap, 1:sl[snap]]);
        if (sl[snap] < dmax) {
          pp_inf_obs[i, k] += sum(pp_obs_tmp[snap, (sl[snap]+1):dmax]);
        }
      }
    }
    // If posterior predictions for all observations are needed copy
    // from a temporary object to a permanent one
    // store in a flat vector to make observation linking easier
    if (pp) {
      int start_t = 0;
      for (i in 1:s) {
        pp_obs[(start_t + 1):(start_t + sl[i])] = pp_obs_tmp[i, 1:sl[i]];
        start_t += sl[i];
      }
    }
    }
  }
}
}

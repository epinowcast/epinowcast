functions {
#include functions/regression.stan
#include functions/discretised_reporting_prob.stan
#include functions/hazard.stan
#include functions/zero_truncated_normal.stan
#include functions/expected_obs.stan
#include functions/expected_obs_from_index.stan
#include functions/obs_lpmf.stan
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
<<<<<<< HEAD
=======
  // Observations
  array[s, dmax] int obs; // obs for each primary date (row) and report date (column)
  array[n] int flat_obs; // obs stored as a flat vector
  array[t, g] int latest_obs; // latest obs for each snapshot group
>>>>>>> develop
  // Reference day model
  int npmfs; // how many unique pmfs there are
  array[s] int dpmfs; // how each date links to a pmf
  int neffs; // number of effects to apply
  matrix[npmfs, neffs + 1] d_fixed; // design matrix for pmfs
  int neff_sds; // number of standard deviations to use for pooling
  matrix[neffs, neff_sds + 1] d_random; // Pooling pmf design matrix 
  int dist; // parametric distribution (0 = none, 1 = exp. 2 = lognormal, 2 = gamma)
  // Reporting day model
  int rd; // how many reporting days are there (t + dmax - 1)
  int urds; // how many unique reporting days are there
  array[rd, g] int rdlurd; // how each report date links to a sparse report effect
  int nrd_effs; // number of report day effects to apply
  matrix[urds, nrd_effs + 1] rd_fixed; // design matrix for report dates
  int nrd_eff_sds; // number of standard deviations to use for pooling for rds
  matrix[nrd_effs, nrd_eff_sds + 1] rd_random; // Pooling pmf design matrix 
  // Observations
  int obs[s, dmax]; // obs for each primary date (row) and report date (column)
  int flat_obs[n]; // obs stored as a flat vector
  int obs_miss[g, t]; // obs with missing primary date (group first)
  int latest_obs[t, g]; // latest obs for each snapshot group
  // Control parameters
  int debug; // should debug information be shown
  int likelihood; // should the likelihood be included
  int pp; // should posterior predictions be produced
  int cast; // should a nowcast be produced
  int ologlik; // Should the pointwise log likelihood be calculated
  // Priors (1st index = mean, 2nd index = standard deviation)
<<<<<<< HEAD
  real eobs_lsd_p[2]; // Standard deviation for expected final observations
  real alpha_start_p[2]; // starting value for alpha random walk (logit scale)
  real alpha_sd_p[2]; // standard deviation for alpha random walk increments
  real logmean_int_p[2]; // log mean intercept for reference date delay
  real logsd_int_p[2]; // log standard deviation for the reference date delay
  real logmean_sd_p[2]; // standard deviation of scaled pooled logmean effects
  real logsd_sd_p[2]; // standard deviation of scaled pooled logsd effects
  real rd_eff_sd_p[2]; //standard deviation of scaled pooled report date effects
  real sqrt_phi_p[2]; // 1/sqrt(overdispersion)
=======
  array[2] real eobs_lsd_p; // Standard deviation for expected final observations
  array[2] real logmean_int_p; // log mean intercept for reference date delay
  array[2] real logsd_int_p; // log standard deviation for the reference date delay
  array[2] real logmean_sd_p; // standard deviation of scaled pooled logmean effects
  array[2] real logsd_sd_p; // standard deviation of scaled pooled logsd effects
  array[2] real rd_eff_sd_p; //standard deviation of scaled pooled report date effects
  array[2] real sqrt_phi_p; // 1/sqrt(overdispersion)
>>>>>>> develop
}

transformed data{
  real logdmax = 5*log(dmax); // scaled maxmimum delay to log for crude bounds
  // prior mean of cases based on thoose observed
  vector[g] eobs_init = log(to_vector(latest_obs[1, 1:g]) + 1);
  // if no reporting day effects use native probability for reference day
  // effects
  int ref_as_p = (nrd_effs > 0 || dist) ? 0 : 1; 
}

parameters {
  array[g] real leobs_init; // First time point for expected observations
  vector<lower=0>[g] eobs_lsd; // standard deviation of rw for primary obs
  array[g] vector[t - 1] leobs_resids; // unscaled rw for primary obs
  array[dist ? 1 : 0] real<lower=-10, upper=logdmax> logmean_int; // logmean intercept
  array[dist > 1 ? 1 : 0]real<lower=1e-3, upper=2*dmax> logsd_int; // logsd intercept
  vector[dist ? neffs : 0] logmean_eff; // unscaled modifiers to log mean
  vector[dist > 1 ? neffs : 0] logsd_eff; // unscaled modifiers to log sd
  vector[nrd_effs] rd_eff; // unscaled modifiers to report date hazard
  vector<lower=0>[neff_sds] logmean_sd; // pooled modifiers to logmean
  vector<lower=0>[dist ? neff_sds : 0] logsd_sd; // pooled modifiers to logsd
  vector<lower=0>[nrd_eff_sds] rd_eff_sd; // pooled modifiers to report date
  real alpha_start[g]; // starting value for alpha
  real<lower=0> alpha_sd; // standard deviation of the random walk increments
  vector<offset=0, multiplier=alpha_sd>[t] alpha_epsilon[g]; // random walk increments, non-centered
  real<lower=0, upper=1e4> sqrt_phi; // Overall dispersion by group
}

transformed parameters{
  vector[npmfs] logmean;
  vector[npmfs] logsd;
  matrix[dmax, npmfs] pmfs; // sparse report distributions
  matrix[dmax, npmfs] ref_lh; // sparse report logit hazards
  vector[urds] srdlh; // sparse report day logit hazards
<<<<<<< HEAD
  vector[t] imp_obs[g]; // Expected final observations
  vector<lower=0,upper=1>[t] alpha[g]; // share of cases with known reference date
=======
  array[g] vector[t] imp_obs; // Expected final observations
>>>>>>> develop
  real phi; // Transformed overdispersion (joint across all observations)
  // calculate log mean and sd parameters for each dataset from design matrices
  profile("transformed_delay_reference_date_total") {
  if (dist) {
    profile("transformed_delay_reference_date_effects") {
    logmean = combine_effects(logmean_int[1], logmean_eff, d_fixed, logmean_sd,
                              d_random);
    if (dist > 1) {
      logsd = combine_effects(log(logsd_int[1]), logsd_eff, d_fixed, logsd_sd,
                              d_random); 
      logsd = exp(logsd);
    }
    }
    // calculate pmfs
    profile("transformed_delay_reference_date_pmfs") {
    for (i in 1:npmfs) {
      pmfs[, i] = discretised_reporting_prob(logmean[i], logsd[i], dmax, dist);
    }
    if (ref_as_p == 0) {
      for (i in 1:npmfs) {
        ref_lh[, i] = prob_to_hazard(pmfs[, i]);
        ref_lh[, i] = logit(ref_lh[, i]);
      }
    }else{
      ref_lh = pmfs;
    }
    }
  }
  }
  // calculate sparse report date effects with forced 0 intercept
  profile("transformed_delay_reporting_date_effects") {
  srdlh = combine_effects(0, rd_eff, rd_fixed, rd_eff_sd, rd_random);
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
  // estimate share of cases with eventually known reference date, modeled as
  // a first order random walk for each group on the logit scale
  for (k in 1:g) {
    alpha[k] = inv_logit(alpha_start[k] + cumulative_sum(alpha_epsilon[k]));
  }
  // transform phi to overdispersion scale
  phi = inv_sqrt(sqrt_phi);
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
  // priors for the intercept of the log normal truncation distribution
  if (dist) {
    logmean_int ~ normal(logmean_int_p[1], logmean_int_p[2]);
    if (dist > 1) {
      logsd_int ~ normal(logsd_int_p[1], logsd_int_p[2]);
    }
    // priors and scaling for date of reference effects
    if (neffs) {
      logmean_eff ~ std_normal();
      if (dist > 1) {
        logsd_eff ~ std_normal();
      }
      if (neff_sds) {
        logmean_sd ~ zero_truncated_normal(logmean_sd_p[1], logmean_sd_p[2]);
        if (dist > 1) {
          logsd_sd ~ zero_truncated_normal(logsd_sd_p[1], logsd_sd_p[2]);
        }
      }
    }
  }
  // priors and scaling for date of report effects
  if (nrd_effs) {
    rd_eff ~ std_normal();
    if (nrd_eff_sds) {
      rd_eff_sd ~ zero_truncated_normal(rd_eff_sd_p[1], rd_eff_sd_p[2]);
    } 
  }
  // share of cases with eventually known reference date
  alpha_sd ~ normal(alpha_sd_p[1], alpha_sd_p[2]) T[0, ];
  for (k in 1:g){
    alpha_start[k] ~ normal(alpha_start_p[1], alpha_start_p[2]);
    alpha_epsilon[k] ~ normal(0, alpha_sd);
  }
  // reporting overdispersion (1/sqrt)
  sqrt_phi ~ normal(sqrt_phi_p[1], sqrt_phi_p[2]) T[0,];
  }
  // log density: observed vs model
  if (likelihood) {
    profile("model_likelihood") {
<<<<<<< HEAD
    target += obs_lupmf(flat_obs | obs_miss, dmax, sl, csl, g, imp_obs, sg, st,
                         rdlurd, srdlh, ref_lh, dpmfs, ref_p, alpha, phi);
=======
    target += reduce_sum(
      obs_lupmf, st, 1, flat_obs, sl, csl, imp_obs, sg, st, rdlurd, srdlh,
      ref_lh, dpmfs, dist, nrd_effs, ref_as_p, phi
    );
>>>>>>> develop
    }
  }
}

generated quantities {
<<<<<<< HEAD
  int pp_obs[pp ? sum(sl) : 0];
  int pp_obs_miss[pp ? sum(sl) : 0];
  vector[ologlik ? s : 0] log_lik;
  vector[ologlik ? (t-dmax) : 0] log_lik_miss;
  int pp_inf_obs[cast ? dmax : 0, cast ? g : 0];
  int pp_inf_obs_miss[cast ? t : 0, cast ? g : 0];
  int pp_inf_obs_miss_rep[cast ? (t-dmax) : 0, cast ? g : 0];
  profile("generated_total") {
  if (cast) {
    int i_group, i_time;
    real tar_obs, tar_alpha;
    vector[dmax] rdlh;
    vector[dmax] exp_obs;
    vector[ologlik ? t : 0] exp_obs_miss_rep[ologlik ? g : 0];
    int pp_obs_tmp[s, dmax];
    int pp_obs_tmp_miss[s, dmax];
    exp_obs_miss_rep = rep_array(rep_vector(0, t), g);
    pp_inf_obs_miss_rep = rep_array(0, (t-dmax), g);
    // Posterior predictions for observations
    for (i in 1:s) {
      profile("generated_obs") {
      i_group = sg[i];
      i_time = st[i];
      // estimated expected cases
      tar_obs = imp_obs[i_group][i_time];
      // estimated share of known reference dates
      tar_alpha = alpha[i_group][i_time];
      // reference date delay hazard
      rdlh = srdlh[rdlurd[i_time:(i_time + dmax - 1), i_group]];
      // expected observations with delay 0:(dmax-1)
      exp_obs = expected_obs(tar_obs, ref_lh[1:dmax, dpmfs[i]], rdlh, ref_p);
      // realized observations with known reference date
      pp_obs_tmp[i, 1:dmax] = neg_binomial_2_rng(exp_obs * tar_alpha, phi);
      // realized observations with unknown reference date
      pp_obs_tmp_miss[i, 1:dmax] = neg_binomial_2_rng(exp_obs * (1 - tar_alpha), phi);
=======
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
        i, imp_obs, rdlurd, srdlh, ref_lh, dpmfs, dist, nrd_effs, ref_as_p,
        sg[i], st[i], dmax
      );
      pp_obs_tmp[i, 1:dmax] = neg_binomial_2_log_rng(lexp_obs, phi);
>>>>>>> develop
      }
      profile("generated_loglik") {
      if (ologlik) {
        // predicted observations with missing reference date by reporting date
        if (i_time > 1) {
          exp_obs_miss_rep[i_group][i_time:min(i_time + dmax - 1, t)]
            += (exp_obs * (1 - tar_alpha))[1:min(dmax, t - i_time + 1)];
        }
        log_lik[i] = 0;
        for (j in 1:sl[i]) {
<<<<<<< HEAD
          // log-likelihood for observations with known reference date
          log_lik[i] += neg_binomial_2_lpmf(obs[i, j] | exp_obs[j] * tar_alpha, phi);
=======
          log_lik[i] += neg_binomial_2_log_lpmf(obs[i, j] | lexp_obs[j], phi);
>>>>>>> develop
        }
      }
      }
    }
    profile("generated_loglik") {
    if (ologlik) {
      for (i in (dmax+1):t) {
        log_lik_miss[i - dmax] = 0;
        for (k in 1:g) {
          // log-likelihood for observations with missing reference date
          log_lik_miss[i - dmax] += neg_binomial_2_lpmf(
            obs_miss[k, i] | exp_obs_miss_rep[k][i], phi);
        }
      }
    }
    }
    // Posterior prediction for final reported data (i.e at t = dmax + 1)
    profile("generated_obs") {
    for (k in 1:g) {
      // cases with known reference date (by reference date)
      int start_t = t - dmax;
      for (i in 1:dmax) {
        int snap = ts[start_t + i, k];
        pp_inf_obs[i, k] = sum(obs[snap, 1:sl[snap]]);
        if (sl[snap] < dmax) {
          pp_inf_obs[i, k] += sum(pp_obs_tmp[snap, (sl[snap]+1):dmax]);
        }
      }
      // cases with missing reference date (by estimated reference date)
      for (i in 1:t) {
        int snap = ts[i, k];
        pp_inf_obs_miss[i, k] = sum(pp_obs_tmp_miss[snap, 1:dmax]);
      }
      // cases with missing reference date (by reporting date)
      for (i in 2:t) {
        int snap = ts[i, k];
        for (l in max(dmax - i + 2, 1):min(dmax, t - i + 1)){
          pp_inf_obs_miss_rep[(i - dmax) + l - 1, k] += pp_obs_tmp_miss[snap, l];
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
        pp_obs_miss[(start_t + 1):(start_t + sl[i])] = pp_obs_tmp_miss[i, 1:sl[i]];
        start_t += sl[i];
      }
    }
    }
  }
}
}

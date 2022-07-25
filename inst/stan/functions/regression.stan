// Combine nested regression effects
// 
// Combines nested regression effects using a design matrix
// includes effect pooling used a second design matrix in which
// the first row indicates no scaling (i.e  independent effects).
// 
// @param intercept The regression intercept
// 
// @param beta A Vector of effects. In general these should be specified
// on the unit scale as they may be rescaled (and hence pooled) using the
// beta_sd vector.
// 
// @param design The design matrix for the observations (rows) and effects
// columns.
// 
// @param beta_sd A vector of standard deviations to use for scaling (pooling)
// effect sizes.
// 
// @param sd_design The design matrix relating effect sizes (rows) with standard
// deviations (columns). The first column is used to indicate no scaling. In
// general each effect should only be scaled with a single standard deviation.
// 
// @param add_intercept Binary. Should the intercept be added to the supplied
// beta vector. 
//
// @return A vector of linear predictions without error.
// 
//  @examples
// # compile function for use in R
// source(here::here("R", "utils.R"))
// expose_stan_fns("regression.stan", "stan/functions")
// 
// # make example data
// intercept <- 1
// beta <- c(0.1, 0.2, 0.4)
// design <- t(matrix(c(1, 0, 0, 1, 1, 1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1), 4, 4))
// beta_sd <- c(0.1)
// sd_design <- t(matrix(c(1, 0, 0, 1, 0, 1), 2 ,3))
// 
// # Check effects  are combined as expected
// combine_effects(intercept, beta, design, beta_sd, sd_design)
// # 1.04 1.12 1.00 1.04
//
// Check function works with no effects
// combine_effects(intercept, as.double(c()), design, beta_sd, sd_design)
// # 1 1 1 1
vector combine_effects(real intercept, vector beta, matrix design,
                       vector beta_sd, matrix sd_design, int add_intercept) {
  int nobs = rows(design);
  int neffs = num_elements(beta);
  int sds = num_elements(beta_sd);
  vector[neffs + add_intercept] scaled_beta;
  vector[sds + 1] ext_beta_sd;
  ext_beta_sd[1] =  1.0;
  if (neffs) {
    ext_beta_sd[2:(sds+1)] = beta_sd;
      if (add_intercept) {
        scaled_beta[1] = intercept;
      }
    scaled_beta[(1+add_intercept):(neffs+add_intercept)] =
      beta .* (sd_design * ext_beta_sd);
    return(design * scaled_beta);
  }else{
    return(rep_vector(intercept, nobs));
  }
}

void effect_priors_lp(vector beta, vector beta_sd, array[] real beta_sd_p,
                    int fixed, int random) {
  if (fixed) {
    beta ~ std_normal();
    if (random) {
      beta_sd ~ zero_truncated_normal(beta_sd_p[1], beta_sd_p[2]);
    }
  }
}

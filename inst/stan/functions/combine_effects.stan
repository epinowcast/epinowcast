/**
 * Combine nested regression effects using design matrices
 * 
 * This function combines nested regression effects based on a design matrix and
 * applies effect pooling using a second design matrix. It allows for scaling 
 * of effects with specified standard deviations, enabling the pooling of these 
 * effects. The function can also incorporate an intercept into the linear 
 * predictions.
 * 
 * @param intercept Array containing the regression intercept (length one).
 *
 * @param beta Vector of regression effects, typically unit-scaled for possible 
 * rescaling with beta_sd.
 *
 * @param nobs Integer the number of observations (i.e. design matrix columns).
 *
 * @param neffs Integer the number of effects (i.e. the number of rows in the design
 * matrix).
 *
 * @param fdesign Dense matrix mapping observations (rows) to fixed effects (columns).
 *
 * @param beta_sd Vector of standard deviations for scaling and pooling effects.
 *
 * @param rdesign Dense matrix relating effect sizes to standard deviations.
 * The first column indicates no scaling for independent effects.
 *
 * @param sparse Sparse matrix components for fixed effects design matrix.
 * The output from csr_extract(fdesign).
 *
 * @param add_intercept Binary flag to indicate if the intercept should be
 * added to the beta vector.
 *
 * @param sparse_design Binary flag to indicate whether to use sparse or dense
 * matrices.
 * 
 * @return A vector of linear predictions without error.
 * 
 * @note The function scales the beta vector using the product of beta_sd and 
 * rdesign, then combines these scaled effects with the fdesign matrix. 
 * If `add_intercept` is true, the intercept is included in the linear 
 * predictions. The function handles cases with no effects by returning 
 * a vector of the intercept repeated for each observation.
 * 
 * @code
 * # Example usage in R:
 * intercept <- 1
 * beta <- c(0.1, 0.2, 0.4)
 * design <- t(matrix(c(1, 0, 0, 1, 1, 1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1), 4, 4))
 * beta_sd <- c(0.1)
 * sd_design <- t(matrix(c(1, 0, 0, 1, 0, 1), 2, 3))
 * 
 * # Check effects are combined as expected:
 * combine_effects(
 *   intercept, beta, 4, 3, design, list({}, {}, {}), beta_sd, sd_design, 1, 0
 * )
 * # Output: 1.04 1.12 1.00 1.04
 * @endcode
 */
vector combine_effects(array[] real intercept, vector beta, 
                       int nobs, int neffs,
                       // Dense matrix components
                       matrix fdesign,
                       // Sparse matrix components
                       tuple(vector, array[] int, array[] int) sparse,
                       vector beta_sd, 
                       // Dense matrix for random effects
                       matrix rdesign,
                       int add_intercept, int sparse_design) {
  if (neffs) {
    vector[1 + num_elements(beta_sd)] ext_beta_sd = append_row(1.0, beta_sd);
    vector[nobs] result;
    vector[neffs] scaled_beta = beta .* (rdesign * ext_beta_sd);
    
    if (sparse_design) {
      // Extract sparse matrix components from fdesign
      result = csr_matrix_times_vector(
        nobs, neffs, sparse.1, sparse.2, sparse.3, scaled_beta
      );
    } else {
      result = fdesign * scaled_beta;
    }
    
    if (add_intercept) {
      result = result + intercept[1];
    }
    return(result);
  } else {
    return(rep_vector(intercept[1], nobs));
  }
}

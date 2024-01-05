/**
 * Compute dot product on the log scale
 * 
 * Calculates the dot product of two vectors on the log scale efficiently. This
 * function is designed to handle operations where the vectors are represented 
 * in log space, avoiding potential underflow issues that can arise with 
 * standard dot product calculations on the natural scale, especially with
 * small values.
 * 
 * @param x First vector in log space.
 *
 * @param y Second vector in log space.
 * 
 * @return The log of the dot product of the two vectors.
 * 
 * @note The function computes the dot product as follows:
 *  1. Element-wise sum of `x` and `y` (since they are in log space).
 *  2. Application of `log_sum_exp` to the result, which efficiently 
 *     calculates the logarithm of the sum of exponentials, corresponding 
 *     to the log of the dot product.
 * 
 * This approach is particularly useful in statistical contexts where 
 * log-space operations are common, such as in the computation of 
 * log-likelihoods.
 */
real log_dot_product(vector x, vector y) {
  return(log_sum_exp(x + y));
}

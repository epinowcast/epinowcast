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

/**
 * Count the number of non-zero elements in a matrix
 * 
 * This function iterates through all elements of a given matrix and counts
 * the number of elements that are not equal to zero.
 * 
 * @param x The input matrix to be analyzed.
 * 
 * @return An integer representing the count of non-zero elements in the matrix.
 * 
 * @note This function may be useful in contexts where the sparsity of a matrix
 * needs to be quantified, such as in sparse matrix operations or in assessing
 * the efficiency of certain matrix algorithms.
 */
int num_nonzero(matrix x) {
  int i = rows(x);
  int j = cols(x);
  int n = 0;
  for (k in 1:i) {
    for (l in 1:j) {
      if (x[k, l] != 0) {
        n = n + 1;
      }
    }
  }
  return(n);
}

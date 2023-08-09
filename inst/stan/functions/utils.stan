/**
* Efficient dot product on log scale
*/
real log_dot_product(vector x, vector y) {
  return(log_sum_exp(x + y));
}

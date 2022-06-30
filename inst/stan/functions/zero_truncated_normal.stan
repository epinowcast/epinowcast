real zero_truncated_normal_lpdf(vector y, real mu, real sigma) {
  real tar;
  real g = num_elements(y);
  tar = normal_lpdf(y | mu, sigma)  -  g * normal_lccdf(0 | mu, sigma);
  return(tar);
}

real zero_truncated_normal_lpdf(array[] real y, real mu, real sigma) {
  real tar;
  real g = num_elements(y);
  tar = normal_lpdf(y | mu, sigma)  -  g * normal_lccdf(0 | mu, sigma);
  return(tar);
}

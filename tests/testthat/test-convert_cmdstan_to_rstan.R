test_that(
  "convert_cmdstan_to_rstan can regex cmdstan stan code to rstan stan code", {
  expect_equal(
    epinowcast:::convert_cmdstan_to_rstan("gamma_cdf(a | b, c)"),
    "gamma_cdf(a, b, c)"
  )
  expect_equal(
    epinowcast:::convert_cmdstan_to_rstan("gamma_lupmf(a, b, c)"),
    "gamma_lpmf(a, b, c)"
  )
  expect_equal(
    epinowcast:::convert_cmdstan_to_rstan("array[] real x"),
    "real[] x"
  )
  expect_equal(
    epinowcast:::convert_cmdstan_to_rstan("array[,] real x"),
    "real[,] x"
  )
  expect_equal(
    epinowcast:::convert_cmdstan_to_rstan("array[n] real x;"),
    "real x[n];"
  )
  expect_equal(
    epinowcast:::convert_cmdstan_to_rstan("array[nl, pq] vector[n] x;"),
    "vector[n] x[nl, pq];"
  )
  expect_equal(
    epinowcast:::convert_cmdstan_to_rstan("array[nl, pq] matrix[n, l] x;"),
    "matrix[n, l] x[nl, pq];"
  )
})
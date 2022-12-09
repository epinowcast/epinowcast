test_that("add_pmfs can combine two Poisson distributions", {
  # Sample and analytical PMFs for two Poisson distributions
  set.seed(123)
  x <- rpois(100000, 5)
  xpmf <- dpois(0:20, 5)
  y <- rpois(100000, 7)
  ypmf <- dpois(0:20, 7)
  # Add sampled Poisson distributions up to get combined distribution
  z <- x + y
  # Analytical convolution of PMFs
  conv_pmf <- add_pmfs(list(xpmf, ypmf))
  conv_cdf <- cumsum(conv_pmf)
  # Empirical convolution of PMFs
  cdf <- ecdf(z)(0:41)
  expect_true(sum(abs(conv_cdf - cdf)) < 0.02)
})

test_that("add_pmfs returns the input PMF when only one is passed", {
  pmf <- c(0.1, 0.2, 0.3)
  expect_equal(add_pmfs(pmf), pmf)
  expect_equal(add_pmfs(list(pmf)), pmf)
})
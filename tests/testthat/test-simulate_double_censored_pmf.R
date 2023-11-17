test_that("simulate_double_censored_pmf() returns valid PMF", {
  pmf <- simulate_double_censored_pmf()
  expect_true(all(pmf >= 0))
  expect_equal(sum(pmf), 1, tolerance = 1e-5)
})

test_that("simulate_double_censored_pmf() handles custom distributions", {
  pmf <- simulate_double_censored_pmf(
    fun_primary = rnorm, fun_dist = rexp, rate = 2,
    primary_args = list(mean = 0, sd = 1)
  )
  expect_true(all(pmf >= 0))
  expect_equal(sum(pmf), 1, tolerance = 1e-5)
})

test_that("simulate_double_censored_pmf() handles default values", {
  pmf <- simulate_double_censored_pmf()
  expect_true(all(pmf >= 0))
  expect_equal(sum(pmf), 1, tolerance = 1e-5)
})

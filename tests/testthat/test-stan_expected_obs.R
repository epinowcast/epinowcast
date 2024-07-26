skip_on_cran()
skip_on_os("windows")
skip_on_os("mac")
skip_on_local()

enw_stan_to_r(
  c("expected_obs.stan", "hazard.stan"),
  system.file("stan", "functions", package = "epinowcast")
)
# note these tests require enw_stan_to_r() to be run first

test_that("expected_obs() aggregates probabilities correctly", {
  tar_obs <- 0
  lh <- c(0.1, 0.2, 0.3, 0.4)
  ref_as_p <- 1
  agg_probs <- 1
  agg_indicator <- matrix(c(0, 0, 0, 0,
                            1, 1, 0, 0,
                            0, 0, 0, 0,
                            0, 0, 1, 1), nrow = 4, byrow = TRUE)
  exp_obs <- expected_obs(tar_obs, lh, ref_as_p, agg_probs, agg_indicator)
  expect_equal(exp_obs, c(0.0, 0.3, 0.0, 0.7), tolerance = 1e-15)
  # Note below is only true since ref_as_p is 1
  expect_identical(sum(exp_obs), sum(lh))
})

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
  tar_obs <- log(1)
  lh <- log(
    (plnorm(1:30, 1.5, 2) - plnorm(0:29, 1.5, 2)) / plnorm(30, 1.5, 2)
    )
  agg_probs <- matrix(c(rep(0, times = 30 * 4),
                        rep(c(rep(1, times = 5),
                              rep(0, times = 6 * 5 + 30 * 4)),
                            times = 5),
                        rep(1, times = 5)), ncol = 30, byrow = TRUE)
  exp_obs <- expected_obs(tar_obs, lh, ref_as_p = 1, agg_probs = 1, agg_probs)
  exp_output <- as.vector(tar_obs + log(agg_probs %*% exp(lh)))
  expect_equal(object = exp_obs, expected = exp_output, tolerance = 1e-15)
})

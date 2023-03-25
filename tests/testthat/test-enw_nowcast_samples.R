test_that("enw_nowcast_samples can extract nowcast samples as expected", {
  fit <- enw_example("nowcast")
  expect_snapshot(
    round_numeric(enw_nowcast_samples(fit$fit[[1]], fit$latest[[1]])[1:10])
  )
})
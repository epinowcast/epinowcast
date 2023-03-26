test_that("enw_summarise_samples summarises samples as expected", {
  fit <- enw_example("nowcast")
  samples <- summary(fit, type = "nowcast_sample")
  summary <- enw_summarise_samples(samples, probs = c(0.05, 0.5, 0.95))
  expect_snapshot(summary[1:10])
})
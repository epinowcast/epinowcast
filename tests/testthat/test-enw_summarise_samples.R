test_that("enw_summarise_samples summarises samples as expected", {
  fit <- enw_example("nowcast")
  print(length(fit))
  samples <- summary(fit, type = "nowcast_sample")
  summary <- enw_summarise_samples(samples, probs = c(0.05, 0.5, 0.95))
  expect_snapshot(summary[1:10])
})

test_that(paste("enw_summarise_samples adds artificial samples",
                "when a delay smaller than specified was modelled"), {
  fit <- enw_example("nowcast")
  samples <- summary(fit, type = "nowcast_sample", max_delay = 22)
  summary <- enw_summarise_samples(samples, probs = c(0.05, 0.5, 0.95))
  expect_snapshot(summary[1:10])
})
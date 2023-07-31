test_that("enw_summarise_samples summarises samples as expected", {
  fit <- enw_example("nowcast")
  samples <- summary(fit, type = "nowcast_sample")
  summary <- enw_summarise_samples(samples, probs = c(0.05, 0.5, 0.95))
  expect_snapshot(summary[1:10])
})

test_that(paste("enw_summarise_samples adds artificial samples",
                "when a delay smaller than specified was modelled"), {
  fit <- enw_example("nowcast")
  fit$metamaxdelay[[1]] <- data.table::data.table(
    type = c("specified", "observed", "modelled"),
    delay = c(22, 41, 20),
    description = c(
      "maximum delay specified by the user",
      "maximum delay observed in the data",
      "maximum delay used in model"
    )
  )     
  samples <- summary(fit, type = "nowcast_sample")
  summary <- enw_summarise_samples(samples, probs = c(0.05, 0.5, 0.95))
  expect_snapshot(summary[1:10])
})
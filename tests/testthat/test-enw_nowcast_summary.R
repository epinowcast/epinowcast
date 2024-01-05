test_that(
  "enw_nowcast_summary can extract the summarised nowcast as expected",
  {
    fit <- enw_example("nowcast")
    nowcast <- enw_nowcast_summary(
      fit$fit[[1]], fit$latest[[1]], max_delay = fit$max_delay
    )
    expect_snapshot(
      round_numerics(nowcast[, c("rhat", "ess_bulk", "ess_tail") := NULL])
    )
  }
)

test_that("enw_nowcast_summary can extract the summarised nowcast with custom quantiles", {
  fit <- enw_example("nowcast")
  nowcast <- enw_nowcast_summary(
    fit$fit[[1]], fit$latest[[1]], max_delay = fit$max_delay,
    probs = c(0.05, 0.5, 0.95)
  )
  expect_snapshot(
    round_numerics(nowcast[, c("rhat", "ess_bulk", "ess_tail") := NULL])
  )
})

test_that(paste(
  "enw_nowcast_summary can extract the summarised nowcast as expected",
  "when a delay smaller than specified was modelled"
), {
  fit <- enw_example("nowcast")
  nowcast <- enw_nowcast_summary(
    fit$fit[[1]], fit$latest[[1]], max_delay = 22
  )
  expect_snapshot(
    round_numerics(nowcast[, c("rhat", "ess_bulk", "ess_tail") := NULL])
  )
})

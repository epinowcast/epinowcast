test_that("enw_add_latest_obs_to_nowcast can link nowcasts with more recent observations", {
  fit <- enw_example("nowcast")
  obs <- enw_example("obs")
  nowcast <- enw_nowcast_summary(
    fit$fit[[1]], fit$latest[[1]], probs = c(0.05, 0.5, 0.95)
  )
  nowcast <- enw_add_latest_obs_to_nowcast(nowcast, obs)
  expect_snapshot(
    nowcast[, c("rhat", "ess_bulk", "ess_tail") := NULL],
  )
})
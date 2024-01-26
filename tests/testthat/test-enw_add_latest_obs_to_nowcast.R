test_that("enw_add_latest_obs_to_nowcast can link nowcasts with more recent observations", { # nolint line_length
  fit <- enw_example("nowcast")
  obs <- enw_example("obs")
  nowcast <- summary(fit, type = "nowcast", probs = c(0.05, 0.5, 0.95))
  nowcast <- enw_add_latest_obs_to_nowcast(nowcast, obs)
  expect_snapshot(
    round_numerics(nowcast[, c("rhat", "ess_bulk", "ess_tail") := NULL])
  )
})

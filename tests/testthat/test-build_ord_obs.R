# Daily data
obs_daily <- enw_example("nowcast")$latest[[1]]
# Mock weekly data
obs_weekly <- data.table(
    reference_date = as.IDate("2021-07-28") + 7 * (0:6),
    report_date = c(as.IDate("2021-08-25") + 7 * (0:2),
                    rep(as.IDate("2021-09-08"), 4)),
    .group = rep(1, times = 7),
    max_confirm = c(625, 856, 1073, 1733, 2268, 2388, 1487),
    confirm = c(615, 847, 1073, 1733, 2268, 2388, 1487),
    cum_prop_reported = c(615 / 625, 847 / 856, rep(1, 5)),
    delay = c(rep(4, 3), 3:0)
)

# Will also need nowcast data if sampling - could be tough

# Test 1: No sampling, daily data
test_that("build_ord_obs() output matches snapshot with day timesteps", {
  max_delay <- 5
  timestep <- 7
  result <- build_ord_obs(obs_weekly, max_delay, timestep,
                       "no_sample")
  expect_snapshot(result)
})

# Test 2: No sampling, weekly data
test_that("build_ord_obs() output matches snapshot with week timesteps", {
  max_delay <- 5
  timestep <- 7
  result <- build_ord_obs(obs_weekly, max_delay, timestep,
                       "no_sample")
  expect_snapshot(result)
})

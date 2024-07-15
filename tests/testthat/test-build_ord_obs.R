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

# Mock nowcast draws
fit <- enw_example("nowcast")$fit[[1]]
nc <- fit$draws(variables = "pp_inf_obs", format = "draws_df")
nc <- coerce_dt(nc, required_cols = c(".chain", ".iteration", ".draw"))
nc <- melt(nc, value.name = "sample", variable.name = "variable",
           id.vars = c(".chain", ".iteration", ".draw"))

# Test 1: No sampling, daily data
test_that("build_ord_obs() output matches snapshot with day timesteps", {
  max_delay <- 5
  timestep <- 1
  result <- build_ord_obs(obs_daily, max_delay, timestep, timestep)
  expect_snapshot(result)
})

# Test 2: No sampling, weekly data
test_that("build_ord_obs() output matches snapshot with week timesteps", {
  max_delay <- 5
  timestep <- 7
  result <- build_ord_obs(obs_weekly, max_delay, timestep, timestep)
  expect_snapshot(result)
})

# Test 3: With sampling
test_that("build_ord_obs() output matches snapshot when sampling from posterior", { # nolint
    max_delay <- 14
    timestep <- 1
    result <- build_ord_obs(obs_daily, max_delay, timestep, timestep,
                            nc)
    expect_snapshot(result)
})

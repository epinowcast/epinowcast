# Daily data
obs_daily <- enw_example("nowcast")$latest[[1]]

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

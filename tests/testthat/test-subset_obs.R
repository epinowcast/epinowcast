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

# Test 1: Select "after" (daily)
test_that("select 'after' returns correct subset of reference dates when timesteps are days", { # nolint
  max_delay <- 5
  internal_timestep <- 1
  expected_cutoff <- max(obs_daily$reference_date) -
    max_delay * internal_timestep
  result <- subset_obs(obs_daily, max_delay, internal_timestep,
                       select = "after")
  expect_true(all(result$reference_date > expected_cutoff))
})

# Test 2: Select "before" (daily)
test_that("select 'before' returns correct subset of reference dates when timesteps are days", { # nolint
  max_delay <- 5
  internal_timestep <- 1
  expected_cutoff <- max(obs_daily$reference_date) -
    max_delay * internal_timestep
  result <- subset_obs(obs_daily, max_delay, internal_timestep,
                       select = "before")
  expect_true(all(result$reference_date <= expected_cutoff))
})

# Test 3: Select "after" (weekly)
test_that("select 'after' returns correct subset of reference dates when timesteps are days", { # nolint
  max_delay <- 5
  internal_timestep <- 1
  expected_cutoff <- max(obs_weekly$reference_date) -
    max_delay * internal_timestep
  result <- subset_obs(obs_weekly, max_delay, internal_timestep,
                       select = "after")
  expect_true(all(result$reference_date > expected_cutoff))
})

# Test 4: Select "before" (weekly)
test_that("select 'before' returns correct subset of reference dates when timesteps are days", { # nolint
  max_delay <- 5
  internal_timestep <- 1
  expected_cutoff <- max(obs_weekly$reference_date) -
    max_delay * internal_timestep
  result <- subset_obs(obs_weekly, max_delay, internal_timestep,
                       select = "before")
  expect_true(all(result$reference_date <= expected_cutoff))
})

# Test 5: Invalid select argument
test_that("invalid select argument throws an error", {
  expect_error(subset_obs(obs_daily, 5, 1, select = "invalid"))
})


# Test 6: Edge cases for max_delay
test_that("edge cases for max_delay are handled correctly", {
  # max_delay of 0
  result_zero_delay <- subset_obs(obs_daily, 0, 1, select = "after")
  expect_equal(nrow(result_zero_delay), 0)  # nolint

  # Very large max_delay
  large_delay <- 1000
  result_large_delay <- subset_obs(obs_daily, large_delay, 1, select = "after")
  expect_identical(nrow(result_large_delay), nrow(obs_daily))
})

# Snapshot test for subset_obs() with obs_weekly
test_that("subset_obs() output matches snapshot with week timesteps", {
  max_delay <- 5
  internal_timestep <- 7
  result <- subset_obs(obs_weekly, max_delay, internal_timestep,
                       select = "after")

  expect_snapshot(result)
})
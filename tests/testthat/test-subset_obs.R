# Daily data
obs_daily <- enw_example("nowcast")$latest[[1]]

# Test 1: Subset to modelled reference dates (daily)
test_that("subset_obs() returns correct subset of reference dates when timesteps are days", { # nolint
  max_delay <- 5
  internal_timestep <- 1
  expected_cutoff <- max(obs_daily$reference_date) -
    max_delay * internal_timestep
  # test modelled
  result <- subset_obs(obs_daily, max_delay, internal_timestep,
                       reference_subset = ">")
  expect_true(all(result$reference_date > expected_cutoff))
  expect_identical(as.integer(unique(diff(result$reference_date))),
                   as.integer(internal_timestep))
  # test not-modelled
  result <- subset_obs(obs_daily, max_delay, internal_timestep,
                       reference_subset = "<=")
  expect_true(all(result$reference_date <= expected_cutoff))
  expect_identical(as.integer(unique(diff(result$reference_date))),
                   as.integer(internal_timestep))
})

# Test 2: Subset to modelled reference dates (weekly)
test_that("subset_obs() returns correct subset of reference dates when timesteps are weeks", { # nolint
  max_delay <- 5
  internal_timestep <- 7
  expected_cutoff <- max(obs_weekly$reference_date) -
    max_delay * internal_timestep
  # test modelled
  result <- subset_obs(obs_weekly, max_delay, internal_timestep,
                       reference_subset = ">")
  expect_true(all(result$reference_date > expected_cutoff))
  expect_identical(as.integer(unique(diff(result$reference_date))),
                   as.integer(internal_timestep))
  # test not-modelled
  result <- subset_obs(obs_weekly, max_delay, internal_timestep,
                       reference_subset = "<=")
  expect_true(all(result$reference_date <= expected_cutoff))
  expect_identical(as.integer(unique(diff(result$reference_date))),
                   as.integer(internal_timestep))
})


# Test 3: Invalid reference_subset argument
test_that("subset_obs() throws an error when reference_subset is invalid", {
  expect_error(subset_obs(obs_daily, 5, 1, reference_subset = "invalid"))
})


# Test 6: Edge cases for max_delay
test_that("subset_obs() handles zero max_delay and large max_delay", {
  # max_delay of 0
  result_zero_delay <- subset_obs(obs_daily, 0, 1, reference_subset = ">")
  expect_equal(nrow(result_zero_delay), 0)  # nolint

  # Very large max_delay
  large_delay <- 1000
  result_large_delay <- subset_obs(obs_daily, large_delay, 1,
                                   reference_subset = ">")
  expect_identical(nrow(result_large_delay), nrow(obs_daily))
})

# Snapshot test for subset_obs() with obs_weekly
test_that("subset_obs() output matches snapshot with week timesteps", {
  max_delay <- 5
  internal_timestep <- 7
  result <- subset_obs(obs_weekly, max_delay, internal_timestep,
                       reference_subset = ">")

  expect_snapshot(result)
})

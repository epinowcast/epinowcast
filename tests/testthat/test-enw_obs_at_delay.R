test_that("enw_obs_at_delay returns expected output", {
  obs <- enw_example("preprocessed")$obs[[1]]
  result <- enw_obs_at_delay(obs, max_delay = 2)
  expect_data_table(result)
  expect_true(
    max(result$delay, na.rm = TRUE) <= 1
  )
  expect_identical(
    result,
    enw_latest_data(enw_filter_delay(obs, max_delay = 2))
  )
})

test_that("enw_obs_at_delay gives same result as manual steps", {
  obs <- enw_example("preprocessed")$obs[[1]]
  manual <- enw_filter_delay(
    obs, max_delay = 5, timestep = "day"
  )
  manual <- enw_latest_data(manual)
  result <- enw_obs_at_delay(
    obs, max_delay = 5, timestep = "day"
  )
  expect_identical(result, manual)
})

test_that("enw_obs_at_delay returns one row per reference date", {
  obs <- enw_example("preprocessed")$obs[[1]]
  result <- enw_obs_at_delay(obs, max_delay = 3)
  ref_dates <- result$reference_date[!is.na(result$reference_date)]
  expect_false(anyDuplicated(ref_dates) > 0)
})

test_that("enw_obs_at_delay preserves data.table structure", {
  obs <- enw_example("preprocessed")$obs[[1]]
  result <- enw_obs_at_delay(obs, max_delay = 3)
  expect_data_table(result)
  expect_true("reference_date" %in% names(result))
  expect_true("report_date" %in% names(result))
})

test_that("enw_obs_at_delay works with timestep = 'week'", {
  obs <- enw_example("preprocessed")$obs[[1]]
  result_week <- enw_obs_at_delay(obs, max_delay = 1, timestep = "week")
  result_day7 <- enw_obs_at_delay(obs, max_delay = 7, timestep = "day")
  expect_data_table(result_week)
  expect_identical(result_week, result_day7)
})

test_that("enw_obs_at_delay works with numeric timestep", {
  obs <- enw_example("preprocessed")$obs[[1]]
  result_num <- enw_obs_at_delay(obs, max_delay = 1, timestep = 7)
  result_week <- enw_obs_at_delay(obs, max_delay = 1, timestep = "week")
  expect_identical(result_num, result_week)
})

test_that("enw_obs_at_delay handles max_delay = 1", {
  obs <- enw_example("preprocessed")$obs[[1]]
  result <- enw_obs_at_delay(obs, max_delay = 1)
  expect_data_table(result)
  expect_true(all(result$delay == 0 | is.na(result$delay)))
})

test_that("enw_obs_at_delay handles large max_delay", {
  obs <- enw_example("preprocessed")$obs[[1]]
  max_obs_delay <- max(obs$delay, na.rm = TRUE)
  result <- enw_obs_at_delay(obs, max_delay = max_obs_delay + 10)
  expect_data_table(result)
  ref_dates <- result$reference_date[!is.na(result$reference_date)]
  expect_false(anyDuplicated(ref_dates) > 0)
})

test_that("enw_obs_at_delay with different max_delay values are consistent", {
  obs <- enw_example("preprocessed")$obs[[1]]
  result_small <- enw_obs_at_delay(obs, max_delay = 2)
  result_large <- enw_obs_at_delay(obs, max_delay = 5)
  shared_dates <- intersect(
    result_small$reference_date, result_large$reference_date
  )
  small_shared <- result_small[reference_date %in% shared_dates]
  large_shared <- result_large[reference_date %in% shared_dates]
  expect_true(
    all(small_shared$confirm <= large_shared$confirm, na.rm = TRUE)
  )
})

test_that("enw_obs_at_delay handles data with NA reference dates", {
  obs <- enw_example("preprocessed")$obs[[1]]
  na_rows <- obs[is.na(reference_date)]
  if (nrow(na_rows) > 0) {
    result <- enw_obs_at_delay(obs, max_delay = 3)
    expect_false(anyNA(result$reference_date))
  }
})

test_that("enw_obs_at_delay accepts data.frame input", {
  obs <- enw_example("preprocessed")$obs[[1]]
  obs_df <- as.data.frame(obs)
  result <- enw_obs_at_delay(obs_df, max_delay = 3)
  expect_data_table(result)
})

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

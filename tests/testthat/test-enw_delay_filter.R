test_that("enw_filter_delay() can filter for delays as expected", {
  obs <- enw_example("preprocessed")$obs[[1]]
  expect_identical(
    max(enw_filter_delay(obs, max_delay = 2)$delay, na.rm = TRUE),
    1
  )
})

test_that("enw_filter_delay() throws a warning when the empirical delay is less
           than the max specified", {
  obs <- enw_example("preprocessed")$obs[[1]]
  expect_warning(enw_filter_delay(obs, max_delay = 100))
})

test_that("enw_filter_delay() filters correctly for a week timestep", {
  obs <- data.frame(
    report_date = as.Date("2021-01-01") + 0:20,
    reference_date = as.Date("2021-01-01")
  )
  filtered_obs <- enw_filter_delay(obs, max_delay = 2, timestep = "week")
  expect_true(all(filtered_obs$report_date <= as.Date("2021-01-01") + 14))
  expect_true(all(filtered_obs$report_date >= as.Date("2021-01-01")))
})

test_that("enw_filter_delay() filters correctly for a 5 days timestep", {
  obs <- data.frame(
    report_date = as.Date("2021-01-01") + 0:20,
    reference_date = as.Date("2021-01-01")
  )
  filtered_obs <- enw_filter_delay(obs, max_delay = 2, timestep = 5)
  expect_true(all(filtered_obs$report_date <= as.Date("2021-01-01") + 10))
  expect_true(all(filtered_obs$report_date >= as.Date("2021-01-01")))
})

test_that("enw_filter_delay() throws a warning for week timestep when empirical
          delay is less", {
  obs <- data.frame(
    report_date = as.Date("2021-01-01") + 0:6,
    reference_date = as.Date("2021-01-01")
  )
  expect_warning(enw_filter_delay(obs, max_delay = 10, timestep = "week"))
})

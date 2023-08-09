# Initialize obs data for use across tests
obs <- data.table::data.table(
  location = c(rep("A", 50), rep("B", 50)),
  report_date = as.Date(rep(
    rep(seq(as.Date("2020-01-05"), by = "day", length.out = 5), each = 10), 2
  )),
  reference_date = as.Date(
    rep(
      replicate(5, seq(as.Date("2020-01-01"), by = "day", length.out = 10)),
      2
    )
  ),
  confirm = 1
)

test_that("enw_aggregate_cumulative() basic functionality works", {
  result <- enw_aggregate_cumulative(obs, timestep = "week", by = "location")
  expect_lt(nrow(result), nrow(obs))
})

test_that("Works with different timesteps", {
  # Test with a week
  result_week <- enw_aggregate_cumulative(obs, timestep = "week")
  
  # Test with a 5-day period
  result_5days <- enw_aggregate_cumulative(obs, timestep = "5 days")
  
  expect_lt(nrow(result_5days), nrow(obs))
  expect_gt(nrow(result_5days), nrow(result_week))
})

test_that("Works with and without groups", {
  # Without groups
  result_no_group <- enw_aggregate_cumulative(obs, timestep = "week")
  
  # With groups
  result_with_group <- enw_aggregate_cumulative(obs, timestep = "week", by = ".group")
  
  expect_equal(nrow(result_with_group), 2 * nrow(result_no_group))
  expect_equal(unique(result_with_group$.group), c("A", "B"))
})

test_that("Handles missing reference dates", {
  obs_with_na <- copy(obs)
  obs_with_na[1:5, reference_date := NA]
  
  result <- enw_aggregate_cumulative(obs_with_na, timestep = "week")
  expect_true(any(is.na(result$reference_date)))
})

test_that("Handles missing report dates", {
  obs_with_na <- copy(obs)
  obs_with_na[1:5, report_date := NA]
  
  result <- enw_aggregate_cumulative(obs_with_na, timestep = "week")
  expect_true(any(is.na(result$report_date)))
})

test_that("Handles both missing report and reference dates", {
  obs_with_na <- copy(obs)
  obs_with_na[1:3, report_date := NA]
  obs_with_na[7:9, reference_date := NA]
  
  result <- enw_aggregate_cumulative(obs_with_na, timestep = "week")
  expect_true(any(is.na(result$report_date)))
  expect_true(any(is.na(result$reference_date)))
})

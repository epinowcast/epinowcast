# Initialize obs data for use across tests
obs <- data.table::data.table(
  location = c(rep("A", 50), rep("B", 50)),
  report_date = as.Date(rep(
    rep(seq(as.Date("2020-01-05"), by = "day", length.out = 5), each = 10), 2
  ), origin = "1970-01-01"),
  reference_date = as.Date(
    rep(
      replicate(5, seq(as.Date("2020-01-01"), by = "day", length.out = 10)),
      2
    ),
    origin = "1970-01-01"
  ),
  confirm = 1
)

test_that("enw_aggregate_cumulative() basic functionality works", {
  obs <- obs[location == "A"]
  result <- enw_aggregate_cumulative(obs, timestep = "week")
  expect_identical(unique(result$confirm), 7) # 7 days in a week
})

test_that("enw_aggregate_cumulative() works with different timesteps", {
  obs <- obs[location == "A"]
  # Test with a week as numeric
  result_week <- enw_aggregate_cumulative(obs, timestep = 7)
  expect_identical(unique(result_week$confirm), 7)

  # Test with a 5-day period
  result_5days <- enw_aggregate_cumulative(obs, timestep = 5)
  expect_identical(unique(result_5days$confirm), 5)

  # Test with a 3-day period
  result_5days <- enw_aggregate_cumulative(obs, timestep = 3)
  expect_identical(unique(result_5days$confirm), 3)
})

test_that("enw_aggregate_cumulative() with groups", {
  # With groups
  result_with_group <- enw_aggregate_cumulative(
    obs,
    timestep = "week", by = "location"
  )
  expect_identical(unique(result_with_group$confirm), 7)
})

test_that("enw_aggregate_cumulative() handles missing reference dates", {
  obs_with_na <- obs[location == "A"]
  setorder(obs_with_na, location, reference_date)
  obs_with_na[1:5, reference_date := NA]

  result <- enw_aggregate_cumulative(obs_with_na, timestep = 3)
  expect_true(anyNA(result$reference_date))
  expect_identical(result$confirm[1], 1)
  expect_identical(unique(result[-1, ]$confirm), 3)
})

test_that("enw_aggregate_cumulative() handles missing report dates", {
  obs_with_na <- obs[location == "A"]
  obs_with_na[1:5, report_date := NA]
  result <- enw_aggregate_cumulative(obs_with_na, timestep = "week")
  expect_identical(unique(result$confirm), 7)
})

test_that(
  "enw_aggregate_cumulative() when there are no complete report dates",
  {
    obs_no_complete <- obs[location == "A"]
    obs_no_complete <- obs_no_complete[1:20, ]
    expect_error(
      enw_aggregate_cumulative(obs_no_complete, timestep = "week"),
      "There are no complete report dates"
    )
  }
)

test_that("enw_aggregate_cumulative() when timestep is set to 'day'", {
  obs_day <- obs[location == "A"]
  expect_error(
    enw_aggregate_cumulative(obs_day, timestep = "day"),
    "The data already has a timestep of a day"
  )
})

test_that("enw_aggregate_cumulative() handles missing values in 'confirm'", {
  obs_na_confirm <- obs[location == "A"]
  obs_na_confirm[1:5, confirm := NA]
  result <- enw_aggregate_cumulative(obs_na_confirm, timestep = "week")
  expect_identical(unique(result$confirm), 7)
})

test_that("enw_aggregate_cumulative() when 'by' grouping does not exist", {
  expect_error(
    enw_aggregate_cumulative(
      obs,
      timestep = "week", by = "non_existent_column"
    )
  )
})

test_that("enw_aggregate_cumulative() when 'obs' is empty", {
  obs_empty <- obs[0]
  expect_error(
    enw_aggregate_cumulative(obs_empty, timestep = "week"),
    "There must be at least two observations"
  )
})

test_that(
  "enw_aggregate_cumulative() works as expected with weekly reported data",
  {
    data <- data.table(
      report_date = as.Date(c(
        "2022-10-25", "2022-11-01", "2022-11-01", "2022-11-01", "2022-11-01",
        "2022-11-01", "2022-11-01", "2022-11-01", "2022-11-01", "2022-11-08",
        "2022-11-08", "2022-11-08", "2022-11-08", "2022-11-08", "2022-11-08",
        "2022-11-08", "2022-11-08", "2022-11-08", "2022-11-08", "2022-11-08"
      )),
      reference_date = as.Date(c(
        "2022-10-22", "2022-10-22", "2022-10-23", "2022-10-24", "2022-10-25",
        "2022-10-26", "2022-10-27", "2022-10-28", "2022-10-29", "2022-10-22",
        "2022-10-23", "2022-10-24", "2022-10-25", "2022-10-26", "2022-10-27",
        "2022-10-28", "2022-10-29", "2022-10-30", "2022-10-31", "2022-11-01"
      )),
      confirm = c(
        34, 46, 47, 41, 68, 59, 62, 30, 40,
        48, 53, 46, 75, 67, 84, 47, 67, 69, 81, 88
      )
    )
    expected_agg <- data.table(
      report_date = as.IDate(c(
        "2022-10-28", "2022-11-04", "2022-11-04"
      )),
      reference_date = as.IDate(c(
        "2022-10-28", "2022-10-28", "2022-11-04"
      )),
      confirm = c(34, 353, 40)
    )
    daily <- enw_complete_dates(data, missing_reference = FALSE)
    actual_agg <- enw_aggregate_cumulative(daily, timestep = "week")
    expect_identical(actual_agg, expected_agg)
  }
)

test_that(
  "enw_aggregate_cumulative() works as expected with a custom min_date",
  {
    data <- data.table(
      report_date = as.Date(c(
        "2022-10-25", "2022-11-01", "2022-11-01", "2022-11-01", "2022-11-01",
        "2022-11-01", "2022-11-01", "2022-11-01", "2022-11-01", "2022-11-08",
        "2022-11-08", "2022-11-08", "2022-11-08", "2022-11-08", "2022-11-08",
        "2022-11-08", "2022-11-08", "2022-11-08", "2022-11-08", "2022-11-08"
      )),
      reference_date = as.Date(c(
        "2022-10-22", "2022-10-22", "2022-10-23", "2022-10-24", "2022-10-25",
        "2022-10-26", "2022-10-27", "2022-10-28", "2022-10-29", "2022-10-22",
        "2022-10-23", "2022-10-24", "2022-10-25", "2022-10-26", "2022-10-27",
        "2022-10-28", "2022-10-29", "2022-10-30", "2022-10-31", "2022-11-01"
      )),
      confirm = c(
        34, 46, 47, 41, 68, 59, 62, 30, 40,
        48, 53, 46, 75, 67, 84, 47, 67, 69, 81, 88
      )
    )
    expected_agg <- data.table(
      report_date = as.IDate(
        c(
          "2022-10-25", "2022-11-01", "2022-11-08", "2022-11-01", "2022-11-08",
          "2022-11-08"
        )
      ),
      reference_date = as.IDate(
        c(
          "2022-10-25", "2022-10-25", "2022-10-25", "2022-11-01", "2022-11-01",
          "2022-11-08"
        )
      ),
      confirm = c(34, 202, 222, 191, 503, 0)
    )
    expected_agg <- expected_agg[
      report_date != as.Date("2022-10-25")
    ][reference_date != as.Date("2022-10-25")]
    daily <- enw_complete_dates(data, missing_reference = FALSE)
    actual_agg <- enw_aggregate_cumulative(
      daily,
      timestep = "week", min_reference_date = min(data$report_date) + 1
    )
    expect_identical(actual_agg, expected_agg)
  }
)

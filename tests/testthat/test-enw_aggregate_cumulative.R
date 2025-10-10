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
  expect_identical(unique(result$confirm), 1)
})

test_that("enw_aggregate_cumulative() works with different timesteps", {
  obs <- obs[location == "A"]
  # Test with a week as numeric
  result_week <- enw_aggregate_cumulative(obs, timestep = 7)
  expect_identical(unique(result_week$confirm), 1)

  # Test with a 5-day period
  result_5days <- enw_aggregate_cumulative(obs, timestep = 5)
  expect_identical(unique(result_5days$confirm), 1)

  # Test with a 3-day period
  result_5days <- enw_aggregate_cumulative(obs, timestep = 3)
  expect_identical(unique(result_5days$confirm), c(1, 4))
})

test_that("enw_aggregate_cumulative() with groups", {
  # With groups
  result_with_group <- enw_aggregate_cumulative(
    obs,
    timestep = "week", by = "location"
  )
  expect_identical(unique(result_with_group$confirm), 1)
})

test_that("enw_aggregate_cumulative() handles missing reference dates", {
  obs_with_na <- obs[location == "A"]
  setorder(obs_with_na, location, reference_date)
  obs_with_na[1:5, reference_date := NA]

  result <- enw_aggregate_cumulative(obs_with_na, timestep = 3)
  expect_true(anyNA(result$reference_date))
  expect_identical(result$confirm[1], 1)
  expect_identical(unique(result[-1, ]$confirm), c(4, 1))
})

test_that("enw_aggregate_cumulative() handles missing report dates", {
  obs_with_na <- obs[location == "A"]
  obs_with_na[1:5, report_date := NA]
  result <- enw_aggregate_cumulative(obs_with_na, timestep = "week")
  expect_identical(unique(result$confirm), 1)
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
  expect_identical(unique(result$confirm), 1)
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
      confirm = c(0, 120, 0)
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
          "2022-11-01", "2022-11-08", "2022-11-08"
        )
      ),
      reference_date = as.IDate(
        c(
          "2022-11-01", "2022-11-01", "2022-11-08"
        )
      ),
      confirm = c(0, 88, 0)
    )
    daily <- enw_complete_dates(data, missing_reference = FALSE)
    actual_agg <- enw_aggregate_cumulative(
      daily,
      timestep = "week", min_reference_date = min(data$report_date) + 1
    )
    expect_identical(actual_agg, expected_agg)
  }
)

test_that("enw_aggregate_cumulative preserves monotonic cumulative property
           at timestep boundaries (issue #511)", {
  # Create test data matching exact scenario from issue:
  # 6 weeks of daily data with max_delay = 14 days
  reference_dates <- seq(
    as.Date("2023-01-01"),
    as.Date("2023-02-11"),  # 6 weeks
    by = "day"
  )

  # Generate reports with delays up to 14 days
  test_data <- data.table::data.table(
    reference_date = rep(reference_dates, each = 15),  # 0-14 day delays
    delay = rep(0:14, length(reference_dates))
  )
  test_data[, report_date := reference_date + delay]
  test_data[, confirm := rpois(.N, lambda = 10)]

  # Keep only reports up to a fixed max report date
  max_report <- max(reference_dates) + 14
  test_data <- test_data[report_date <= max_report]

  # Aggregate to weekly timestep (the problematic case)
  result <- enw_aggregate_cumulative(
    test_data,
    timestep = "week",
    copy = TRUE
  )

  # Verify cumulative property: for each reference_date,
  # cumulative counts must be monotonically non-decreasing
  result <- result[order(reference_date, report_date)]

  # Check each reference date separately
  reference_dates_weekly <- unique(result$reference_date)

  for (ref_date in reference_dates_weekly) {
    subset_data <- result[reference_date == ref_date]
    cumulative_counts <- subset_data$confirm

    # Verify no decreases
    diffs <- diff(cumulative_counts)
    expect_true(
      all(diffs >= 0),
      label = paste0(
        "Cumulative counts decreased for reference_date ",
        ref_date
      )
    )

    # Additional check: cumulative counts should be >= 0
    expect_true(all(cumulative_counts >= 0))
  }

  # Verify result structure
  expect_data_table(result)
  expect_true("reference_date" %in% names(result))
  expect_true("report_date" %in% names(result))
  expect_true("confirm" %in% names(result))
})

test_that("enw_aggregate_cumulative handles edge case with exact max_delay
           multiple", {
  # Test with max_delay = 21 days and timestep = week (21 = 3 * 7)
  dates <- seq(as.Date("2023-01-01"), as.Date("2023-01-14"), by = "day")

  test_data <- data.table::data.table(
    reference_date = rep(dates, each = 22),
    delay = rep(0:21, length(dates))
  )
  test_data[, report_date := reference_date + delay]
  test_data[, confirm := rpois(.N, lambda = 5)]
  test_data <- test_data[report_date <= max(dates) + 21]

  result <- enw_aggregate_cumulative(
    test_data,
    timestep = "week",
    copy = TRUE
  )

  # Verify no negative differences
  result <- result[order(reference_date, report_date)]
  for (ref_date in unique(result$reference_date)) {
    subset_data <- result[reference_date == ref_date]
    diffs <- diff(subset_data$confirm)
    expect_true(all(diffs >= 0))
  }
})

test_that("enw_aggregate_cumulative preserves cumulative property with
           grouping", {
  # Test with 'by' grouping to ensure fix works with groups
  dates <- seq(as.Date("2023-01-01"), as.Date("2023-01-21"), by = "day")

  # Create data for each location separately to ensure daily timestep
  test_data_a <- data.table::data.table(
    reference_date = rep(dates, each = 15),
    delay = rep(0:14, length(dates)),
    location = "A"
  )
  test_data_a[, report_date := reference_date + delay]
  test_data_a[, confirm := rpois(.N, lambda = 8)]

  test_data_b <- data.table::data.table(
    reference_date = rep(dates, each = 15),
    delay = rep(0:14, length(dates)),
    location = "B"
  )
  test_data_b[, report_date := reference_date + delay]
  test_data_b[, confirm := rpois(.N, lambda = 8)]

  test_data <- rbind(test_data_a, test_data_b)
  test_data <- test_data[report_date <= max(dates) + 14]

  result <- enw_aggregate_cumulative(
    test_data,
    timestep = "week",
    by = "location",
    copy = TRUE
  )

  # Check each location separately
  for (loc in c("A", "B")) {
    loc_data <- result[location == loc]
    loc_data <- loc_data[order(reference_date, report_date)]

    for (ref_date in unique(loc_data$reference_date)) {
      subset_data <- loc_data[reference_date == ref_date]
      diffs <- diff(subset_data$confirm)
      expect_true(
        all(diffs >= 0),
        label = paste0("Counts decreased for location ", loc)
      )
    }
  }
})

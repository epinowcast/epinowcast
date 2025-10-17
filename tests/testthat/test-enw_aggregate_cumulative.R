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
  result_3days <- enw_aggregate_cumulative(obs, timestep = 3)
  expect_identical(sort(unique(result_3days$confirm)), c(0, 1, 2, 3))
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
  # enw_complete_dates() is called with missing_reference = FALSE
  expect_false(anyNA(result$reference_date))
  expect_identical(sort(unique(result$confirm)), c(0, 1, 3))
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
      report_date = as.IDate(c(
        "2022-11-01", "2022-11-08", "2022-11-08"
      )),
      reference_date = as.IDate(c(
        "2022-11-01", "2022-11-01", "2022-11-08"
      )),
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

test_that("enw_aggregate_cumulative() fixes issue #511: cumulative counts
           should not decrease at timestep boundaries", {
  # Reproduce exact scenario from issue #511
  # 6 weeks of data with max delay of 2 weeks (14 days)
  ref_dates <- seq.Date(as.Date("2000-01-01"), by = "day", length.out = 6 * 7)
  rep_dates <- seq.Date(
    as.Date("2000-01-01"), by = "day",
    length.out = 6 * 7 + 14
  )

  ref_dates <- rep(ref_dates, each = 6 * 7 + 14)
  rep_dates <- rep(rep_dates, times = 6 * 7)

  dates_df <- data.frame(reference_date = ref_dates, report_date = rep_dates)
  dates_df <- dates_df |>
    dplyr::filter(reference_date <= report_date) |>
    # enforce max delay of 2 weeks in the toy data
    dplyr::filter(report_date <= reference_date + 14) |>
    dplyr::mutate(new_confirm = rpois(length(reference_date), 10)) |>
    dplyr::group_by(reference_date) |>
    dplyr::mutate(confirm = cumsum(new_confirm)) |>
    dplyr::ungroup()

  # Convert to data.table
  dates_df <- data.table::as.data.table(dates_df)
  dates_df[, new_confirm := NULL]

  # Aggregate to weekly timestep
  agg <- enw_aggregate_cumulative(dates_df, timestep = "week")

  # Verify cumulative property: for each reference_date,
  # confirm should be monotonically non-decreasing
  agg <- agg[order(reference_date, report_date)]

  for (ref_date in unique(agg$reference_date)) {
    subset_data <- agg[reference_date == ref_date]
    cumulative_counts <- subset_data$confirm

    # Check no decreases (issue #511 bug was that counts decreased)
    if (length(cumulative_counts) > 1) {
      diffs <- diff(cumulative_counts)
      expect_true(
        all(diffs >= 0),
        label = paste0(
          "Cumulative counts should not decrease for reference_date ",
          ref_date, " but found negative diff"
        )
      )
    }
  }
})

test_that("enw_aggregate_cumulative() throws error for month timestep", {
  obs <- data.table::data.table(
    reference_date = as.Date(
      rep(seq(as.Date("2020-01-01"), by = "day", length.out = 40), 40),
      origin = "1970-01-01"
    ),
    report_date = as.Date(rep(
      seq(as.Date("2020-01-01"), by = "day", length.out = 40), each = 40),
      origin = "1970-01-01"),
    confirm = 1
  )
  obs <- obs[report_date < as.Date("2020-01-15") & report_date >= reference_date, ]
  data.table::setorderv(obs, "reference_date")

  expect_error(
    enw_aggregate_cumulative(obs, timestep = "month"),
    "Calendar months are not currently supported"
  )
})

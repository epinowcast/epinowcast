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
  # Filter out 0s added by enw_add_incidence()
  expect_identical(unique(result$confirm[result$confirm > 0]), 7)
})

test_that("enw_aggregate_cumulative() works with different timesteps", {
  obs <- obs[location == "A"]
  # Test with a week as numeric
  result_week <- enw_aggregate_cumulative(obs, timestep = 7)
  expect_identical(unique(result_week$confirm[result_week$confirm > 0]), 7)

  # Test with a 5-day period
  result_5days <- enw_aggregate_cumulative(obs, timestep = 5)
  expect_identical(unique(result_5days$confirm[result_5days$confirm > 0]), 5)

  # Test with a 3-day period
  result_5days <- enw_aggregate_cumulative(obs, timestep = 3)
  expect_identical(unique(result_5days$confirm[result_5days$confirm > 0]), 3)
})

test_that("enw_aggregate_cumulative() with groups", {
  # With groups
  result_with_group <- enw_aggregate_cumulative(
    obs,
    timestep = "week", by = "location"
  )
  expect_identical(
    unique(result_with_group$confirm[result_with_group$confirm > 0]),
    7
  )
})

test_that("enw_aggregate_cumulative() handles missing reference dates", {
  obs_with_na <- obs[location == "A"]
  setorder(obs_with_na, location, reference_date)
  obs_with_na[1:5, reference_date := NA]

  result <- enw_aggregate_cumulative(obs_with_na, timestep = 3)
  expect_true(anyNA(result$reference_date))
  # NA reference date rows are aggregated
  result_na <- result[is.na(reference_date)]
  expect_true(all(result_na$confirm >= 0))
  # Non-NA rows should have confirm values of 0 or 3
  expect_identical(
    unique(result[!is.na(reference_date)]$confirm[
      result[!is.na(reference_date)]$confirm > 0
    ]),
    3
  )
})

test_that("enw_aggregate_cumulative() handles missing report dates", {
  obs_with_na <- obs[location == "A"]
  obs_with_na[1:5, report_date := NA]
  result <- enw_aggregate_cumulative(obs_with_na, timestep = "week")
  expect_identical(unique(result$confirm[result$confirm > 0]), 7)
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
  expect_identical(unique(result$confirm[result$confirm > 0]), 7)
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
    # Filter to key columns and non-NA reference dates
    actual_agg_filtered <- actual_agg[
      !is.na(reference_date),
      .(report_date, reference_date, confirm)
    ]
    # Remove sorted attribute for comparison
    setattr(actual_agg_filtered, "sorted", NULL)
    expect_identical(actual_agg_filtered, expected_agg)
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
    # Filter to key columns and non-NA reference dates
    actual_agg_filtered <- actual_agg[
      !is.na(reference_date),
      .(report_date, reference_date, confirm)
    ]
    # Remove sorted attribute for comparison
    setattr(actual_agg_filtered, "sorted", NULL)
    expect_identical(actual_agg_filtered, expected_agg)
  }
)

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
  obs <- obs[
    report_date < as.Date("2020-01-15") & report_date >= reference_date,
  ]
  data.table::setorderv(obs, "reference_date")

  expect_error(
    enw_aggregate_cumulative(obs, timestep = "month"),
    "Calendar months are not currently supported"
  )
})

test_that(
  paste(
    "enw_aggregate_cumulative() correctly handles max_delay as",
    "even multiple of timestep (issue 511)"
  ),
  {
    # Exact example from issue #511
    # 6 weeks of data with max delay of 2 weeks (14 days)
    ref_dates <- seq.Date(
      as.Date("2000-01-01"), by = "day",
      length.out = 6 * 7
    )
    rep_dates <- seq.Date(
      as.Date("2000-01-01"), by = "day",
      length.out = 6 * 7 + 14
    )

    ref_dates <- rep(ref_dates, each = 6 * 7 + 14)
    rep_dates <- rep(rep_dates, times = 6 * 7)

    dates_df <- data.frame(
      reference_date = ref_dates,
      report_date = rep_dates
    )
    dates_df <- dates_df |>
      dplyr::filter(reference_date <= report_date) |>
      dplyr::filter(report_date <= reference_date + 14) |>
      dplyr::mutate(new_confirm = rpois(length(reference_date), 10)) |>
      dplyr::group_by(reference_date) |>
      dplyr::mutate(confirm = cumsum(new_confirm)) |>
      dplyr::ungroup()

    dates_df <- as.data.table(dates_df)

    # Aggregate to weekly
    agg <- enw_aggregate_cumulative(dates_df, timestep = "week")

    # Key test: confirm values should be non-decreasing (cumulative)
    # for each reference date across report dates
    agg[,
      is_cumulative := all(confirm == cummax(confirm)),
      by = reference_date
    ]
    expect_true(all(agg$is_cumulative, na.rm = TRUE))
  }
)

test_that(
  paste(
    "enw_aggregate_cumulative() drops incomplete timesteps as expected",
    "(issue 427)"
  ),
  {
    # Test that incomplete timesteps are correctly dropped
    obs <- data.table(
      reference_date = as.IDate(
        rep(seq(as.Date("2020-01-01"), by = "day", length.out = 10), 10)
      ),
      report_date = as.IDate(
        rep(seq(as.Date("2020-01-01"), by = "day", length.out = 10), each = 10)
      ),
      confirm = 1
    )
    obs <- obs[report_date >= reference_date]

    # Aggregate to 3-day timestep
    agg <- enw_aggregate_cumulative(obs, timestep = 3)

    # Should only have complete 3-day timesteps
    # Original has reference dates 01-01 to 01-10 (10 days)
    # Complete 3-day timesteps: 01-03, 01-06, 01-09 (3 reference dates)
    # 01-10 should be dropped as incomplete
    expect_identical(
      sort(unique(agg$reference_date[!is.na(agg$reference_date)])),
      as.IDate(c("2020-01-03", "2020-01-06", "2020-01-09"))
    )

    # Counts are correctly aggregated for complete timesteps
    obs_with_inc <- enw_add_incidence(obs)
    agg_with_inc <- enw_add_incidence(agg)

    # Total should be less due to dropped incomplete timestep
    total_original <- sum(obs_with_inc$new_confirm, na.rm = TRUE)
    total_agg <- sum(agg_with_inc$new_confirm, na.rm = TRUE)

    expect_lt(total_agg, total_original)
  }
)

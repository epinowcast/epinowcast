test_that("enw_filter_reference_dates filters as expected", {
  expect_error(enw_filter_reference_dates(
    germany_covid19_hosp,
    include_days = 10, earliest_date = "2021-09-01"
  ))
  filt_date <- enw_filter_reference_dates(
    germany_covid19_hosp,
    earliest_date = "2021-09-01"
  )
  expect_identical(max(filt_date$report_date), as.IDate("2021-10-20"))
  expect_identical(max(filt_date$reference_date), as.IDate("2021-10-20"))
  expect_identical(min(filt_date$report_date), as.IDate("2021-09-01"))
  expect_identical(min(filt_date$reference_date), as.IDate("2021-09-01"))
  filt_days <- enw_filter_reference_dates(
    germany_covid19_hosp,
    include_days = 10
  )
  expect_identical(max(filt_days$report_date), as.IDate("2021-10-20"))
  expect_identical(max(filt_days$reference_date), as.IDate("2021-10-20"))
  expect_identical(min(filt_days$report_date), as.IDate("2021-10-11"))
  expect_identical(min(filt_days$reference_date), as.IDate("2021-10-11"))
  # Verify exact count of dates
  n_dates <- length(unique(filt_days$reference_date))
  expect_identical(n_dates, 10L)

  expect_error(enw_filter_reference_dates(
    germany_covid19_hosp,
    remove_days = 10, latest_date = "2021-10-01"
  ))
  filt_date <- enw_filter_reference_dates(
    germany_covid19_hosp,
    latest_date = "2021-10-01"
  )
  expect_identical(max(filt_date$report_date), as.IDate("2021-10-20"))
  expect_identical(max(filt_date$reference_date), as.IDate("2021-10-01"))
  expect_identical(min(filt_date$report_date), as.IDate("2021-04-06"))
  expect_identical(min(filt_date$reference_date), as.IDate("2021-04-06"))
  filt_days <- enw_filter_reference_dates(
    germany_covid19_hosp,
    remove_days = 10
  )
  expect_identical(max(filt_days$report_date), as.IDate("2021-10-20"))
  expect_identical(max(filt_days$reference_date), as.IDate("2021-10-10"))
  expect_identical(min(filt_days$report_date), as.IDate("2021-04-06"))
  expect_identical(min(filt_days$reference_date), as.IDate("2021-04-06"))
})

test_that("enw_filter_reference_dates filters as expected when data is present with missing reference dates", { # nolint: line_length_linter.
  nat_germany_hosp <-
    germany_covid19_hosp[location == "DE"][age_group == "00+"]
  nat_germany_hosp <- enw_complete_dates(
    nat_germany_hosp,
    by = c("location", "age_group")
  )
  filt_days <- enw_filter_reference_dates(
    nat_germany_hosp,
    include_days = 10
  )
  expect_identical(max(filt_days$report_date), as.IDate("2021-10-20"))
  expect_identical(
    max(filt_days$reference_date, na.rm = TRUE), as.IDate("2021-10-20")
  )
  expect_identical(min(filt_days$report_date), as.IDate("2021-10-11"))
  expect_identical(
    min(filt_days$reference_date, na.rm = TRUE), as.IDate("2021-10-11")
  )
  # Verify exact count of dates
  n_dates <- length(unique(filt_days$reference_date[!is.na(filt_days$reference_date)]))
  expect_identical(n_dates, 10L)
  filt_date <- enw_filter_reference_dates(
    nat_germany_hosp,
    earliest_date = "2021-09-01"
  )
  expect_identical(max(filt_date$report_date), as.IDate("2021-10-20"))
  expect_identical(
    max(filt_date$reference_date, na.rm = TRUE), as.IDate("2021-10-20")
  )
  expect_identical(min(filt_date$report_date), as.IDate("2021-09-01"))
  expect_identical(
    min(filt_date$reference_date, na.rm = TRUE), as.IDate("2021-09-01")
  )
})

test_that("enw_filter_reference_dates works with both include and remove days under missing data", { # nolint: line_length_linter.
  nat_germany_hosp <-
    germany_covid19_hosp[location == "DE"][age_group == "00+"]
  nat_germany_hosp <- enw_complete_dates(
    nat_germany_hosp,
    by = c("location", "age_group")
  )
  filt_date <- enw_filter_reference_dates(
    nat_germany_hosp,
    include_days = 5,
    remove_days = 2
  )
  expect_snapshot(filt_date)
})

test_that("enw_filter_reference_dates handles include_days = 0 correctly", {
  latest_date <- as.IDate("2021-10-20")
  include_days <- 0
  filtered <- enw_filter_reference_dates(
    germany_covid19_hosp,
    latest_date = latest_date,
    include_days = include_days
  )

  # Should return empty data.table
  expect_identical(nrow(filtered), 0L)
  expect_s3_class(filtered, "data.table")
})

test_that("enw_filter_reference_dates handles include_days = 1 correctly", {
  latest_date <- as.IDate("2021-10-20")
  include_days <- 1
  filtered <- enw_filter_reference_dates(
    germany_covid19_hosp,
    latest_date = latest_date,
    include_days = include_days
  )

  # Should return only the most recent date
  n_dates <- length(unique(filtered$reference_date))
  expect_identical(n_dates, 1L)
  expect_identical(min(filtered$reference_date), as.IDate("2021-10-20"))
  expect_identical(max(filtered$reference_date), as.IDate("2021-10-20"))
})

test_that("enw_filter_reference_dates handles include_days = 2 correctly", {
  latest_date <- as.IDate("2021-10-20")
  include_days <- 2
  filtered <- enw_filter_reference_dates(
    germany_covid19_hosp,
    latest_date = latest_date,
    include_days = include_days
  )

  # Should return exactly 2 days
  n_dates <- length(unique(filtered$reference_date))
  expect_identical(n_dates, 2L)
  expect_identical(min(filtered$reference_date), as.IDate("2021-10-19"))
  expect_identical(max(filtered$reference_date), as.IDate("2021-10-20"))
})

test_that("enw_filter_reference_dates returns correct count for various include_days", { # nolint: line_length_linter.
  latest_date <- as.IDate("2021-10-20")

  test_cases <- c(5, 10, 15, 20)

  for (days in test_cases) {
    filtered <- enw_filter_reference_dates(
      germany_covid19_hosp,
      latest_date = latest_date,
      include_days = days
    )
    n_dates <- length(unique(filtered$reference_date))
    expect_identical(
      n_dates,
      as.integer(days),
      label = sprintf(
        "include_days = %d should return exactly %d dates", days, days
      )
    )
  }
})

test_that("enw_filter_reference_dates preserves data structure after fix", {
  latest_date <- as.IDate("2021-10-20")
  include_days <- 10
  filtered <- enw_filter_reference_dates(
    germany_covid19_hosp,
    latest_date = latest_date,
    include_days = include_days
  )

  # Check all expected columns present
  expected_cols <- c(
    "reference_date", "report_date", "confirm", "age_group", "location"
  )
  expect_true(all(expected_cols %in% names(filtered)))

  # Check data.table class preserved
  expect_s3_class(filtered, "data.table")

  # Check no NA reference dates in filtered result
  expect_false(anyNA(filtered$reference_date))
})

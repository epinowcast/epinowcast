# Use germany data like other preprocessing tests
nat_germany_hosp <- germany_covid19_hosp[location == "DE"][age_group == "00+"]

test_that("enw_structural_reporting_metadata creates correct grid structure", {
  pobs <- enw_preprocess_data(nat_germany_hosp, max_delay = 5)

  metadata <- enw_structural_reporting_metadata(pobs)

  # Check it's a data.table
  expect_data_table(metadata)

  # Check required columns
  expect_true(all(c(".group", "date", "report_date") %in% names(metadata)))

  # Check report_date is reference date + delay
  expect_true(all(metadata$report_date >= metadata$date))
  expect_true(all(metadata$report_date - metadata$date < pobs$max_delay))

  # Check complete grid
  n_groups <- pobs$groups[[1]]
  n_times <- pobs$time[[1]]
  max_delay <- pobs$max_delay
  expected_rows <- n_groups * n_times * max_delay
  expect_equal(nrow(metadata), expected_rows)
})

test_that("enw_dayofweek_structural_reporting works with single weekday", {
  pobs <- enw_preprocess_data(nat_germany_hosp, max_delay = 5)

  structural <- enw_dayofweek_structural_reporting(
    pobs, day_of_week = "Wednesday"
  )

  # Check it's a data.table
  expect_data_table(structural)

  # Check required columns
  required_cols <- c(".group", "date", "report_date", "report")
  expect_true(all(required_cols %in% names(structural)))

  # Check report column is binary
  expect_true(all(structural$report %in% c(0, 1)))

  # Check Wednesday reporting
  structural[, day_name := weekdays(report_date)]
  expect_true(all(structural[day_name == "Wednesday"]$report == 1))
  expect_true(all(structural[day_name != "Wednesday"]$report == 0))
})

test_that("enw_dayofweek_structural_reporting works with multiple weekdays", {
  pobs <- enw_preprocess_data(nat_germany_hosp, max_delay = 5)

  structural <- enw_dayofweek_structural_reporting(
    pobs, day_of_week = c("Monday", "Wednesday", "Friday")
  )

  # Check report column
  expect_true(all(structural$report %in% c(0, 1)))

  # Check multiple day reporting
  structural[, day_name := weekdays(report_date)]
  reporting_days <- c("Monday", "Wednesday", "Friday")
  expect_true(all(structural[day_name %in% reporting_days]$report == 1))
  expect_true(all(structural[!day_name %in% reporting_days]$report == 0))
})

test_that("enw_dayofweek_structural_reporting maintains grid structure", {
  pobs <- enw_preprocess_data(nat_germany_hosp, max_delay = 5)

  structural <- enw_dayofweek_structural_reporting(
    pobs, day_of_week = "Wednesday"
  )

  # Check complete grid
  n_groups <- pobs$groups[[1]]
  n_times <- pobs$time[[1]]
  max_delay <- pobs$max_delay
  expected_rows <- n_groups * n_times * max_delay
  expect_equal(nrow(structural), expected_rows)

  # Check sorted by group, date, report_date
  expect_true(
    all(structural[, .I] ==
        structural[order(.group, date, report_date), .I])
  )
})

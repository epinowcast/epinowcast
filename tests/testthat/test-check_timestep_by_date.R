test_that("check_timestep_by_date() handles dates and groups correctly", {
  # Create a dataset with two date columns, two groups, and multiple reference
  # dates for each report date
  obs <- data.table::data.table(
    .group = c(rep("A", 50), rep("B", 50)),
    report_date = as.Date(rep(
      rep(seq(as.Date("2020-01-01"), by = "day", length.out = 5), each = 10), 2
    ), origin = "1970-01-01"),
    reference_date = as.Date(
      rep(
        replicate(5, seq(as.Date("2020-01-01"), by = "day", length.out = 10)),
        2
      ),
      origin = "1970-01-01"
    )
  )

  # Test for correct timestep
  expect_silent(
    check_timestep_by_date(obs)
  )

  # Introduce a discrepancy by adding a duplicate report_date for a given reference_date and group
  obs <- rbind(
    obs,
    data.table::data.table(
      .group = "A",
      report_date = as.Date("2020-01-01"),
      reference_date = as.Date("2020-01-01")
    )
  )

  expect_error(
    check_timestep_by_date(obs),
    "report_date has a duplicate date. Please remove duplicate dates."
  )

  # Remove the discrepancy and introduce a discrepancy in one of the date columns
  obs <- obs[-nrow(obs)]
  obs[1, report_date := as.Date("2019-01-02")]
  expect_error(
    check_timestep_by_date(obs),
    "report_date does not have the specified timestep of 1 day(s)",
    fixed = TRUE
  )

  # Reset the discrepancy and introduce a discrepancy in one of the groups
  obs[1, report_date := as.Date("2020-01-01")]
  obs[c(1, 6), report_date := as.Date("2020-01-02")]
  expect_error(
    check_timestep_by_date(obs),
    "report_date has a duplicate date. Please remove duplicate dates."
  )

  # Drop the group column and test
  obs_no_group <- obs[, .group := NULL]
  expect_error(
    check_timestep_by_date(obs_no_group),
    "report_date has a duplicate date. Please remove duplicate dates."
  )
})

test_that("check_timestep_by_date() handles insufficient data correctly", {
  # Create a dataset with a single date and group
  obs_single_date <- data.table::data.table(
    .group = "A",
    report_date = as.Date("2020-01-01"),
    reference_date = as.Date("2020-01-01")
  )

  # Test for insufficient data
  expect_error(
    check_timestep_by_date(obs_single_date),
    "There must be at least two observations"
  )

  # Create a dataset with two identical dates and group
  obs_identical_dates <- data.table::data.table(
    .group = c("A", "A"),
    report_date = as.Date(c("2020-01-01", "2020-01-01")),
    reference_date = as.Date(c("2020-01-01", "2020-01-01"))
  )

  # Test for identical dates
  expect_error(
    check_timestep_by_date(obs_identical_dates),
    "report_date has a duplicate date. Please remove duplicate dates."
  )
})

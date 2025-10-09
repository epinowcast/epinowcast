test_that("coerce_dt gives new data.table object", {
  dummy <- data.table::data.table(dummy = 1:10)
  newdt <- coerce_dt(dummy)
  expect_false(data.table::address(newdt) == data.table::address(dummy))
})

test_that("coerce_dt gives new data.table object, unless asked not to", {
  dummy <- data.table::data.table(dummy = 1:10)
  newdt <- coerce_dt(dummy, copy = FALSE)
  expect_identical(data.table::address(newdt), data.table::address(dummy))
})

test_that("coerce_dt requires required_cols", {
  present <- data.table::data.table(present = 1:10)
  absent <- data.table::data.table(absent = 1:10)
  expect_no_error(coerce_dt(present, required_cols = "present"))
  expect_error(coerce_dt(absent, required_cols = "present"), regexp = "present")
})

test_that("coerce_dt forbids forbidden_cols", {
  present <- data.table::data.table(present = 1:10)
  absent <- data.table::data.table(absent = 1:10)
  expect_no_error(coerce_dt(absent, forbidden_cols = "present"))
  expect_error(
    coerce_dt(present, forbidden_cols = "present"),
    regexp = "present"
  )
})

test_that("coerce_dt selects select", {
  both <- data.table::data.table(present = 1:10, absent = 1:10)
  present <- coerce_dt(both, select = "present")
  expect_true("present" %in% colnames(present))
  expect_false("absent" %in% colnames(present))
})

test_that("coerce_dt ensures a group if asked", {
  dummy <- data.table::data.table(dummy = 1:10)
  cdummy <- coerce_dt(dummy, group = TRUE)
  expect_true(".group" %in% colnames(cdummy))
  expect_true(all(cdummy$.group == 1))
})

test_that("coerce_dt ensures a group if asked, but doesn't overwrite one", {
  dummy <- data.table::data.table(dummy = 1:10, .group = 4)
  cdummy <- coerce_dt(dummy, group = TRUE)
  expect_true(".group" %in% colnames(cdummy))
  expect_true(all(cdummy$.group == 4))
})

test_that("coerce_dt(date = TRUE) works for example data", {
  expect_error(
    coerce_dt(germany_covid19_hosp, dates = TRUE), NA
  )
  obs <- coerce_dt(germany_covid19_hosp, dates = TRUE)
  expect_data_table(obs)
  expect_identical(colnames(obs), colnames(germany_covid19_hosp))
  expect_s3_class(obs$reference_date, c("IDate", "Date"))
  expect_s3_class(obs$report_date, c("IDate", "Date"))
})

test_that("coerce_dt(date = TRUE) requires reference and report dates", {
  ref_dates <- data.frame(
    reference_date = "2021-10-01",
    stringsAsFactors = FALSE
  )
  expect_error(coerce_dt(ref_dates, dates = TRUE))
  report_dates <- data.frame(
    report_dates = "2021-10-01",
    stringsAsFactors = FALSE
  )
  expect_error(coerce_dt(report_dates, dates = TRUE))
  expect_error(coerce_dt(mtcars, dates = TRUE))
})

test_that("coerce_dt provides the requested errors", {
  present <- data.table::data.table(present = 1:10)
  expect_error(
    coerce_dt(present, required_cols = "absent", msg_required = "ABSENT"),
    regexp = "ABSENT"
  )
  expect_error(
    coerce_dt(present, forbidden_cols = "present", msg_forbidden = "PRESENT"),
    regexp = "PRESENT"
  )
})

test_that("coerce_dt fixes IDate storage mode after dplyr operations", {
  skip_if_not_installed("dplyr")

  # Create test data with proper IDate columns
  test_data <- data.table::data.table(
    report_date = data.table::as.IDate("2021-10-01") + 0:5,
    reference_date = data.table::as.IDate("2021-10-01") + 0:5,
    confirm = c(1, 1, 2, 3, 5, 8)
  )

  # Verify initial storage mode is integer
  expect_identical(storage.mode(test_data$report_date), "integer")
  expect_identical(storage.mode(test_data$reference_date), "integer")

  # Apply dplyr filter (simulates user workflow that triggers bug)
  filtered_data <- dplyr::filter(test_data, confirm > 1)

  # After dplyr operation, storage mode may be corrupted to double
  # but class is still IDate (this is the bug scenario)
  # Note: This behaviour may vary by dplyr version, so we force it
  if (storage.mode(filtered_data$report_date) == "integer") {
    # Force the corruption to test the fix
    filtered_data$report_date <- as.double(filtered_data$report_date)
    class(filtered_data$report_date) <- c("IDate", "Date")
    filtered_data$reference_date <- as.double(
      filtered_data$reference_date
    )
    class(filtered_data$reference_date) <- c("IDate", "Date")
  }

  # Verify we have corrupted storage (double) but correct class
  expect_s3_class(filtered_data$report_date, c("IDate", "Date"))
  expect_identical(storage.mode(filtered_data$report_date), "double")

  # Apply coerce_dt which should fix storage mode
  fixed_data <- coerce_dt(filtered_data, dates = TRUE)

  # Verify storage mode is restored to integer
  expect_identical(storage.mode(fixed_data$report_date), "integer")
  expect_identical(storage.mode(fixed_data$reference_date), "integer")

  # Verify class is still correct
  expect_s3_class(fixed_data$report_date, c("IDate", "Date"))
  expect_s3_class(fixed_data$reference_date, c("IDate", "Date"))

  # Verify data values are unchanged
  expect_identical(
    as.integer(fixed_data$report_date),
    as.integer(test_data$report_date[test_data$confirm > 1])
  )
})

test_that("enw_preprocess_data works after dplyr::filter", {
  skip_on_cran()
  skip_if_not_installed("dplyr")

  # Use example dataset from package
  nat_germany_hosp <- epinowcast::germany_covid19_hosp[location == "DE"]
  nat_germany_hosp <- nat_germany_hosp[age_group == "00+"]

  # Apply dplyr filter before preprocessing (user workflow from issue)
  filtered_data <- dplyr::filter(
    nat_germany_hosp,
    report_date >= as.Date("2021-10-01")
  )

  # Force storage mode corruption if not already corrupted
  if (storage.mode(filtered_data$report_date) == "integer") {
    filtered_data$report_date <- as.double(filtered_data$report_date)
    class(filtered_data$report_date) <- c("IDate", "Date")
    filtered_data$reference_date <- as.double(
      filtered_data$reference_date
    )
    class(filtered_data$reference_date) <- c("IDate", "Date")
  }

  # This should not error (previously would fail with storage mode error)
  expect_no_error({
    pobs <- enw_preprocess_data(filtered_data, max_delay = 20)
  })

  # Verify preprocessing output has correct storage mode
  expect_identical(storage.mode(pobs$obs[[1]]$report_date), "integer")
  expect_identical(storage.mode(pobs$obs[[1]]$reference_date), "integer")

  # Verify classes are correct
  expect_s3_class(pobs$obs[[1]]$report_date, c("IDate", "Date"))
  expect_s3_class(pobs$obs[[1]]$reference_date, c("IDate", "Date"))

  # Verify preprocessing produces valid output structure
  expect_s3_class(pobs, "enw_preprocess_data")
  expect_true(
    all(c("obs", "new_confirm", "latest", "missing_reference") %in%
        names(pobs))
  )
})

test_that("coerce_dt handles edge cases correctly", {
  # Test 1: Data already has correct integer storage (no-op case)
  correct_data <- data.table::data.table(
    report_date = data.table::as.IDate("2021-10-01") + 0:3,
    reference_date = data.table::as.IDate("2021-10-01") + 0:3,
    value = 1:4
  )

  result <- coerce_dt(correct_data, dates = TRUE)
  expect_identical(storage.mode(result$report_date), "integer")
  expect_identical(storage.mode(result$reference_date), "integer")
  expect_s3_class(result$report_date, c("IDate", "Date"))

  # Test 2: Data with only one date column corrupted
  mixed_data <- data.table::data.table(
    report_date = data.table::as.IDate("2021-10-01") + 0:3,
    reference_date = data.table::as.IDate("2021-10-01") + 0:3,
    value = 1:4
  )
  mixed_data$report_date <- as.double(mixed_data$report_date)
  class(mixed_data$report_date) <- c("IDate", "Date")

  result <- coerce_dt(mixed_data, dates = TRUE)
  expect_identical(storage.mode(result$report_date), "integer")
  expect_identical(storage.mode(result$reference_date), "integer")

  # Test 3: Data with character dates (needs full conversion)
  char_data <- data.table::data.table(
    report_date = c("2021-10-01", "2021-10-02", "2021-10-03"),
    reference_date = c("2021-10-01", "2021-10-02", "2021-10-03"),
    value = 1:3
  )

  result <- coerce_dt(char_data, dates = TRUE)
  expect_identical(storage.mode(result$report_date), "integer")
  expect_identical(storage.mode(result$reference_date), "integer")
  expect_s3_class(result$report_date, c("IDate", "Date"))
  expect_s3_class(result$reference_date, c("IDate", "Date"))
})

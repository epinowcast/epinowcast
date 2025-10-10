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

test_that("coerce_dt restores integer storage for IDate columns", {
  skip_if_not_installed("dplyr")

  # Create test data and apply dplyr operation
  test_data <- data.table::data.table(
    report_date = data.table::as.IDate("2021-10-01") + 0:5,
    reference_date = data.table::as.IDate("2021-10-01") + 0:5,
    confirm = c(1, 1, 2, 3, 5, 8)
  )
  filtered_data <- dplyr::filter(test_data, confirm > 1)

  # Some dplyr versions corrupt IDate storage mode to double whilst
  # preserving class. Force corruption to test the fix works.
  if (storage.mode(filtered_data$report_date) == "integer") {
    filtered_data$report_date <- as.double(filtered_data$report_date)
    class(filtered_data$report_date) <- c("IDate", "Date")
    filtered_data$reference_date <- as.double(filtered_data$reference_date)
    class(filtered_data$reference_date) <- c("IDate", "Date")
  }

  # Verify we have double storage but IDate class (the bug scenario)
  expect_identical(storage.mode(filtered_data$report_date), "double")

  # coerce_dt should restore integer storage
  fixed_data <- coerce_dt(filtered_data, dates = TRUE)
  expect_identical(storage.mode(fixed_data$report_date), "integer")
  expect_identical(storage.mode(fixed_data$reference_date), "integer")
  expect_s3_class(fixed_data$report_date, c("IDate", "Date"))
})

test_that("enw_preprocess_data works after dplyr operations", {
  skip_on_cran()
  skip_if_not_installed("dplyr")

  # Simulate user workflow: dplyr filter then preprocess
  nat_germany_hosp <- germany_covid19_hosp[location == "DE"][age_group == "00+"]
  filtered_data <- dplyr::filter(
    nat_germany_hosp,
    report_date >= as.Date("2021-10-01")
  )

  # Force storage mode corruption to test the fix
  if (storage.mode(filtered_data$report_date) == "integer") {
    filtered_data$report_date <- as.double(filtered_data$report_date)
    class(filtered_data$report_date) <- c("IDate", "Date")
    filtered_data$reference_date <- as.double(filtered_data$reference_date)
    class(filtered_data$reference_date) <- c("IDate", "Date")
  }

  # Should work without error (previously failed)
  pobs <- enw_preprocess_data(filtered_data, max_delay = 20)
  expect_s3_class(pobs, "enw_preprocess_data")
  expect_identical(storage.mode(pobs$obs[[1]]$report_date), "integer")
})

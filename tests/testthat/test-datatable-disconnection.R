test_that("`coerce_dt` gives new `data.table` object", {
  dummy <- data.table::data.table(dummy = 1:10)
  newdt <- coerce_dt(dummy)
  expect_false(data.table::address(newdt) == data.table::address(dummy))
})

test_that("`coerce_dt` gives new `data.table` object, unless asked not to", {
  dummy <- data.table::data.table(dummy = 1:10)
  newdt <- coerce_dt(dummy, copy = FALSE)
  expect_true(data.table::address(newdt) == data.table::address(dummy))
})

test_that("`coerce_dt` requires `required_cols`", {
  present <- data.table::data.table(present = 1:10)
  absent <- data.table::data.table(absent = 1:10)
  expect_no_error(coerce_dt(present, required_cols = "present"))
  expect_error(coerce_dt(absent, required_cols = "present"), regexp = "present")
})

test_that("`coerce_dt` forbids `forbidden_cols`", {
  present <- data.table::data.table(present = 1:10)
  absent <- data.table::data.table(absent = 1:10)
  expect_no_error(coerce_dt(absent, forbidden_cols = "present"))
  expect_error(coerce_dt(present, forbidden_cols = "present"), regexp = "present")
})

test_that("`coerce_dt` selects `select`", {
  both <- data.table::data.table(present = 1:10, absent = 1:10)
  present <- coerce_dt(both, select = "present")
  expect_true("present" %in% colnames(present))
  expect_false("absent" %in% colnames(present))
})

test_that("`coerce_dt` ensures a group if asked", {
  dummy <- data.table::data.table(dummy = 1:10)
  cdummy <- coerce_dt(dummy, group = TRUE)
  expect_true(".group" %in% colnames(cdummy))
  expect_true(all(cdummy$.group == 1))
})

test_that("`coerce_dt` ensures a group if asked, but doesn't overwrite one", {
  dummy <- data.table::data.table(dummy = 1:10, .group = 4)
  cdummy <- coerce_dt(dummy, group = TRUE)
  expect_true(".group" %in% colnames(cdummy))
  expect_true(all(cdummy$.group == 4))
})

test_that("`coerce_dt` ensures a the required dates", {
  dummy <- data.table::data.table(dummy = 1:10, .group = 4)
  cdummy <- coerce_dt(dummy, group = TRUE)
  expect_true(".group" %in% colnames(cdummy))
  expect_true(all(cdummy$.group == 4))
})

test_that("`coerce_dt(date = TRUE)` works for example data", {
  expect_error(
    coerce_dt(germany_covid19_hosp, dates = TRUE), NA
  )
  obs <- coerce_dt(germany_covid19_hosp, dates = TRUE)
  expect_data_table(obs)
  expect_equal(colnames(obs), colnames(germany_covid19_hosp))
  expect_equal(class(obs$reference_date), c("IDate", "Date"))
  expect_equal(class(obs$report_date), c("IDate", "Date"))
})

test_that("`coerce_dt(date = TRUE)` requires reference and report dates", {
  ref_dates <- data.frame(reference_date = "2021-10-01")
  expect_error(coerce_dt(ref_dates, dates = TRUE))
  report_dates <- data.frame(report_dates = "2021-10-01")
  expect_error(coerce_dt(report_dates, dates = TRUE))
  expect_error(coerce_dt(mtcars, dates = TRUE))
})

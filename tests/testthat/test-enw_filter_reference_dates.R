test_that("enw_filter_reference_dates filters as expected", {
  expect_error(enw_filter_reference_dates(
    germany_covid19_hosp, include_days = 10, earliest_date = "2021-09-01")
  )
  filt_date <- enw_filter_reference_dates(
    germany_covid19_hosp, earliest_date = "2021-09-01"
  )
  expect_equal(max(filt_date$report_date), as.IDate("2021-10-20"))
  expect_equal(max(filt_date$reference_date), as.IDate("2021-10-20"))
  expect_equal(min(filt_date$report_date), as.IDate("2021-09-01"))
  expect_equal(min(filt_date$reference_date), as.IDate("2021-09-01"))
  filt_days <- enw_filter_reference_dates(
    germany_covid19_hosp, include_days = 10
  )
  expect_equal(max(filt_days$report_date), as.IDate("2021-10-20"))
  expect_equal(max(filt_days$reference_date), as.IDate("2021-10-20"))
  expect_equal(min(filt_days$report_date), as.IDate("2021-10-10"))
  expect_equal(min(filt_days$reference_date), as.IDate("2021-10-10"))
})

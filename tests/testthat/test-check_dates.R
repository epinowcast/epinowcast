test_that("check_dates works for example data", {
  expect_error(
    epinowcast:::check_dates(germany_covid19_hosp), NA
  )
  obs <- epinowcast:::check_dates(germany_covid19_hosp)
  expect_data_table(obs)
  expect_equal(colnames(obs), colnames(germany_covid19_hosp))
  expect_equal(class(obs$reference_date), c("IDate", "Date"))
  expect_equal(class(obs$report_date), c("IDate", "Date"))
})

test_that("check_dates requires reference and report dates", {
  ref_dates <- data.frame(reference_date = "2021-10-01")
  expect_error(check_dates(ref_dates))
  report_dates <- data.frame(report_dates = "2021-10-01")
  expect_error(check_dates(report_dates))
  expect_error(check_dates(mtcars))
})

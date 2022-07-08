test_that("enw_latest_data works as expected with well behaved data", {
  obs <- data.frame(
    reference_date = c("2021-10-01", "2021-11-01"),
    report_date = c("2021-10-01", "2021-12-01", "2021-11-01", "2021-11-30")
  )
  exp_obs <- data.table::data.table(
    reference_date = as.IDate(c("2021-10-01", "2021-11-01")),
    report_date = as.IDate(c("2021-11-01", "2021-12-01"))
  )
  expect_equal(enw_latest_data(obs), exp_obs)
})

test_that("enw_latest_data works as expected with poorly behaved data", {
  obs <- data.frame(
    reference_date = c("2021-10-01", "2021-11-01", NA),
    report_date = c("2021-10-01", "2021-12-01", "2021-11-30")
  )
  exp_obs <- data.table::data.table(
    reference_date = as.IDate(c("2021-10-01", "2021-11-01")),
    report_date = as.IDate(c("2021-10-01", "2021-12-01"))
  )
  expect_equal(enw_latest_data(obs), exp_obs)
  obs$reference_date <- NULL
  expect_error(enw_latest_data(obs))
})

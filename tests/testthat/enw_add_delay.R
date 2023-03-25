test_that("enw_add_delay adds a delay as expected", {
  obs <- data.frame(report_date = as.IDate("2021-01-01") + -2:0)
  obs$reference_date <- as.IDate("2021-01-01")
  expect_equal(
    enw_add_delay(obs),
    data.table::as.data.table(obs)[, delay := -2:0]
  )
})
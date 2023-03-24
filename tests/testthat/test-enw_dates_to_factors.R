test_that("enw_dates_to_factors can convert date variables", {
  data <- data.frame(
    date = as.Date("2019-01-01") + 0:2,
    char = c("a", "b", "c")
  )
  data <- enw_dates_to_factors(data)
  expect_true(is.factor(data$date))
  expect_equal(ncol(data), 1)
})
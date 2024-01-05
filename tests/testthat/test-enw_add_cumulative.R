test_that("enw_add_cumulative can return toy cumulative data", {
  dt <- enw_add_cumulative(toy_incidence)
  tc <- data.table::copy(toy_cumulative)
  data.table::setkeyv(tc, c("reference_date", "report_date"))
  expect_identical(
    dt[, .(reference_date, report_date, confirm)], tc
  )
})

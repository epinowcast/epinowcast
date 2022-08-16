test_that("enw_incidence_to_cumulative can return toy cumulative data", {
  dt <- enw_incidence_to_cumulative(toy_incidence)
  tc <- data.table::copy(toy_cumulative)
  data.table::setkeyv(tc, c("reference_date", "report_date"))
  expect_equal(
    dt[, .(reference_date, report_date, confirm)], tc
  )
})

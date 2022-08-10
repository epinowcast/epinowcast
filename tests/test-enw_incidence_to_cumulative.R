test_that("enw_incidence_to_cumulative can return toy cumulative data", {
  dt <- enw_incidence_to_cumulative(toy_incidence)
  expect_equal(
    dt[, .(reference_date, report_date, confirm)],
    toy_cumulative[order(reference_date, report_date)]
  )
})

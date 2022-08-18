test_that("enw_cumulative_to_incidence can return toy incidence data", {
  dt <- enw_cumulative_to_incidence(
    toy_cumulative,
    set_negatives_to_zero = FALSE
  )
  expect_equal(
    dt[, .(reference_date, report_date, new_confirm)],
    toy_incidence
  )
  expect_equal(dt$delay, 0:9)
})

test_that("enw_cumulative_to_incidence can calculate reporing proportions", {
  dt <- enw_cumulative_to_incidence(
    data.table::copy(toy_cumulative)[, max_confirm := 100],
    set_negatives_to_zero = FALSE
  )
  expect_equal(
    dt[, prop_reported],
    dt$new_confirm / 100
  )
})

test_that("enw_cumulative_to_incidence can set negatives to zero", {
  dt <- enw_cumulative_to_incidence(
    toy_cumulative,
    set_negatives_to_zero = TRUE
  )
  expect_equal(
    dt[, new_confirm],
    c(1, 2, 3, 4, 0, 5, 5, 6, 7, 9)
  )
})

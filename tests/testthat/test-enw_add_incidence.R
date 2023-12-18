test_that("enw_add_incidence can return toy incidence data", {
  dt <- enw_add_incidence(
    toy_cumulative,
    set_negatives_to_zero = FALSE
  )
  expect_identical(
    dt[, .(reference_date, report_date, new_confirm)],
    toy_incidence
  )
  expect_identical(dt$delay, 0:9)
})

test_that("enw_add_incidence can calculate reporing proportions", {
  dt <- enw_add_incidence(
    data.table::copy(toy_cumulative)[, max_confirm := 100],
    set_negatives_to_zero = FALSE
  )
  expect_identical(
    dt[, prop_reported],
    dt$new_confirm / 100
  )
})

test_that("enw_add_incidence can set negatives to zero", {
  dt <- enw_add_incidence(
    toy_cumulative,
    set_negatives_to_zero = TRUE
  )
  expect_identical(
    dt[, new_confirm],
    c(1, 2, 3, 4, 0, 5, 5, 6, 7, 9)
  )
})

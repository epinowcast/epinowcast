test_that("enw_add_delay() adds a delay as expected", {
  obs <- data.frame(report_date = as.IDate("2021-01-01") + -2:0)
  obs$reference_date <- as.IDate("2021-01-01")
  expect_equal(
    enw_add_delay(obs),
    data.table::as.data.table(obs)[, delay := -2:0]
  )
})

test_that("enw_add_delay() calculates delay correctly for a week timestep", {
  obs <- data.frame(report_date = as.IDate("2021-01-01") + c(-14, -7, 0))
  obs$reference_date <- as.IDate("2021-01-01")
  expect_equal(
    enw_add_delay(obs, timestep = 7),
    data.table::as.data.table(obs)[, delay := c(-2, -1, 0)]
  )
})

test_that("enw_add_delay() calculates delay correctly for a 5 days timestep", {
  obs <- data.frame(report_date = as.IDate("2021-01-01") + c(-10, -5, 0))
  obs$reference_date <- as.IDate("2021-01-01")
  expect_equal(
    enw_add_delay(obs, timestep = 5),
    data.table::as.data.table(obs)[, delay := c(-2, -1, 0)]
  )
})

test_that("enw_add_delay() calculates delay correctly for a 14 days timestep", {
  obs <- data.frame(report_date = as.IDate("2021-01-01") + c(-28, -14, 0))
  obs$reference_date <- as.IDate("2021-01-01")
  expect_equal(
    enw_add_delay(obs, timestep = 14),
    data.table::as.data.table(obs)[, delay := c(-2, -1, 0)]
  )
})

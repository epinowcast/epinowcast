test_that("enw_extend_date extends the date as expected", {
  metaobs <- data.frame(date = as.Date("2021-01-01") + 0:4)
  expect_equal(
    enw_extend_date(metaobs, days = 2),
    data.table::setkeyv(
      data.table::data.table(
        date = as.Date("2021-01-01") + 0:6, .group = 1,
        observed = c(rep(TRUE, 5), FALSE, FALSE)
      ),
      c(".group", "date")
    )
  )
  expect_equal(
    enw_extend_date(metaobs, days = 2, direction = "start"),
    data.table::setkeyv(
      data.table::data.table(
        date = as.Date("2021-01-01") + -2:4, .group = 1,
        observed = c(FALSE, FALSE, rep(TRUE, 5))
      ),
      c(".group", "date")
    )
  )
})
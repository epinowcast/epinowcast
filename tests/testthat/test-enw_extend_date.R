test_that("enw_extend_date() extends the date as expected", {
  metaobs <- data.frame(date = as.Date("2021-01-01") + 0:4)
  expect_identical(
    enw_extend_date(metaobs, days = 2),
    data.table::setkeyv(
      data.table::data.table(
        date = as.Date("2021-01-01") + 0:6, .group = 1,
        observed = c(rep(TRUE, 5), FALSE, FALSE)
      ),
      c(".group", "date")
    )
  )
  expect_identical(
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

test_that(
  "enw_extend_date() extends the date correctly for a week timestep",
  {
    metaobs <- data.frame(date = as.Date("2021-01-01") + seq(0, 28, by = 7))
    expect_identical(
      enw_extend_date(metaobs, days = 14, timestep = 7),
      data.table::setkeyv(
        data.table::data.table(
          date = as.Date("2021-01-01") + seq(0, 42, by = 7), .group = 1,
          observed = c(rep(TRUE, 5), FALSE, FALSE)
        ),
        c(".group", "date")
      )
    )
  }
)

test_that(
  "enw_extend_date() extends the date correctly for a 5 days timestep",
  {
    metaobs <- data.frame(date = as.Date("2021-01-01") + seq(0, 20, by = 5))
    expect_identical(
      enw_extend_date(metaobs, days = 10, timestep = 5),
      data.table::setkeyv(
        data.table::data.table(
          date = as.Date("2021-01-01") + seq(0, 30, by = 5), .group = 1,
          observed = c(rep(TRUE, 5), FALSE, FALSE)
        ),
        c(".group", "date")
      )
    )
  }
)

test_that(
  "enw_extend_date() extends the date correctly for a 14 days timestep",
  {
    metaobs <- data.frame(date = as.Date("2021-01-01") + seq(0, 28, by = 14))
    expect_identical(
      enw_extend_date(metaobs, days = 28, timestep = 14),
      data.table::setkeyv(
        data.table::data.table(
          date = as.Date("2021-01-01") + seq(0, 56, by = 14), .group = 1,
          observed = c(rep(TRUE, 3), FALSE, FALSE)
        ),
        c(".group", "date")
      )
    )
  }
)

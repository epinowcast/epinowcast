test_that("enw_add_max_reported adds a max_reported as expected", {
  obs <- data.frame(report_date = as.IDate("2021-01-01") + 0:2)
  obs$reference_date <- as.IDate("2021-01-01")
  obs$confirm <- 1:3
  expect_equal(
    enw_add_max_reported(obs),
    data.table::setcolorder(
      data.table::as.data.table(obs)[,
        `:=`(.group = 1, max_confirm = 3, cum_prop_reported = confirm / 3)
      ],
      c(
        "reference_date", "report_date", ".group", "max_confirm", "confirm",
        "cum_prop_reported"
      )
    )
  )
})

test_that("enw_add_max_reported is robust to repeated application", {
  obs <- data.frame(report_date = as.IDate("2021-01-01") + 0:2)
  obs$reference_date <- as.IDate("2021-01-01")
  obs$confirm <- 1:3
  expect_equal(
    enw_add_max_reported(enw_add_max_reported(obs)),
    data.table::setcolorder(
      data.table::as.data.table(obs)[,
                                     `:=`(.group = 1, max_confirm = 3, cum_prop_reported = confirm / 3)
      ],
      c(
        "reference_date", "report_date", ".group", "max_confirm", "confirm",
        "cum_prop_reported"
      )
    )
  )
})
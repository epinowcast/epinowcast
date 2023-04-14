test_that("enw_metadata works as expected", {
  obs <- data.frame(
    reference_date = as.Date("2021-01-01"),
    report_date = as.Date("2022-01-01"),
    x = 1:10
  )
  expect_equal(
    enw_metadata(obs, target_date = "reference_date"),
    data.table::setkeyv(
      data.table::data.table(
        date = as.Date("2021-01-01"), .group = 1, x = 1
      ),
      c(".group","date")
    )
  )
}) 

test_that(
  "enw_metadata works as expected when a grouping variable is present", {
  obs <- data.frame(
    reference_date = as.Date("2021-01-01"),
    report_date = as.Date("2022-01-01"),
    x = 1:10,
    .group = 2
  )
  expect_equal(
    enw_metadata(obs, target_date = "reference_date"),
    data.table::setkeyv(
      data.table::data.table(
        date = as.Date("2021-01-01"), .group = 2, x = 1
      ),
      c(".group","date")
    )
  )
}) 

test_that("enw_metadata works as expected to summarise report_date metadata", {
  obs <- data.frame(
    reference_date = as.Date("2021-01-01"),
    report_date = as.Date("2022-01-01"),
    x = 1:10, y = 1:10
  )
  expect_equal(
    enw_metadata(obs, target_date = "report_date"),
    data.table::setkeyv(
      data.table::data.table(
        date = as.Date("2022-01-01"), .group = 1, x = 1, y = 1
      ),
      c(".group","date")
    )
  )
}) 
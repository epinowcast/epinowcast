test_that("check_group_date_unique works for unique groups", {
  obs <- data.frame(
    .group = c("A", "B", "C"),
    reference_date = as.Date(c("2023-01-01", "2023-01-02", "2023-01-03")),
    report_date = as.Date(c("2023-02-01", "2023-02-02", "2023-02-03"))
  )

  # Expect no error
  expect_silent(check_group_date_unique(obs))
})

test_that("check_group_date_unique stops with duplicated groups", {
  obs <- data.frame(
    .group = c("A", "A", "C"),
    reference_date = as.Date(c("2023-01-01", "2023-01-01", "2023-01-03")),
    report_date = as.Date(c("2023-02-01", "2023-02-01", "2023-02-03"))
  )

  # Expect error due to duplicated combination
  expect_error(check_group_date_unique(obs),
               "The input data seems to be stratified by more variables than \nspecified via the `by` argument. Please provide additional grouping \nvariables to `by`, or aggregate the observations beforehand.")
})

test_that("check_group_date_unique works with empty data frame", {
  obs <- data.frame(
    .group = character(),
    reference_date = as.Date(character()),
    report_date = as.Date(character())
  )

  # Expect no error with empty data frame
  expect_silent(check_group_date_unique(obs))
})

test_that("check_group_date_unique stops with missing required columns", {
  obs <- data.frame(
    .group = c("A", "B", "C")
  )

  # Expect error as required columns are missing
  # This test might need modification depending on how coerce_dt handles missing columns
  expect_error(
    check_group_date_unique(obs),
    "reference_date, report_date but are not present among .group"
  )
})

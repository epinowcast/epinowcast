test_that("check_group_date_unique works for unique groups", {
  obs <- data.frame(
    .group = c("A", "B", "C"),
    reference_date = as.Date(c("2023-01-01", "2023-01-02", "2023-01-03")),
    report_date = as.Date(c("2023-02-01", "2023-02-02", "2023-02-03")),
    stringsAsFactors = FALSE
  )

  # Expect no error
  expect_silent(check_group_date_unique(obs))
})

test_that("check_group_date_unique stops with duplicated groups", {
  obs <- data.frame(
    .group = c("A", "A", "C"),
    reference_date = as.Date(c("2023-01-01", "2023-01-01", "2023-01-03")),
    report_date = as.Date(c("2023-02-01", "2023-02-01", "2023-02-03")),
    stringsAsFactors = FALSE
  )

  # Expect error due to duplicated combination
  expect_error(
    check_group_date_unique(obs),
    "stratified by more variables than specified via the `by` argument"
  )
})

test_that("check_group_date_unique works with empty data frame", {
  obs <- data.frame(
    .group = character(),
    reference_date = as.Date(character()),
    report_date = as.Date(character()),
    stringsAsFactors = FALSE
  )

  # Expect no error with empty data frame
  expect_silent(check_group_date_unique(obs))
})

test_that("check_group_date_unique stops with missing required columns", {
  obs <- data.frame(
    .group = c("A", "B", "C"),
    stringsAsFactors = FALSE
  )

  # Expect error as required columns are missing
  # This test might need modification depending on how coerce_dt handles missing
  # columns
  expect_error(
    check_group_date_unique(obs),
    "reference_date, report_date but are not present among .group"
  )
})

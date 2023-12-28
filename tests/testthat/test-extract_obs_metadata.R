test_that("extract_obs_metadata returns correct metadata", {
  # Create a mock data.table for testing
  new_confirm <- data.table(
    reference_date = as.Date(c("2023-01-01", "2023-01-02", "2023-01-03")),
    delay = c(1, 2, 3),
    .group = c(1, 1, 2),
    new_confirm = c(10, 20, 30),
    .observed = c(TRUE, TRUE, FALSE) # Mock observation_indicator
  )

  result <- extract_obs_metadata(new_confirm)

  # Check if the result is a list
  expect_type(result, "list")
  # Check if the list has the expected names
  expect_named(
    result,
    c("st", "ts", "sl", "csl", "lsl", "clsl", "nsl", "cnsl", "sg")
  )
  # Test the output is as expected
  expect_identical(result$st, c(1L, 2L, 1L))
  expect_identical(
    unname(as.matrix(result$ts)), t(matrix(c(1L, NA, 2L, NA, NA, 3L), nrow = 2))
  )
  expect_identical(result$sl, c(2, 3, 4))
  expect_identical(result$csl, c(2, 5, 9))
  expect_identical(result$nsl, c(2, 3, 4))
  expect_identical(result$cnsl, c(2, 5, 9))
  expect_identical(result$sg, c(1, 1, 2))

  # Test with observation_indicator
  new_confirm <- add_max_observed_delay(new_confirm, ".observed")
  result <- extract_obs_metadata(new_confirm, ".observed")

  expect_type(result, "list")
  # Check if the list has the expected names
  expect_named(
    result,
    c("st", "ts", "sl", "csl", "lsl", "clsl", "nsl", "cnsl", "sg")
  )
  # Test the output is as expected
  expect_identical(result$st, c(1L, 2L, 1L))
  expect_identical(
    unname(as.matrix(result$ts)), t(matrix(c(1L, NA, 2L, NA, NA, 3L), nrow = 2))
  )
  expect_identical(result$sl, c(2, 3, 4))
  expect_identical(result$csl, c(2, 5, 9))
  expect_identical(result$nsl, c(1L, 1L, 0L))
  expect_identical(result$cnsl, c(1L, 2L, 2L))
  expect_identical(result$sg, c(1, 1, 2))
  expect_error(
    extract_obs_metadata(new_confirm, "delay"),
    "observation_indicator must be a logical"
  )
})

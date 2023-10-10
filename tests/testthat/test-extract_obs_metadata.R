test_that("extract_obs_metadata returns correct metadata", {
  # Create a mock data.table for testing
  new_confirm <- data.table(
    reference_date = as.Date(c("2023-01-01", "2023-01-02", "2023-01-03")),
    delay = c(1, 2, 3),
    .group = c(1, 1, 2),
    new_confirm = c(10, 20, 30),
    .observed = c(TRUE, TRUE, FALSE)  # Mock observation_indicator
  )
  
  result <- epinowcast:::extract_obs_metadata(new_confirm)
  
  # Check if the result is a list
  expect_true(is.list(result))
  # Check if the list has the expected names
  expect_equal(names(result), c("st", "ts", "sl", "csl", "nsl", "cnsl", "sg"))
  # Test the output is as expected
  expect_equal(result$st, c(1,2, 1))
  expect_equal(
    unname(as.matrix(result$ts)), t(matrix(c(1, NA, 2, NA, NA, 3), nrow = 2))
  )
  expect_equal(result$sl, c(2, 3, 4))
  expect_equal(result$csl, c(2, 5, 9))
  expect_equal(result$nsl, c(2, 3, 4))
  expect_equal(result$cnsl, c(2, 5, 9))
  expect_equal(result$sg, c(1, 1, 2))
  
  # Test with observation_indicator
  result <-
    epinowcast:::extract_obs_metadata(new_confirm, ".observed")
  
  expect_true(is.list(result))
  # Check if the list has the expected names
  expect_equal(names(result), c("st", "ts", "sl", "csl", "nsl", "cnsl", "sg"))
  # Test the output is as expected
  expect_equal(result$st, c(1,2, 1))
  expect_equal(
    unname(as.matrix(result$ts)), t(matrix(c(1, NA, 2, NA, NA, 3), nrow = 2))
  )
  expect_equal(result$sl, c(2, 3, 4))
  expect_equal(result$csl, c(2, 5, 9))
  expect_equal(result$nsl, c(1, 1, 0))
  expect_equal(result$cnsl, c(1, 2, 2))
  expect_equal(result$sg, c(1, 1, 2))
  expect_error(
    epinowcast:::extract_obs_metadata(new_confirm, "delay"),
    "observation_indicator must be a logical"
  )
})

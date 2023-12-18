# Mock data
mock_data <- data.table(
  reference_date = as.Date(c("2023-01-01", "2023-01-01", "2023-01-02", "2023-01-02")),
  .group = c("A", "B", "A", "B"),
  delay = c(5, 10, 3, 7),
  observed = c(TRUE, FALSE, TRUE, TRUE)
)

test_that("add_max_observed_delay works without observation_indicator", {
  result <- add_max_observed_delay(mock_data)

  expected <- copy(mock_data)
  expected[, max_obs_delay := c(5, 10, 3, 7)]

  expect_identical(result, expected)
})

test_that("add_max_observed_delay works with observation_indicator", {
  result <- add_max_observed_delay(mock_data, "observed")

  expected <- copy(mock_data)
  expected[, max_obs_delay := c(5, -1, 3, 7)]

  expect_identical(result, expected)
})

# Mock data
mock_data_logical <- data.table(
  reference_date = as.Date(c("2023-01-01", "2023-01-01")),
  observed = c(TRUE, FALSE)
)

mock_data_non_logical <- data.table(
  reference_date = as.Date(c("2023-01-01", "2023-01-01")),
  observed = c(1, 2)
)

test_that(
  "check_observation_indicator works with logical observation_indicator",
  {
    expect_silent(check_observation_indicator(mock_data_logical, "observed"))
  }
)

test_that("check_observation_indicator throws error with non-logical
          observation_indicator", {
  expect_error(
    check_observation_indicator(mock_data_non_logical, "observed"),
    "observation_indicator must be a logical"
  )
})

test_that("check_observation_indicator works without observation_indicator", {
  expect_silent(check_observation_indicator(mock_data_logical))
})

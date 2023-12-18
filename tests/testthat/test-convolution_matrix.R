test_that("convolution matrix can construct matrices of the correct form", {
  # Simple convolution matrix with a static distribution
  expect_snapshot(
    convolution_matrix(c(1, 2, 3), 10)
  )

  # Include partially reported convolutions
  expect_snapshot(
    convolution_matrix(c(1, 2, 3), 10, include_partial = TRUE)
  )

  # Use a list of distributions
  expect_identical(
    convolution_matrix(rep(list(c(1, 2, 3)), 10), 10),
    convolution_matrix(c(1, 2, 3), 10)
  )
  # Use a time-varying list of distributions
  expect_snapshot(
    convolution_matrix(c(rep(list(c(1, 2, 3)), 10), list(c(4, 5, 6))), 11)
  )
  expect_error(
    convolution_matrix(c(rep(list(c(1, 2, 3)), 10), list(c(4, 5, 6, y))), 11)
  )
})

test_that("enw_priors_as_data_list produces expected output", {
  priors <- data.frame(variable = c("x", "y"), mean = c(1, 2), sd = c(2, 2.2))
  priors_list <- list(
    x_p = c(1, 2),
    y_p = c(2, 2.2)
  )
  expect_equal(
    enw_priors_as_data_list(priors), priors_list
  )
})

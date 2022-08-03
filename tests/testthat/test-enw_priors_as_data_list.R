test_that("enw_priors_as_data_list produces expected output", {
  priors <- data.frame(
    variable = c("x", "y", "z", "z"), mean = c(1, 2, 2, 3), sd = c(2, 2.2, 3, 1)
  )
  priors_list <- list(
    x_p = array(t(c(1, 2))),
    y_p = array(t(c(2, 2.2))),
    z_p = as.array(matrix(c(2, 3, 3, 1), 2, 2))
  )
  expect_equal(
    enw_priors_as_data_list(priors), priors_list
  )
})

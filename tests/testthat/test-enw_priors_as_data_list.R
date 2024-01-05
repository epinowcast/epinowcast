test_that("enw_priors_as_data_list produces expected output", {
  priors <- data.frame(
    variable = c("x", "y", "z", "z"),
    mean = c(1, 2, 2, 3), sd = c(2, 2.2, 3, 1),
    stringsAsFactors = FALSE
  )
  priors_list <- list(
    x_p = as.matrix(c(1, 2)),
    y_p = as.matrix(c(2, 2.2)),
    z_p = as.array(matrix(c(2, 3, 3, 1), 2, 2))
  )
  rownames(priors_list$x_p) <- c("mean", "sd")
  rownames(priors_list$y_p) <- c("mean", "sd")
  rownames(priors_list$z_p) <- c("mean", "sd")

  expect_identical(
    enw_priors_as_data_list(priors), priors_list
  )
})

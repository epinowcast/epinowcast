test_that("enw_priors_as_data_list converts a named list of priors", {
  priors <- list(
    x = distspec::Normal(mean = 1, sd = 2),
    y = distspec::LogNormal(meanlog = 2, sdlog = 2.2)
  )
  expect_identical(
    enw_priors_as_data_list(priors),
    list(
      x_p = as.array(matrix(c(1, 2), nrow = 2)),
      y_p = as.array(matrix(c(2, 2.2), nrow = 2))
    )
  )
})

test_that("enw_priors_as_data_list stacks vectorised priors by dimension", {
  priors <- .enw_prior_table(
    variable = c("x", "z", "z"),
    dimension = c(NA, 1, 2),
    description = c("x", "z1", "z2"),
    distribution = rep("Normal", 3),
    prior = list(
      distspec::Normal(mean = 1, sd = 2),
      distspec::Normal(mean = 2, sd = 3),
      distspec::Normal(mean = 3, sd = 1)
    )
  )
  expect_identical(
    enw_priors_as_data_list(priors),
    list(
      x_p = as.array(matrix(c(1, 2), nrow = 2)),
      z_p = as.array(matrix(c(2, 3, 3, 1), nrow = 2, ncol = 2))
    )
  )
})

test_that("enw_priors_as_data_list supports mean and sd columns", {
  priors <- data.frame(
    variable = c("x", "y"), mean = c(1, 2), sd = c(2, 0),
    stringsAsFactors = FALSE
  )
  expect_identical(
    enw_priors_as_data_list(priors),
    list(
      x_p = as.array(matrix(c(1, 2), nrow = 2)),
      y_p = as.array(matrix(c(2, 0), nrow = 2))
    )
  )
})

test_that("enw_priors_as_data_list uses the natural parameters of each
           prior family", {
  priors <- enw_report(data = enw_example("preprocessed"))$priors
  data_list <- enw_priors_as_data_list(priors)
  expect_identical(as.vector(data_list$rep_beta_sd_p), c(0, 1))
  expect_identical(as.vector(data_list$rep_gp_rho_p), c(log(3), 0.5))
  # A flat prior ships as a zero standard deviation.
  expect_identical(as.vector(data_list$rep_arima_pacf_p), c(0, 0))
})

test_that("enw_priors_as_data_list rejects unsupported prior families", {
  expect_error(
    enw_priors_as_data_list(list(x = distspec::Gamma(shape = 1, rate = 1))),
    "Normal"
  )
})

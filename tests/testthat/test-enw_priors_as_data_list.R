test_that("enw_priors_as_data_list converts a named list of priors", {
  priors <- list(
    x = distspec::Normal(mean = 1, sd = 2),
    y = distspec::LogNormal(meanlog = 2, sdlog = 2.2)
  )
  expect_identical(
    enw_priors_as_data_list(priors),
    list(
      x_p = as.array(matrix(c(1, 2), nrow = 2)),
      x_p_dist = 1L,
      y_p = as.array(matrix(c(2, 2.2), nrow = 2)),
      y_p_dist = 2L
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
      x_p_dist = 1L,
      z_p = as.array(matrix(c(2, 3, 3, 1), nrow = 2, ncol = 2)),
      z_p_dist = 1L
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
      x_p_dist = 1L,
      y_p = as.array(matrix(c(2, 0), nrow = 2)),
      y_p_dist = 0L
    )
  )
})

test_that("enw_priors_as_data_list uses the natural parameters and
           distribution id of each prior family", {
  priors <- list(
    normal = distspec::Normal(mean = 0, sd = 1),
    lognormal = distspec::LogNormal(meanlog = log(3), sdlog = 0.5),
    gamma = distspec::Gamma(shape = 2, rate = 4),
    exponential = distspec::Exponential(rate = 3)
  )
  data_list <- enw_priors_as_data_list(priors)
  expect_identical(as.vector(data_list$normal_p), c(0, 1))
  expect_identical(data_list$normal_p_dist, 1L)
  expect_identical(as.vector(data_list$lognormal_p), c(log(3), 0.5))
  expect_identical(data_list$lognormal_p_dist, 2L)
  expect_identical(as.vector(data_list$gamma_p), c(2, 4))
  expect_identical(data_list$gamma_p_dist, 3L)
  expect_identical(as.vector(data_list$exponential_p), c(3, 0))
  expect_identical(data_list$exponential_p_dist, 4L)
})

test_that("enw_priors_as_data_list ships a flat prior as id 0", {
  priors <- enw_report(data = enw_example("preprocessed"))$priors
  data_list <- enw_priors_as_data_list(priors)
  expect_identical(as.vector(data_list$rep_beta_sd_p), c(0, 1))
  expect_identical(data_list$rep_beta_sd_p_dist, 1L)
  expect_identical(as.vector(data_list$rep_gp_rho_p), c(log(3), 0.5))
  expect_identical(data_list$rep_gp_rho_p_dist, 2L)
  expect_identical(as.vector(data_list$rep_arima_pacf_p), c(0, 0))
  expect_identical(data_list$rep_arima_pacf_p_dist, 0L)
})

test_that("enw_priors_as_data_list rejects unsupported prior families", {
  expect_error(
    enw_priors_as_data_list(list(x = distspec::Weibull(shape = 1, scale = 1))),
    "Normal"
  )
})

test_that("enw_priors_as_data_list requires one family per vectorised
           prior", {
  priors <- .enw_prior_table(
    variable = c("z", "z"),
    dimension = c(1, 2),
    description = c("z", "z"),
    distribution = rep("Zero truncated normal", 2),
    prior = list(
      distspec::Normal(mean = 0, sd = 1),
      distspec::Gamma(shape = 2, rate = 4)
    )
  )
  expect_error(enw_priors_as_data_list(priors), "share a distribution family")
})

test_that(".enw_priors_as_init_list gives prior means and standard
           deviations", {
  priors <- list(
    x = distspec::Normal(mean = 1, sd = 2),
    y = distspec::LogNormal(meanlog = 0, sdlog = 0.5),
    z = distspec::Gamma(shape = 2, rate = 4)
  )
  init_list <- .enw_priors_as_init_list(priors)
  expect_named(init_list, c("x_p", "y_p", "z_p"))
  expect_identical(as.vector(init_list$x_p), c(1, 2))
  expect_equal(
    as.vector(init_list$y_p),
    c(exp(0.125), sqrt(exp(0.25) - 1) * exp(0.125)),
    tolerance = 1e-12
  )
  expect_identical(as.vector(init_list$z_p), c(0.5, sqrt(2) / 4))
  expect_identical(
    as.vector(.enw_priors_as_init_list(list(w = NULL))$w_p), c(0, 0)
  )
})

test_that(".enw_rlnorm_init draws around the median of a log-normal prior", {
  prior <- distspec::LogNormal(meanlog = log(4000), sdlog = 0.5)
  moments <- .enw_prior_moments(prior)
  expect_equal(
    .enw_rlnorm_init(2, 4000, 0, scale = 0), c(4000, 4000),
    tolerance = 1e-12
  )
  set.seed(1)
  draws <- .enw_rlnorm_init(2000, moments[1], moments[2])
  expect_length(draws, 2000)
  expect_true(all(draws > 0))
  expect_lt(abs(median(log(draws)) - log(4000)), 0.01)
  expect_lt(sd(log(draws)), 0.06)
  expect_gt(sd(log(draws)), 0.04)
})

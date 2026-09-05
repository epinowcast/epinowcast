example_priors <- function() {
  .enw_prior_table(
    variable = c("x", "y", "z"),
    description = c("x", "y", "z"),
    distribution = c("Normal", "Zero truncated normal", "Log normal"),
    prior = list(
      distspec::Normal(mean = 1, sd = 1),
      distspec::Normal(mean = 0, sd = 2),
      distspec::LogNormal(meanlog = 0, sdlog = 1)
    )
  )
}

test_that("enw_replace_priors can replace a default prior with a custom
           prior", {
  priors <- example_priors()
  updated <- enw_replace_priors(
    priors, list(x = distspec::Normal(mean = 10, sd = 2))
  )
  expect_data_table(updated)
  expect_named(updated, c("variable", "description", "distribution", "prior"))
  expect_identical(updated$variable, priors$variable)
  expect_identical(updated$description, priors$description)
  expect_identical(updated$prior[[1]], distspec::Normal(mean = 10, sd = 2))
  expect_identical(updated$prior[[2]], priors$prior[[2]])
  expect_identical(updated$prior[[3]], priors$prior[[3]])
})

test_that("enw_replace_priors accepts a data.frame with a prior column", {
  priors <- example_priors()
  custom <- data.table::data.table(variable = "y")
  data.table::set(
    custom,
    j = "prior", value = list(list(distspec::Normal(mean = 0, sd = 0.5)))
  )
  updated <- enw_replace_priors(priors, custom)
  expect_identical(updated$prior[[2]], distspec::Normal(mean = 0, sd = 0.5))
})

test_that("enw_replace_priors converts mean and sd columns using the default
           prior family", {
  priors <- example_priors()
  custom <- data.frame(
    variable = c("x[1]", "z"), mean = c(10, 2), sd = c(2, 0.5),
    stringsAsFactors = FALSE
  )
  updated <- enw_replace_priors(priors, custom)
  expect_identical(updated$prior[[1]], distspec::Normal(mean = 10, sd = 2))
  expect_identical(updated$prior[[2]], priors$prior[[2]])
  expect_identical(
    updated$prior[[3]], distspec::LogNormal(meanlog = 2, sdlog = 0.5)
  )
})

test_that("enw_replace_priors matches vectorised priors by dimension", {
  priors <- .enw_prior_table(
    variable = c("x", "z", "z"),
    dimension = c(1, 1, 2),
    description = c("x", "z", "z"),
    distribution = rep("Normal", 3),
    prior = list(
      distspec::Normal(mean = 1, sd = 1),
      distspec::Normal(mean = 2, sd = 1),
      distspec::Normal(mean = 3, sd = 1)
    )
  )
  updated <- enw_replace_priors(
    priors, list(`z[2]` = distspec::Normal(mean = 10, sd = 2))
  )
  expect_identical(updated$prior[[2]], priors$prior[[2]])
  expect_identical(updated$prior[[3]], distspec::Normal(mean = 10, sd = 2))

  updated <- enw_replace_priors(
    priors, list(z = distspec::Normal(mean = 5, sd = 1))
  )
  expect_identical(updated$prior[[2]], distspec::Normal(mean = 5, sd = 1))
  expect_identical(updated$prior[[3]], distspec::Normal(mean = 5, sd = 1))

  expect_error(
    enw_replace_priors(priors, list(`z[3]` = distspec::Normal(0, 1))),
    "dimension 3"
  )
})

test_that("enw_replace_priors ignores an index on a prior that is not
           vectorised", {
  priors <- example_priors()
  updated <- enw_replace_priors(
    priors, list(`x[1]` = distspec::Normal(mean = 0, sd = 1))
  )
  expect_identical(updated$prior[[1]], distspec::Normal(mean = 0, sd = 1))
})

test_that("enw_replace_priors checks the prior family and parameters", {
  priors <- example_priors()
  expect_error(
    enw_replace_priors(priors, list(x = distspec::LogNormal(1, 1))),
    "must be a \"normal\" distribution"
  )
  expect_error(
    enw_replace_priors(priors, list(z = distspec::Normal(1, 1))),
    "must be a \"lognormal\" distribution"
  )
  expect_error(
    enw_replace_priors(
      priors, list(x = distspec::Normal(distspec::Normal(0, 1), 1))
    ),
    "fixed \\(numeric\\) parameters"
  )
  expect_error(
    enw_replace_priors(priors, list(x = distspec::Normal(1, 0))),
    "not a \"fixed\" distribution"
  )
  expect_error(
    enw_replace_priors(priors, list(x = NULL)),
    "flat"
  )
  expect_error(
    enw_replace_priors(priors, list(x = 1)),
    "not an object of class"
  )
  expect_error(
    enw_replace_priors(priors, list(distspec::Normal(0, 1))),
    "named list"
  )
  expect_error(
    enw_replace_priors(priors, distspec::Normal(0, 1)),
    "named list"
  )
  expect_error(
    enw_replace_priors(priors, data.frame(variable = "x", mean = 1)),
    "mean"
  )
})

test_that("enw_replace_priors errors for an unknown prior in a list but
           ignores unmatched rows of a data.frame", {
  priors <- example_priors()
  expect_error(
    enw_replace_priors(priors, list(nope = distspec::Normal(0, 1))),
    "not a prior variable"
  )
  custom <- data.frame(
    variable = c("nope", "x"), mean = c(1, 10), sd = c(1, 2),
    stringsAsFactors = FALSE
  )
  updated <- enw_replace_priors(priors, custom)
  expect_identical(updated$variable, priors$variable)
  expect_identical(updated$prior[[1]], distspec::Normal(mean = 10, sd = 2))
})

test_that("enw_replace_priors allows a flat prior where the model uses a
           Uniform prior", {
  priors <- enw_report(data = enw_example("preprocessed"))$priors
  updated <- enw_replace_priors(
    priors, list(rep_arima_pacf = distspec::Normal(mean = 0, sd = 0.3))
  )
  expect_identical(
    updated[variable == "rep_arima_pacf"]$prior[[1]],
    distspec::Normal(mean = 0, sd = 0.3)
  )
  reset <- enw_replace_priors(updated, list(rep_arima_pacf = NULL))
  expect_null(reset[variable == "rep_arima_pacf"]$prior[[1]])
  reset <- enw_replace_priors(
    updated, list(rep_arima_pacf = distspec::Normal(mean = 0, sd = 0))
  )
  expect_identical(
    as.vector(enw_priors_as_data_list(reset)$rep_arima_pacf_p), c(0, 0)
  )
})

test_that("enw_replace_priors can replace default priors with those from an
           estimated model", {
  variables <- c("refp_mean_int", "refp_sd_int", "sqrt_phi")
  obs <- enw_example("preprocessed")
  fit_priors <- summary(
    enw_example("nowcast"),
    type = "fit",
    variables = variables
  )
  fit_priors <- fit_priors[,
    c("mean", "sd") := lapply(.SD, round, digits = 1),
    .SDcols = c("mean", "sd")
  ]
  default_priors <- enw_reference(distribution = "lognormal", data = obs)$priors
  updated_priors <- enw_replace_priors(default_priors, fit_priors)
  updated_priors <- updated_priors[variable %in% variables]
  expect_identical(updated_priors$variable, c("refp_mean_int", "refp_sd_int"))
  fit_priors <- fit_priors[
    gsub("\\[.*\\]$", "", variable) %in% updated_priors$variable
  ]
  expect_identical(
    purrr::map_dbl(updated_priors$prior, ~ distspec::get_parameters(.)$mean),
    as.numeric(fit_priors$mean)
  )
  expect_identical(
    purrr::map_dbl(updated_priors$prior, ~ distspec::get_parameters(.)$sd),
    as.numeric(fit_priors$sd)
  )
})

test_that("enw_replace_priors does not modify input `data.table`s", {
  priors <- example_priors()
  custom_priors <- data.table::data.table(variable = "x[1]", mean = 10, sd = 2)
  priors_copy <- data.table::copy(priors)
  custom_copy <- data.table::copy(custom_priors)
  newpriors <- enw_replace_priors(priors, custom_priors)
  expect_true(data.table::address(newpriors) != data.table::address(priors))
  expect_true(
    data.table::address(newpriors) != data.table::address(custom_priors)
  )
  expect_identical(priors, priors_copy)
  expect_identical(custom_priors, custom_copy)
  expect_identical(priors$prior[[1]], distspec::Normal(mean = 1, sd = 1))
})

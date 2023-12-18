test_that("enw_replace_priors can replace a default prior with a custom
           prior", {
  priors <- data.frame(
    variable = c("x", "y"), mean = c(1, 2), sd = c(1, 2),
    stringsAsFactors = FALSE
  )
  custom_priors <- data.frame(
    variable = "x", mean = 10, sd = 2,
    stringsAsFactors = FALSE
  )
  exp_priors <- data.table::data.table(
    variable = c("y", "x"), mean = c(2, 10), sd = c(2, 2)
  )
  expect_identical(enw_replace_priors(priors, custom_priors), exp_priors)
})

test_that("enw_replace_priors can replace a default prior with a custom
           prior when it is vectorised", {
  priors <- data.frame(
    variable = c("x", "y"), mean = c(1, 2), sd = c(1, 2),
    stringsAsFactors = FALSE
  )
  custom_priors <- data.frame(
    variable = "x[1]", mean = 10, sd = 2,
    stringsAsFactors = FALSE
  )
  exp_priors <- data.table::data.table(
    variable = c("y", "x"), mean = c(2, 10), sd = c(2, 2)
  )
  expect_identical(enw_replace_priors(priors, custom_priors), exp_priors)
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
  expect_identical(
    updated_priors[variable %in% variables]$mean, as.numeric(fit_priors$mean)
  )
  expect_identical(
    updated_priors[variable %in% variables]$sd, as.numeric(fit_priors$sd)
  )
})

test_that("enw_replace_priors does not modify input `data.table`s", {
  priors <- data.table::data.table(variable = c("x", "y"), mean = c(1, 2), sd = c(1, 2))
  custom_priors <- data.table::data.table(variable = "x[1]", mean = 10, sd = 2)
  refs <- dt_copies(priors, custom_priors)
  newpriors <- enw_replace_priors(priors, custom_priors)
  expect_true(data.table::address(newpriors) != data.table::address(priors))
  expect_true(data.table::address(newpriors) != data.table::address(custom_priors))
  expect_true(dt_compare_all(refs, priors, custom_priors))
})

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

test_that("enw_expectation exposes the uncertain generation time and latent
           reporting delay priors via enw_replace_priors() (#836)", {
  pobs <- enw_example("preprocessed")
  gt_spec <- enw_uncertain(
    "lognormal", mean = c(1.5, 0.2), sd = c(0.4, 0.1), max = 15
  )
  lrd_spec <- enw_uncertain(
    "gamma", mean = c(1.2, 0.3), sd = c(0.6, 0.2), max = 15
  )
  expectation <- enw_expectation(
    r = ~1, generation_time = gt_spec, latent_reporting_delay = lrd_spec,
    data = pobs
  )

  # The module's default `$priors` table carries the enw_uncertain() spec
  # values for all four parameters, not just as opaque Stan `data`.
  priors <- expectation$priors
  expect_identical(priors[variable == "expr_gt_mean"]$mean, gt_spec$mean_p[1])
  expect_identical(priors[variable == "expr_gt_mean"]$sd, gt_spec$mean_p[2])
  expect_identical(priors[variable == "expr_gt_sd"]$mean, gt_spec$sd_p[1])
  expect_identical(priors[variable == "expr_gt_sd"]$sd, gt_spec$sd_p[2])
  expect_identical(
    priors[variable == "expl_lrd_mean"]$mean, lrd_spec$mean_p[1]
  )
  expect_identical(priors[variable == "expl_lrd_mean"]$sd, lrd_spec$mean_p[2])
  expect_identical(priors[variable == "expl_lrd_sd"]$mean, lrd_spec$sd_p[1])
  expect_identical(priors[variable == "expl_lrd_sd"]$sd, lrd_spec$sd_p[2])

  # A user can override them with enw_replace_priors(), as for any other
  # module prior (e.g. from a previous fit's posterior).
  custom_priors <- data.frame(
    variable = c("expr_gt_mean", "expr_gt_sd", "expl_lrd_mean"),
    mean = c(2, 3, 4), sd = c(0.5, 0.6, 0.7)
  )
  updated_priors <- enw_replace_priors(priors, custom_priors)
  expect_identical(updated_priors[variable == "expr_gt_mean"]$mean, 2)
  expect_identical(updated_priors[variable == "expr_gt_sd"]$sd, 0.6)
  expect_identical(updated_priors[variable == "expl_lrd_mean"]$mean, 4)
  # Unreplaced priors are untouched.
  expect_identical(
    updated_priors[variable == "expl_lrd_sd"]$mean, lrd_spec$sd_p[1]
  )

  # The override reaches the assembled Stan data via the same
  # enw_priors_as_data_list() path used by every other overridable module
  # prior, confirming the model would actually see the replacement.
  data_list <- enw_priors_as_data_list(updated_priors)
  expect_identical(as.vector(data_list$expr_gt_mean_p), c(2, 0.5))
  expect_identical(as.vector(data_list$expr_gt_sd_p), c(3, 0.6))
  expect_identical(as.vector(data_list$expl_lrd_mean_p), c(4, 0.7))
})

test_that("enw_replace_priors does not modify input `data.table`s", {
  priors <- data.table::data.table(
    variable = c("x", "y"),
    mean = c(1, 2),
    sd = c(1, 2)
  )
  custom_priors <- data.table::data.table(variable = "x[1]", mean = 10, sd = 2)
  refs <- dt_copies(priors, custom_priors)
  newpriors <- enw_replace_priors(priors, custom_priors)
  expect_true(data.table::address(newpriors) != data.table::address(priors))
  expect_true(
    data.table::address(newpriors) != data.table::address(custom_priors)
  )
  expect_true(dt_compare_all(refs, priors, custom_priors))
})

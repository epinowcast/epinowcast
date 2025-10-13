# Use example data
pobs <- enw_example("preprocessed")

pobs_intermediate <- enw_filter_reference_dates(
  data.table::copy(pobs$obs[[1]])[, ".group" := NULL], latest_date = "2021-07-20"
)

pobs_intermediate <- enw_filter_report_dates(
  pobs_intermediate,
  latest_date = "2021-07-20"
)

pobs_filt <- enw_preprocess_data(
  pobs_intermediate, max_delay = 2
)

test_that("enw_reference requires at least one of a parametric or a
          non-parametric model to be specified", {
  expect_error(
    enw_reference(
      parametric = ~0, distribution = "none", data = pobs
    ),
    "A non-parametric model must be specified if no parametric model"
  )
  expect_error(
    enw_reference(
      parametric = ~0, data = pobs
    ),
    "A non-parametric model must be specified if no parametric model"
  )
  expect_error(
    enw_reference(
      parametric = ~0, data = pobs
    ),
    "A non-parametric model must be specified if no parametric model"
  )
})

test_that("enw_reference supports parametric models", {
  expect_snapshot({
    ref <- enw_reference(
      ~ 1 + (1 | day_of_week) + rw(week),
      distribution = "lognormal",
      data = pobs
    )
    ref$inits <- NULL
    ref
  })
  ref <- enw_reference(
    ~ 1 + (1 | day_of_week) + rw(week),
    distribution = "lognormal", data = pobs
  )
  inits <- ref$inits(ref$data, ref$priors)()
  expect_named(
    inits,
    c(
      "refp_mean_int", "refp_sd_int", "refp_mean_beta",
      "refp_sd_beta", "refp_mean_beta_sd", "refp_sd_beta_sd",
      "refnp_int", "refnp_beta", "refnp_beta_sd",
      "refp_mean", "refp_sd"
    )
  )
  c(
    "refp_mean_int", "ref_p_sd_int", "refp_mean_beta",
    "refp_sd_beta", "refp_mean_beta_sd", "refp_sd_beta_sd",
    "refp_mean", "refp_sd"
  )
  zero_length <- c("refnp_int", "refnp_beta", "refnp_beta_sd")
  expect_zero_length_or_not(zero_length, inits)

  default_ref <- enw_reference(data = pobs)
  expect_identical(default_ref$data$model_refp, 2) # default is lognormal
  exp_ref <- enw_reference(distribution = "exponential", data = pobs)
  expect_identical(exp_ref$data$model_refp, 1)
  lognormal_ref <- enw_reference(distribution = "lognormal", data = pobs)
  expect_identical(lognormal_ref$data$model_refp, 2)
  gamma_ref <- enw_reference(distribution = "gamma", data = pobs)
  expect_identical(gamma_ref$data$model_refp, 3)
  loglogistic_ref <- enw_reference(distribution = "loglogistic", data = pobs)
  expect_identical(loglogistic_ref$data$model_refp, 4)
  no_ref <- suppressWarnings(
    enw_reference(distribution = "none", non_parametric = ~1, data = pobs)
  )
  expect_identical(no_ref$data$model_refp, 0)
  no_ref2 <- suppressWarnings(
    enw_reference(parametric = ~0, non_parametric = ~1, data = pobs)
  )
  expect_identical(no_ref2$data$model_refp, 0)
  expect_identical(
    exp_ref$inits(exp_ref$data, exp_ref$priors)()$refp_sd_int, numeric(0)
  )
})

test_that("enw_reference supports non-parametric models", {
  expect_snapshot({
    ref <- enw_reference(
      parametric = ~0,
      distribution = "none",
      non_parametric = ~ 1 + (1 | delay) + rw(week),
      data = pobs_filt
    )
    ref$inits <- NULL
    ref
  })
  ref <- enw_reference(
    parametric = ~0,
    distribution = "none",
    non_parametric = ~ 1 + delay + rw(week),
    data = pobs_filt
  )
  inits <- ref$inits(ref$data, ref$priors)()
  zero_length <- c(
    "refp_mean_int", "refp_sd_int", "refp_mean_beta",
    "refp_sd_beta", "refp_mean_beta_sd", "refp_sd_beta_sd",
    "refp_mean", "refp_sd"
  )
  expect_zero_length_or_not(zero_length, inits)
  # check that not having an intercept works as expected
  ref_no_int <- enw_reference(
    parametric = ~0,
    distribution = "none",
    non_parametric = ~ 0 + delay,
    data = pobs_filt
  )
  expect_identical(colnames(ref_no_int$data$refnp_fdesign), "delay")
  expect_identical(ref_no_int$data$refnp_fintercept, 0)
  inits_no_int <- ref_no_int$inits(ref_no_int$data, ref_no_int$priors)()
  zero_length <- setdiff(names(inits_no_int), "refnp_beta")
  expect_zero_length_or_not(zero_length, inits_no_int)
})

test_that("Parametric and non-parametric models can be jointly specified", {
  expect_snapshot({
    ref <- enw_reference(
      parametric = ~1,
      non_parametric = ~ 0 + (1 | delay_cat),
      data = pobs_filt
    )
    ref$inits <- NULL
    ref
  })
  ref <- enw_reference(
    parametric = ~1,
    non_parametric = ~ 0 + (1 | delay_cat),
    data = pobs_filt
  )
  inits <- ref$inits(ref$data, ref$priors)()
  zero_length <- c(
    "refp_mean_beta", "refp_sd_beta", "refp_mean_beta_sd", "refp_sd_beta_sd",
    "refnp_int"
  )
  expect_zero_length_or_not(zero_length, inits)
})

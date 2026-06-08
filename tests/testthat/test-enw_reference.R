# Use example data
pobs <- enw_example("preprocessed")

pobs_intermediate <- enw_filter_reference_dates(
  data.table::copy(pobs$obs[[1]])[, ".group" := NULL],
  latest_date = "2021-07-20",
  include_days = 40
)

pobs_intermediate <- enw_filter_report_dates(
  pobs_intermediate,
  latest_date = "2021-07-20"
)

pobs_filt <- enw_preprocess_data(
  pobs_intermediate,
  max_delay = 2
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
      "refp_mean", "refp_sd",
      "refp_arima_pacf", "refp_arima_theta", "refp_arima_sigma",
      "refp_arima_sd_sigma", "refp_arima_z",
      "refp_gp_rho", "refp_gp_alpha", "refp_gp_sd_alpha",
      "refnp_arima_pacf", "refnp_arima_theta", "refnp_arima_sigma",
      "refnp_gp_rho", "refnp_gp_alpha"
    )
  )
  c(
    "refp_mean_int", "ref_p_sd_int", "refp_mean_beta",
    "refp_sd_beta", "refp_mean_beta_sd", "refp_sd_beta_sd",
    "refp_mean", "refp_sd"
  )
  zero_length <- c(
    "refnp_int", "refnp_beta", "refnp_beta_sd",
    "refp_arima_pacf", "refp_arima_theta",
    "refp_gp_rho", "refp_gp_alpha", "refp_gp_sd_alpha",
    "refnp_arima_pacf", "refnp_arima_theta", "refnp_arima_sigma",
    "refnp_gp_rho", "refnp_gp_alpha"
  )
  expect_zero_length_or_not(zero_length, inits)

  default_ref <- enw_reference(data = pobs)
  expect_identical(default_ref$data$model_refp, 2) # default is lognormal
  exp_ref <- enw_reference(distribution = "exponential", data = pobs)
  expect_identical(exp_ref$data$model_refp, 1)
  lognormal_ref <- enw_reference(distribution = "lognormal", data = pobs)
  expect_identical(lognormal_ref$data$model_refp, 2)
  gamma_ref <- enw_reference(distribution = "gamma", data = pobs)
  expect_identical(gamma_ref$data$model_refp, 3)
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

test_that("enw_reference does not expose a discretisation toggle", {
  # The primarycensored discretisation is always used for the supported
  # parametric distributions; there is no discretisation argument or
  # refp_pcens data flag.
  expect_false("discretisation" %in% names(formals(enw_reference)))

  for (dist in c("exponential", "lognormal", "gamma")) {
    ref <- enw_reference(distribution = dist, data = pobs)
    expect_null(ref$data$refp_pcens)
  }
})

test_that("enw_reference does not accept the loglogistic option", {
  # loglogistic is unsupported pending primarycensored support
  # (epinowcast/primarycensored#321).
  expect_false("loglogistic" %in% eval(formals(enw_reference)$distribution))
  expect_error(
    enw_reference(distribution = "loglogistic", data = pobs)
  )
})

test_that("vendored Stan dist ids match the primarycensored lookup", {
  # enw_to_pcens_dist_id() in primarycensored_pmf.stan hard-codes the
  # primarycensored Stan dist ids. Pin them to primarycensored's own lookup so
  # an upstream renumbering fails here rather than silently mis-mapping.
  skip_if_not_installed("primarycensored")
  expect_identical(primarycensored::pcd_stan_dist_id("lognormal"), 1L)
  expect_identical(primarycensored::pcd_stan_dist_id("gamma"), 2L)
  # epinowcast routes its exponential through the gamma id with shape 1 for the
  # analytical solution, not primarycensored's standalone exponential id.
  expect_identical(primarycensored::pcd_stan_dist_id("exponential"), 4L)
})

test_that("enw_reference supports non-parametric models", {
  ref_snapshot <- enw_reference(
    parametric = ~0,
    distribution = "none",
    non_parametric = ~ 1 + (1 | delay) + rw(week),
    data = pobs
  )
  expect_snapshot({
    ref_snapshot$inits <- NULL
    ref_snapshot
  })
  ref <- enw_reference(
    parametric = ~0,
    distribution = "none",
    non_parametric = ~ 1 + delay + rw(week),
    data = pobs
  )
  inits <- ref$inits(ref$data, ref$priors)()
  # rw(week) now flows through the ARIMA backend, so the
  # corresponding step coefficients live in refnp_arima_z and the
  # step standard deviation in refnp_arima_sigma rather than in
  # refnp_beta_sd. With only fixed effects (delay) and an ARIMA
  # term, refnp_rncol = 0 so refnp_beta_sd is empty.
  zero_length <- c(
    "refp_mean_int", "refp_sd_int", "refp_mean_beta",
    "refp_sd_beta", "refp_mean_beta_sd", "refp_sd_beta_sd",
    "refp_mean", "refp_sd", "refnp_beta_sd",
    "refp_arima_pacf", "refp_arima_theta", "refp_arima_sigma",
    "refp_arima_sd_sigma", "refnp_arima_pacf", "refnp_arima_theta",
    "refp_gp_rho", "refp_gp_alpha", "refp_gp_sd_alpha",
    "refnp_gp_rho", "refnp_gp_alpha"
  )
  expect_zero_length_or_not(zero_length, inits)
  # check that not having an intercept works as expected
  ref_no_int <- enw_reference(
    parametric = ~0,
    distribution = "none",
    non_parametric = ~ 0 + delay,
    data = pobs
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
      data = pobs
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
    "refnp_int",
    "refp_arima_pacf", "refp_arima_theta", "refp_arima_sigma",
    "refp_arima_sd_sigma", "refnp_arima_pacf", "refnp_arima_theta",
    "refnp_arima_sigma",
    "refp_gp_rho", "refp_gp_alpha", "refp_gp_sd_alpha",
    "refnp_gp_rho", "refnp_gp_alpha"
  )
  expect_zero_length_or_not(zero_length, inits)
})

test_that(
  "enw_reference allows both ~0 when max_delay = 1",
  {
    obs <- data.table::data.table(
      reference_date = as.Date("2021-01-01") + 0:9,
      report_date = as.Date("2021-01-01") + 0:9,
      confirm = rpois(10, 50)
    )
    pobs_retro <- enw_preprocess_data(obs, max_delay = 1)

    ref <- enw_reference(
      parametric = ~0, non_parametric = ~0, data = pobs_retro
    )
    expect_identical(ref$data$model_refp, 0)
    expect_identical(ref$data$model_refnp, 0)
  }
)

test_that(
  "enw_reference errors on delay model with max_delay = 1",
  {
    obs <- data.table::data.table(
      reference_date = as.Date("2021-01-01") + 0:9,
      report_date = as.Date("2021-01-01") + 0:9,
      confirm = rpois(10, 50)
    )
    pobs_retro <- enw_preprocess_data(obs, max_delay = 1)

    expect_error(
      enw_reference(parametric = ~1, data = pobs_retro),
      "Reference date models cannot be used"
    )
    expect_error(
      enw_reference(
        parametric = ~0, non_parametric = ~1, data = pobs_retro
      ),
      "Reference date models cannot be used"
    )
  }
)

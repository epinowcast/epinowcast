# Helper to fit a small model for forecast tests
fit_for_forecast <- function() {
  obs <- enw_filter_reference_dates(
    enw_filter_report_dates(
      germany_covid19_hosp[age_group == "00+"][location == "DE"],
      remove_days = 10
    ),
    include_days = 10
  )
  pobs <- enw_preprocess_data(obs, max_delay = 5)
  suppressMessages(epinowcast(
    pobs,
    expectation = enw_expectation(r = ~1, data = pobs),
    fit = enw_fit_opts(
      sampler = silent_enw_sample, pp = TRUE, chains = 1,
      iter_warmup = 200, iter_sampling = 200,
      refresh = 0, show_messages = FALSE
    ),
    model = model
  ))
}

test_that("enw_forecast() rejects non-epinowcast input", {
  expect_error(
    enw_forecast(list(), model = NULL),
    "must be a fitted"
  )
})

test_that("enw_forecast() rejects unsupported overrides", {
  fit <- structure(list(), class = "epinowcast")
  expect_error(
    enw_forecast(fit, overrides = list(refp_mean = 1), model = NULL),
    "Unsupported override"
  )
  expect_error(
    enw_forecast(fit, overrides = c(1, 2), model = NULL),
    "must be a named list"
  )
  expect_error(
    enw_forecast(fit, horizon = -1, model = NULL),
    "non-negative"
  )
})

test_that("enw_forecast() horizon > 0 requires an r override", {
  fit <- structure(list(), class = "epinowcast")
  # enw_get_data is only reached after validation, so a bare object is fine
  expect_error(
    enw_forecast(fit, horizon = 5, model = NULL),
    "overrides\\$r"
  )
})

test_that("enw_resolve_growth_rate() guards against a mismatched fit", {
  # Stub fit whose posterior growth rate length does not match expr_len
  stub_fit <- list(
    summary = function(...) data.frame(mean = c(0.1, 0.2, 0.3))
  )
  expect_error(
    enw_resolve_growth_rate(NULL, stub_fit, expr_len = 5L),
    "incompatible model"
  )
  expect_error(
    enw_resolve_growth_rate(0.1, stub_fit, expr_len = 5L),
    "incompatible model"
  )
  # Matching length passes through
  expect_identical(
    enw_resolve_growth_rate(NULL, stub_fit, expr_len = 3L),
    c(0.1, 0.2, 0.3)
  )
})

test_that("enw_forecast() with no override uses the per-draw posterior", {
  skip_on_cran()
  skip_on_local()

  fit <- fit_for_forecast()
  forecast <- suppressMessages(enw_forecast(fit, model = model))

  expect_s3_class(forecast, "epinowcast")

  # No override: the growth rate is taken per draw from the posterior, so the
  # override hook is disabled and the nowcast reproduces the fit up to the
  # observation-model redraw.
  expect_identical(forecast$data[[1]]$expr_r_override, 0L)

  orig <- fit$fit[[1]]$summary("pp_inf_obs")$mean
  redriven <- forecast$fit[[1]]$summary("pp_inf_obs")$mean
  expect_identical(length(orig), length(redriven))
  expect_lt(max(abs(orig - redriven)) / mean(orig), 0.2)
})

test_that("enw_forecast() responds to a new growth rate override", {
  skip_on_cran()
  skip_on_local()

  fit <- fit_for_forecast()
  forecast_up <- suppressMessages(
    enw_forecast(fit, overrides = list(r = 0.3), model = model)
  )
  forecast_down <- suppressMessages(
    enw_forecast(fit, overrides = list(r = -0.3), model = model)
  )

  expect_identical(forecast_up$data[[1]]$expr_r_override, 1L)
  growing <- forecast_up$fit[[1]]$summary("pp_inf_obs")$mean
  declining <- forecast_down$fit[[1]]$summary("pp_inf_obs")$mean
  expect_gt(growing[length(growing)], declining[length(declining)])
})

test_that("enw_forecast() validates the growth rate override length", {
  skip_on_cran()
  skip_on_local()

  fit <- fit_for_forecast()
  expect_error(
    enw_forecast(fit, overrides = list(r = c(0.1, 0.2)), model = model),
    "must have length 1"
  )
})

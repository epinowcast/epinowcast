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

test_that("enw_forecast() re-driving with the posterior matches the fit", {
  skip_on_cran()
  skip_on_local()

  fit <- fit_for_forecast()
  forecast <- suppressMessages(enw_forecast(fit, model = model))

  expect_s3_class(forecast, "epinowcast")
  orig <- fit$fit[[1]]$summary("pp_inf_obs")$mean
  redriven <- forecast$fit[[1]]$summary("pp_inf_obs")$mean
  expect_identical(length(orig), length(redriven))
  # Re-driving redraws the observation model so allow Monte Carlo noise
  expect_lt(max(abs(orig - redriven)) / mean(orig), 0.5)
})

test_that("enw_forecast() responds to a new growth rate trajectory", {
  skip_on_cran()
  skip_on_local()

  fit <- fit_for_forecast()
  forecast_up <- suppressMessages(
    enw_forecast(fit, growth_rate = 0.3, model = model)
  )
  forecast_down <- suppressMessages(
    enw_forecast(fit, growth_rate = -0.3, model = model)
  )

  growing <- forecast_up$fit[[1]]$summary("pp_inf_obs")$mean
  declining <- forecast_down$fit[[1]]$summary("pp_inf_obs")$mean
  expect_gt(growing[length(growing)], declining[length(declining)])
})

test_that("enw_forecast() validates growth rate length", {
  skip_on_cran()
  skip_on_local()

  fit <- fit_for_forecast()
  expect_error(
    enw_forecast(fit, growth_rate = c(0.1, 0.2), model = model),
    "must have length 1"
  )
})

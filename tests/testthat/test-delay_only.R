# Tests for the delay-only model: fitting the reporting-delay distribution
# conditional on known per-reference-date totals via a (truncated)
# multinomial.

# Discretised lognormal delay PMF matching the package's primarycensored
# double interval censoring discretisation (uniform primary window and daily
# secondary censoring, truncated at dmax). Simulating from the same scheme the
# model fits means the recovered refp_mean_int / refp_sd_int are directly
# comparable to the simulation parameters.
disc_lognormal_pmf <- function(meanlog, sdlog, dmax) {
  primarycensored::dprimarycensored(
    0:(dmax - 1), stats::plnorm, pwindow = 1, swindow = 1, D = dmax,
    meanlog = meanlog, sdlog = sdlog
  )
}

# Build a full reporting triangle from a known delay PMF and a constant
# known total per reference date. `truncate = TRUE` keeps only reports up
# to the most recent reference date, so recent reference dates only observe
# early delays and their known totals are partial running totals.
simulate_delay_triangle <- function(meanlog = 1.6, sdlog = 0.5,
                                    max_delay = 15, n_dates = 60,
                                    total = 2000, truncate = FALSE) {
  pmf <- disc_lognormal_pmf(meanlog, sdlog, max_delay)
  counts <- round(total * pmf)
  dates <- as.Date("2021-01-01") + 0:(n_dates - 1)
  delays <- 0:(max_delay - 1)
  obs <- data.table::rbindlist(lapply(seq_along(dates), function(i) {
    data.table::data.table(
      reference_date = dates[i],
      report_date = dates[i] + delays,
      confirm = cumsum(counts)
    )
  }))
  if (truncate) {
    obs <- obs[report_date <= max(dates)]
  }
  list(obs = obs, pmf = pmf)
}

fit_delay_only <- function(pobs, model) {
  suppressWarnings(suppressMessages(epinowcast(
    pobs,
    expectation = enw_expectation(~1, data = pobs),
    reference = enw_reference(~1, data = pobs),
    obs = enw_obs(delay_only = TRUE, data = pobs),
    fit = enw_fit_opts(
      sampler = silent_enw_sample, nowcast = FALSE, pp = FALSE,
      chains = 2, iter_warmup = 500, iter_sampling = 500,
      show_messages = FALSE, refresh = 0, seed = 8675309
    ),
    model = model
  )))
}

test_that("delay_only enw_obs() sets the expected data entries", {
  pobs <- enw_example("preprocessed")
  o <- enw_obs(delay_only = TRUE, data = pobs)
  expect_identical(o$data$model_delay_only, 1L)
  expect_identical(
    dim(o$data$dlo_ltotal), c(pobs$groups[[1]], pobs$time[[1]])
  )
  o0 <- enw_obs(data = pobs)
  expect_identical(o0$data$model_delay_only, 0L)
  expect_identical(ncol(o0$data$dlo_ltotal), 0L)
})

test_that("delay_only forces the multinomial likelihood and ignores family", {
  pobs <- enw_example("preprocessed")
  # No family needed: the multinomial path is selected (model_obs == 0).
  o <- enw_obs(delay_only = TRUE, data = pobs)
  expect_identical(o$data$model_delay_only, 1L)
  expect_identical(o$data$model_obs, 0)
  expect_identical(o$family, "poisson")

  # A supplied family is ignored and warned about, with model_obs still 0.
  expect_warning(
    o_warn <- enw_obs(family = "negbin", delay_only = TRUE, data = pobs),
    "ignored when"
  )
  expect_identical(o_warn$data$model_obs, 0)
  expect_identical(o_warn$data$model_delay_only, 1L)

  # The full model keeps family behaviour unchanged (no warning).
  expect_no_warning(
    o_full <- enw_obs(family = "negbin", data = pobs)
  )
  expect_identical(o_full$data$model_obs, 1)
})

test_that(".expectation_is_minimal() detects an intercept-only expectation", {
  pobs <- enw_example("preprocessed")
  expect_true(
    .expectation_is_minimal(enw_expectation(r = ~1, data = pobs))
  )
  expect_false(
    .expectation_is_minimal(
      enw_expectation(r = ~ 1 + (1 | day), data = pobs)
    )
  )
  expect_false(.expectation_is_minimal(enw_expectation(data = pobs)))
})

test_that("epinowcast() minimises the expectation for a delay_only fit", {
  pobs <- enw_example("preprocessed")
  # The flexible default expectation is swapped for a minimal one so a
  # delay-only fit needs no separately neutered expectation module. We use a
  # stub sampler to capture the assembled data list without fitting.
  nowcast <- suppressMessages(epinowcast(
    pobs,
    obs = enw_obs(delay_only = TRUE, data = pobs),
    fit = enw_fit_opts(
      sampler = function(init, data, ...) {
        data.table::data.table(data = list(data))
      }
    ),
    model = NULL
  ))
  data_list <- nowcast$data[[1]]
  expect_identical(data_list$model_delay_only, 1L)
  # Minimal growth model: no random-effect columns (the flexible default has
  # day:.group random effects).
  expect_equal(data_list$expr_rncol, 0)
})

test_that("delay_only supports an observation indicator", {
  skip_if_not_installed("primarycensored")
  sim <- simulate_delay_triangle(
    meanlog = 1.6, sdlog = 0.5, max_delay = 10, n_dates = 20, total = 2000
  )
  comp <- enw_complete_dates(sim$obs, flag_observation = TRUE)
  pobs <- enw_preprocess_data(comp, max_delay = 10)
  o <- enw_obs(
    delay_only = TRUE, observation_indicator = ".observed", data = pobs
  )
  expect_identical(o$data$model_delay_only, 1L)
})

test_that("delay_only floors non-positive / missing totals to log 0", {
  # The log total is only an offset on the expected cells and cancels in the
  # multinomial, so reference dates with no observed total (e.g. recent dates
  # under an observation indicator) are floored to 1 (log 0) rather than
  # erroring; they contribute nothing to the likelihood.
  pobs <- enw_example("preprocessed")
  bad <- data.table::copy(pobs)
  bad$latest[[1]] <- data.table::copy(pobs$latest[[1]])
  bad$latest[[1]][1, confirm := 0]
  bad$latest[[1]][2, confirm := NA_real_]
  ltotal <- enw_obs(delay_only = TRUE, data = bad)$data$dlo_ltotal
  expect_true(all(is.finite(ltotal)))
  expect_equal(unname(ltotal[1, 1]), 0)
  expect_equal(unname(ltotal[1, 2]), 0)
})

test_that("delay_only is incompatible with the missing reference model", {
  pobs <- enw_example("preprocessed")
  # Fabricate a module list with the missing model switched on alongside a
  # delay-only obs module to exercise the compatibility guard directly.
  modules <- list(
    enw_expectation(~1, data = pobs), enw_reference(~1, data = pobs),
    enw_report(~1, data = pobs),
    list(data = list(model_miss = 1L)),
    enw_obs(delay_only = TRUE, data = pobs),
    enw_fit_opts(likelihood_aggregation = "groups")
  )
  expect_error(check_modules_compatible(modules), "missing reference model")
})

test_that("delay_only recovers a known delay distribution", {
  skip_on_cran()
  skip_on_local()
  model <- enw_model()

  sim <- simulate_delay_triangle(
    meanlog = 1.6, sdlog = 0.5, max_delay = 15, n_dates = 60, total = 2000
  )
  pobs <- enw_preprocess_data(sim$obs, max_delay = 15)
  nowcast <- fit_delay_only(pobs, model)

  expect_lt(nowcast$max_rhat, 1.05)
  fit_pars <- nowcast$fit[[1]]$summary(c("refp_mean_int", "refp_sd_int"))
  expect_equal(
    fit_pars$mean[fit_pars$variable == "refp_mean_int[1]"], 1.6,
    tolerance = 0.05
  )
  expect_equal(
    fit_pars$mean[fit_pars$variable == "refp_sd_int[1]"], 0.5,
    tolerance = 0.05
  )
})

test_that("delay_only recovers a known delay from truncated totals", {
  skip_on_cran()
  skip_on_local()
  model <- enw_model()

  # Truncated triangle: recent reference dates only observe early delays, so
  # their totals are partial running totals. Recovery relies on the truncated
  # multinomial renormalising over the observed delay range.
  sim <- simulate_delay_triangle(
    meanlog = 1.6, sdlog = 0.5, max_delay = 15, n_dates = 60, total = 2000,
    truncate = TRUE
  )
  pobs <- enw_preprocess_data(sim$obs, max_delay = 15)
  nowcast <- fit_delay_only(pobs, model)

  expect_lt(nowcast$max_rhat, 1.05)
  fit_pars <- nowcast$fit[[1]]$summary(c("refp_mean_int", "refp_sd_int"))
  expect_equal(
    fit_pars$mean[fit_pars$variable == "refp_mean_int[1]"], 1.6,
    tolerance = 0.05
  )
  expect_equal(
    fit_pars$mean[fit_pars$variable == "refp_sd_int[1]"], 0.5,
    tolerance = 0.05
  )
})

test_that("delay_only with nowcast = TRUE produces coherent output", {
  skip_on_cran()
  skip_on_local()
  model <- enw_model()

  # Delay-only mode is for delay estimation, not nowcasting. With the default
  # nowcast = TRUE the cast / posterior-prediction block must be skipped so no
  # incoherent per-cell nowcast is drawn from the unused observation model.
  # Only the pointwise log likelihood (the delay-only multinomial) is produced.
  sim <- simulate_delay_triangle(
    meanlog = 1.6, sdlog = 0.5, max_delay = 10, n_dates = 40, total = 2000
  )
  pobs <- enw_preprocess_data(sim$obs, max_delay = 10)
  nowcast <- suppressWarnings(suppressMessages(epinowcast(
    pobs,
    expectation = enw_expectation(~1, data = pobs),
    reference = enw_reference(~1, data = pobs),
    obs = enw_obs(delay_only = TRUE, data = pobs),
    fit = enw_fit_opts(
      sampler = silent_enw_sample, nowcast = TRUE, pp = TRUE,
      output_loglik = TRUE, chains = 2, iter_warmup = 300, iter_sampling = 300,
      show_messages = FALSE, refresh = 0, seed = 8675309
    ),
    model = model
  )))

  stan_vars <- nowcast$fit[[1]]$metadata()$stan_variables
  # No per-cell nowcast / posterior-prediction arrays are produced
  expect_false("pp_inf_obs" %in% stan_vars)
  expect_false("pp_obs" %in% stan_vars)
  # The pointwise log likelihood uses the delay-only multinomial
  log_lik <- nowcast$fit[[1]]$draws("log_lik", format = "matrix")
  expect_true(all(is.finite(log_lik)))
  expect_true(any(log_lik != 0))
  # The delay is still recovered with nowcast = TRUE
  fit_pars <- nowcast$fit[[1]]$summary(c("refp_mean_int", "refp_sd_int"))
  expect_equal(
    fit_pars$mean[fit_pars$variable == "refp_mean_int[1]"], 1.6,
    tolerance = 0.05
  )
  expect_equal(
    fit_pars$mean[fit_pars$variable == "refp_sd_int[1]"], 0.5,
    tolerance = 0.05
  )
})

test_that("delay_only recovers a known delay with an observation indicator", {
  skip_on_cran()
  skip_on_local()
  model <- enw_model()

  # Mask interior delay cells (an observation indicator) and confirm the
  # multinomial renormalises over the observed delays to recover the delay.
  sim <- simulate_delay_triangle(
    meanlog = 1.6, sdlog = 0.5, max_delay = 10, n_dates = 50, total = 2000
  )
  comp <- enw_complete_dates(sim$obs, flag_observation = TRUE)
  comp[, .observed :=
    .observed & !(as.integer(report_date - reference_date) %in% c(3L, 6L))]
  pobs <- enw_preprocess_data(comp, max_delay = 10)
  nowcast <- suppressWarnings(suppressMessages(epinowcast(
    pobs,
    expectation = enw_expectation(~1, data = pobs),
    reference = enw_reference(~1, data = pobs),
    obs = enw_obs(
      delay_only = TRUE,
      observation_indicator = ".observed", data = pobs
    ),
    fit = enw_fit_opts(
      sampler = silent_enw_sample, nowcast = FALSE, pp = FALSE,
      chains = 2, iter_warmup = 500, iter_sampling = 500,
      show_messages = FALSE, refresh = 0, seed = 8675309
    ),
    model = model
  )))

  expect_lt(nowcast$max_rhat, 1.05)
  fit_pars <- nowcast$fit[[1]]$summary(c("refp_mean_int", "refp_sd_int"))
  expect_equal(
    fit_pars$mean[fit_pars$variable == "refp_mean_int[1]"], 1.6,
    tolerance = 0.05
  )
  expect_equal(
    fit_pars$mean[fit_pars$variable == "refp_sd_int[1]"], 0.5,
    tolerance = 0.05
  )
})

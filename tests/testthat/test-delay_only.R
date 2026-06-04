# Tests for the delay-only model (issues #775, #776). The delay-only
# likelihood fits the reporting-delay distribution conditional on known
# per-reference-date totals via a (truncated) multinomial.

# Discretised lognormal delay PMF matching the package's double-censored
# scheme (max_strat = 2 in discretised_logit_hazard.stan). Simulating from
# this means the recovered refp_mean_int / refp_sd_int are directly
# comparable to the simulation parameters.
disc_lognormal_pmf <- function(meanlog, sdlog, dmax) {
  u <- dmax
  lcdf <- stats::plnorm(1:u, meanlog, sdlog, log.p = TRUE)
  m <- max(lcdf[u], lcdf[u - 1])
  denom <- m + log(sum(exp(c(lcdf[u], lcdf[u - 1]) - m)))
  lcdf <- lcdf - denom
  p <- numeric(u)
  p[1] <- exp(lcdf[1])
  if (u > 1) p[2] <- exp(lcdf[2])
  if (u > 2) {
    for (i in 3:u) p[i] <- exp(lcdf[i]) - exp(lcdf[i - 2])
  }
  p
}

# Build a full reporting triangle from a known delay PMF and a constant
# known total per reference date. `truncate = TRUE` keeps only reports up
# to the most recent reference date, so recent reference dates only observe
# early delays and their known totals are partial running totals (#776).
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
    obs = enw_obs(family = "poisson", delay_only = TRUE, data = pobs),
    fit = enw_fit_opts(
      sampler = silent_enw_sample, nowcast = FALSE, pp = FALSE,
      chains = 2, iter_warmup = 500, iter_sampling = 500,
      show_messages = FALSE, refresh = 0
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

test_that("delay_only is incompatible with an observation indicator", {
  pobs <- enw_example("preprocessed")
  expect_error(
    enw_obs(
      delay_only = TRUE, observation_indicator = ".observed", data = pobs
    ),
    "not compatible"
  )
})

test_that("delay_only rejects non-positive totals", {
  pobs <- enw_example("preprocessed")
  bad <- data.table::copy(pobs)
  bad$latest[[1]] <- data.table::copy(pobs$latest[[1]])
  bad$latest[[1]][1, confirm := 0]
  expect_error(
    enw_obs(delay_only = TRUE, data = bad), "strictly positive"
  )
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

test_that("delay_only recovers a known delay distribution (#775)", {
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

test_that("delay_only recovers a known delay from truncated totals (#776)", {
  skip_on_cran()
  skip_on_local()
  model <- enw_model()

  # Truncated triangle: recent reference dates only observe early delays, so
  # their totals are partial running totals (#776). Recovery relies on the
  # truncated multinomial renormalising over the observed delay range.
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

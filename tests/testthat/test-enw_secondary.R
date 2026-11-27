secondary_obs <- function(pobs, scale = 0.1) {
  pobs$latest[[1]][, .(
    reference_date,
    confirm = as.integer(round(confirm * scale))
  )]
}

test_that("enw_secondary_opts() returns incidence options by default", {
  opts <- enw_secondary_opts()
  expect_type(opts, "list")
  expect_identical(opts$sec_cumulative, 0L)
  expect_identical(opts$sec_historic, 1L)
  expect_identical(opts$sec_primary_hist_additive, 1L)
  expect_identical(opts$sec_current, 0L)
  expect_identical(opts$sec_primary_current_additive, 0L)
})

test_that("enw_secondary_opts() returns prevalence options", {
  opts <- enw_secondary_opts(type = "prevalence")
  expect_identical(opts$sec_cumulative, 1L)
  expect_identical(opts$sec_historic, 1L)
  expect_identical(opts$sec_primary_hist_additive, 0L)
  expect_identical(opts$sec_current, 1L)
  expect_identical(opts$sec_primary_current_additive, 1L)
})

test_that("enw_secondary_opts() allows manual overrides", {
  opts <- enw_secondary_opts(
    cumulative = 1L, historic = 0L, current = 1L
  )
  expect_identical(opts$sec_cumulative, 1L)
  expect_identical(opts$sec_historic, 0L)
  expect_identical(opts$sec_current, 1L)
})

test_that("enw_secondary_opts() validates inputs", {
  expect_error(enw_secondary_opts(type = "nonsense"))
  expect_error(enw_secondary_opts(cumulative = 2L))
})

test_that("enw_secondary_opts() aborts cleanly on NA overrides", {
  expect_error(
    enw_secondary_opts(cumulative = NA_integer_),
    "must be a single value of 0 or 1"
  )
})

test_that("enw_secondary() returns a model module structure", {
  pobs <- enw_example("preprocessed")
  secondary <- enw_secondary(obs = secondary_obs(pobs), data = pobs)
  expect_type(secondary, "list")
  expect_named(
    secondary, c("family", "formula", "data", "priors", "inits"),
    ignore.order = TRUE
  )
  expect_true(is.list(secondary$data))
  expect_true(is.function(secondary$inits))
  expect_s3_class(secondary$priors, "data.frame")
  expect_null(check_module(secondary))
})

test_that("enw_secondary() is disabled when no observations are supplied", {
  secondary <- enw_secondary(data = enw_example("preprocessed"))
  expect_identical(secondary$data$model_sec, 0L)
})

test_that("enw_secondary() is disabled by the ~0 formula", {
  pobs <- enw_example("preprocessed")
  secondary <- enw_secondary(
    secondary = ~0, obs = secondary_obs(pobs), data = pobs
  )
  expect_identical(secondary$data$model_sec, 0L)
})

test_that("enw_secondary() encodes the secondary target options", {
  pobs <- enw_example("preprocessed")
  secondary <- enw_secondary(
    secondary = enw_secondary_opts("prevalence"),
    obs = secondary_obs(pobs), data = pobs
  )
  expect_identical(secondary$data$model_sec, 1L)
  expect_identical(secondary$data$sec_cumulative, 1L)
  expect_identical(secondary$data$sec_current, 1L)
})

test_that("enw_secondary() disabled and active data lists are shape-symmetric", {
  pobs <- enw_example("preprocessed")
  disabled <- enw_secondary(data = pobs)
  active <- enw_secondary(obs = secondary_obs(pobs), data = pobs)
  expect_identical(sort(names(disabled$data)), sort(names(active$data)))
  expect_identical(disabled$data$model_sec, 0L)
  expect_identical(disabled$data$model_sec_scale, 0L)
})

test_that("enw_secondary() builds a convolution delay of the requested size", {
  pobs <- enw_example("preprocessed")
  delay <- c(0.1, 0.3, 0.4, 0.2)
  secondary <- enw_secondary(
    obs = secondary_obs(pobs), delay = delay, data = pobs
  )
  expect_identical(secondary$data$sec_delay_n, length(delay))
  expect_identical(secondary$data$model_sec, 1L)
})

test_that("enw_secondary() selects the observation family", {
  pobs <- enw_example("preprocessed")
  poisson <- enw_secondary(
    obs = secondary_obs(pobs), family = "poisson", data = pobs
  )
  negbin <- enw_secondary(
    obs = secondary_obs(pobs), family = "negbin", data = pobs
  )
  expect_identical(poisson$data$sec_model_obs, 0L)
  expect_identical(negbin$data$sec_model_obs, 1L)
})

test_that("enw_secondary() aligns observations to the reference grid", {
  pobs <- enw_example("preprocessed")
  obs <- secondary_obs(pobs)
  # Drop the final two reference dates so they are unobserved
  obs <- obs[seq_len(.N - 2)]
  secondary <- enw_secondary(obs = obs, data = pobs)
  t <- pobs$time[[1]]
  expect_identical(dim(secondary$data$sec_obs), c(t, 1L))
  expect_identical(sum(secondary$data$sec_obs_lookup), t - 2L)
})

test_that("enw_secondary() accepts a time-varying (list of PMFs) delay", {
  pobs <- enw_example("preprocessed")
  t <- pobs$time[[1]]
  delay <- rep(list(c(0.2, 0.5, 0.3)), t)
  expect_no_error(
    secondary <- enw_secondary(
      obs = secondary_obs(pobs), delay = delay,
      data = pobs
    )
  )
  expect_identical(secondary$data$sec_delay_n, 3L)
  expect_identical(secondary$data$model_sec, 1L)
})

test_that("enw_secondary() rejects a delay PMF that does not sum to one", {
  pobs <- enw_example("preprocessed")
  expect_error(
    enw_secondary(obs = secondary_obs(pobs), delay = c(0.2, 0.2), data = pobs),
    "sum to 1"
  )
})

test_that("enw_secondary() always emits the three module priors", {
  pobs <- enw_example("preprocessed")
  secondary <- enw_secondary(obs = secondary_obs(pobs), data = pobs)
  expect_setequal(
    secondary$priors$variable,
    c("sec_scale_int", "sec_beta_sd", "sec_sqrt_phi")
  )
})

test_that("enw_secondary() convolution recovers a known secondary series", {
  pobs <- enw_example("preprocessed")
  delay <- c(0.2, 0.5, 0.3)
  scale <- 0.4
  secondary <- enw_secondary(
    obs = secondary_obs(pobs), delay = delay, data = pobs
  )

  conv <- secondary$data$sec_delay
  t <- pobs$time[[1]]
  primary <- as.numeric(latest_obs_as_matrix(pobs$latest[[1]])[, 1])

  module_secondary <- scale * as.numeric(conv %*% primary)

  ref_secondary <- numeric(t)
  for (i in seq_len(t)) {
    for (d in seq_along(delay)) {
      j <- i - d + 1
      if (j >= 1) ref_secondary[i] <- ref_secondary[i] + primary[j] * delay[d]
    }
  }
  ref_secondary <- scale * ref_secondary

  valid <- seq(length(delay), t)
  expect_equal(
    module_secondary[valid], ref_secondary[valid],
    tolerance = 1e-8
  )
})

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

test_that("enw_secondary() returns a model module structure", {
  secondary <- enw_secondary(
    data = enw_example("preprocessed")
  )
  expect_type(secondary, "list")
  expect_named(
    secondary, c("formula", "data", "priors", "inits"),
    ignore.order = TRUE
  )
  expect_true(is.list(secondary$data))
  expect_true(is.function(secondary$inits))
  expect_s3_class(secondary$priors, "data.frame")
  # Module must pass the standard module check
  expect_null(check_module(secondary))
})

test_that("enw_secondary() encodes the secondary target options", {
  secondary <- enw_secondary(
    secondary = enw_secondary_opts("prevalence"),
    data = enw_example("preprocessed")
  )
  expect_identical(secondary$data$model_sec, 1L)
  expect_identical(secondary$data$sec_cumulative, 1L)
  expect_identical(secondary$data$sec_current, 1L)
})

test_that("enw_secondary() disabled by default produces an inactive module", {
  secondary <- enw_secondary(
    secondary = ~0, data = enw_example("preprocessed")
  )
  expect_identical(secondary$data$model_sec, 0L)
})

test_that("enw_secondary() builds a convolution delay of the requested size", {
  delay <- c(0.1, 0.3, 0.4, 0.2)
  secondary <- enw_secondary(
    delay = delay, data = enw_example("preprocessed")
  )
  expect_identical(secondary$data$sec_delay_n, length(delay))
  expect_true(secondary$data$model_sec == 1L)
})

test_that("enw_secondary() convolution recovers a known secondary series", {
  # Synthetic recovery: build a primary series, convolve it with a known
  # delay and a known scaling, then check the module's convolution matrix
  # reproduces the same scaled-convolution secondary series.
  delay <- c(0.2, 0.5, 0.3)
  scale <- 0.4
  pobs <- enw_example("preprocessed")
  secondary <- enw_secondary(delay = delay, data = pobs)

  conv <- secondary$data$sec_delay
  t <- secondary$data$sec_t
  primary <- as.numeric(secondary$data$sec_primary[, 1])

  # Module convolution (matches the Stan-side sparse multiply input)
  module_secondary <- scale * as.numeric(conv %*% primary)

  # Independent reference convolution
  ref_secondary <- numeric(t)
  for (i in seq_len(t)) {
    for (d in seq_along(delay)) {
      j <- i - d + 1
      if (j >= 1) ref_secondary[i] <- ref_secondary[i] + primary[j] * delay[d]
    }
  }
  ref_secondary <- scale * ref_secondary

  # Only fully observed convolutions are comparable (drop the initial
  # partial window dropped by `include_partial = FALSE`)
  valid <- seq(length(delay), t)
  expect_equal(
    module_secondary[valid], ref_secondary[valid],
    tolerance = 1e-8
  )
})

test_that("enw_uncertain builds a lognormal spec with priors", {
  spec <- enw_uncertain(
    distribution = "lognormal",
    mean = c(1.6, 0.1),
    sd = c(0.4, 0.05),
    max = 15
  )
  expect_s3_class(spec, "enw_uncertain")
  expect_identical(spec$distribution, "lognormal")
  expect_identical(spec$max, 15L)
  expect_identical(spec$mean_p, c(1.6, 0.1))
  expect_identical(spec$sd_p, c(0.4, 0.05))
  expect_identical(spec$dist_id, 2L)
})

test_that("enw_uncertain rejects unknown distributions", {
  expect_error(
    enw_uncertain(distribution = "weibull", max = 10),
    "should be one of"
  )
})

test_that("enw_uncertain rejects a max below 2", {
  expect_error(
    enw_uncertain(distribution = "gamma", max = 1),
    "max"
  )
})

test_that("enw_uncertain rejects a non-integer, non-finite, or NA max", {
  expect_error(
    enw_uncertain(distribution = "gamma", max = 10.5),
    "max"
  )
  expect_error(
    enw_uncertain(distribution = "gamma", max = Inf),
    "max"
  )
  expect_error(
    enw_uncertain(distribution = "gamma", max = NA_integer_),
    "max"
  )
  expect_error(
    enw_uncertain(distribution = "gamma", max = c(5, 10)),
    "max"
  )
})

test_that("enw_uncertain rejects malformed priors", {
  expect_error(
    enw_uncertain(distribution = "gamma", mean = 1, max = 10),
    "length 2"
  )
  expect_error(
    enw_uncertain(distribution = "gamma", sd = c(1, 2, 3), max = 10),
    "length 2"
  )
})

test_that("enw_uncertain rejects non-finite priors", {
  expect_error(
    enw_uncertain(distribution = "gamma", mean = c(1, NA), max = 10),
    "mean"
  )
  expect_error(
    enw_uncertain(distribution = "gamma", mean = c(Inf, 1), max = 10),
    "mean"
  )
  expect_error(
    enw_uncertain(distribution = "gamma", sd = c(0.5, NaN), max = 10),
    "sd"
  )
})

test_that("enw_uncertain requires positive prior standard deviations", {
  expect_error(
    enw_uncertain(distribution = "gamma", mean = c(1, 0), max = 10),
    "mean"
  )
  expect_error(
    enw_uncertain(distribution = "gamma", sd = c(0.5, -1), max = 10),
    "sd"
  )
  # The exponential ignores `sd`, so a non-positive `sd[2]` is accepted
  # (with the usual warning) rather than rejected.
  expect_warning(
    enw_uncertain(distribution = "exponential", sd = c(0.5, 0), max = 10),
    "exponential"
  )
})

test_that("enw_uncertain maps distributions to Stan integer codes", {
  expect_identical(
    enw_uncertain(distribution = "exponential", max = 5)$dist_id, 1L
  )
  expect_identical(
    enw_uncertain(distribution = "lognormal", max = 5)$dist_id, 2L
  )
  expect_identical(
    enw_uncertain(distribution = "gamma", max = 5)$dist_id, 3L
  )
  expect_error(
    enw_uncertain(distribution = "loglogistic", max = 5)
  )
})

test_that("enw_uncertain supplies sensible default priors", {
  spec <- enw_uncertain(distribution = "lognormal", max = 10)
  expect_length(spec$mean_p, 2)
  expect_length(spec$sd_p, 2)
})

test_that("enw_uncertain warns when sd is supplied for the exponential", {
  expect_warning(
    enw_uncertain(distribution = "exponential", sd = c(1, 1), max = 6),
    "exponential"
  )
  # No warning when sd is left at its default.
  expect_no_warning(
    enw_uncertain(distribution = "exponential", max = 6)
  )
})

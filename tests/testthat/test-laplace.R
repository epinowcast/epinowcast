pobs <- enw_example("preprocessed")

test_that("enw_laplace_data builds a valid data list for an RE expectation", {
  expn <- enw_expectation(~ 1 + (1 | day_of_week), data = pobs)
  dl <- enw_laplace_data(pobs, expectation = expn)
  expect_type(dl, "list")
  expect_identical(dl$g, pobs$groups[[1]])
  expect_identical(dl$t, pobs$time[[1]])
  expect_identical(dl$dmax, pobs$max_delay[[1]])
  expect_identical(dl$expr_fintercept, 1L)
  expect_identical(dl$use_re, 1L)
  expect_gt(dl$q_re, 0)
  expect_identical(dl$use_gp, 0L)
  expect_identical(dl$obs_family, 1L)
  expect_identical(nrow(dl$X_fixed), dl$g * dl$t)
  expect_identical(nrow(dl$Z), dl$t)
  expect_length(dl$re_index, dl$q_re)
})

test_that("enw_laplace_data builds a gp() Hilbert-space basis block", {
  expn <- enw_expectation(~ 1 + gp(day), data = pobs)
  dl <- enw_laplace_data(pobs, expectation = expn)
  expect_identical(dl$use_gp, 1L)
  expect_gt(dl$gp_M, 0)
  expect_identical(nrow(dl$PHI), dl$t)
  expect_identical(ncol(dl$PHI), dl$gp_M)
})

test_that("enw_laplace_data observed cells respect the triangle boundary", {
  dl <- enw_laplace_data(pobs)
  # For each cell, ref date + delay must not exceed the number of ref dates.
  expect_true(all(dl$cell_t + dl$cell_d <= dl$t))
  # The Poisson and NB observed totals are non-negative integers.
  expect_true(all(dl$obs >= 0))
  expect_true(all(dl$row_obs_sum >= 0))
})

test_that("enw_laplace_data maps the observation family", {
  dl_nb <- enw_laplace_data(pobs, obs = enw_obs("negbin", data = pobs))
  dl_po <- enw_laplace_data(pobs, obs = enw_obs("poisson", data = pobs))
  expect_identical(dl_nb$obs_family, 1L)
  expect_identical(dl_po$obs_family, 0L)
})

test_that("the NB1 (negbin1d) family is rejected", {
  expect_error(
    enw_laplace_data(pobs, obs = enw_obs("negbin1d", data = pobs)),
    "negbin"
  )
})

test_that("a non-parametric reference model is rejected", {
  ref <- enw_reference(
    parametric = ~1, non_parametric = ~ 0 + (1 | delay), data = pobs
  )
  expect_error(
    enw_laplace_data(pobs, reference = ref),
    "non-parametric"
  )
})

test_that("a missing-reference model is rejected", {
  miss <- enw_missing(~1, data = pobs)
  expect_error(
    enw_laplace_data(pobs, missing = miss),
    "missing-reference"
  )
})

test_that("enw_laplace_inits returns finite starting values", {
  dl <- enw_laplace_data(
    pobs, expectation = enw_expectation(~ 1 + (1 | day_of_week), data = pobs)
  )
  init_fn <- enw_laplace_inits(dl)
  init <- init_fn()
  expect_true(is.finite(init$beta_fixed[1]))
  expect_true(all(init$sigma_re > 0))
  expect_true(init$sqrt_phi > 0)
})

test_that("split_laplace_design separates fixed and random columns", {
  meta <- data.table::as.data.table(pobs$metareference[[1]])
  f <- enw_formula(~ 1 + day_of_week + (1 | week), meta, sparse = FALSE)
  split <- epinowcast:::split_laplace_design(f)
  expect_identical(split$fintercept, 1)
  # Day-of-week contrasts are fixed; week dummies are random.
  expect_gt(ncol(split$X), 1)
  expect_gt(split$q_re, 0)
  expect_identical(split$n_re, 1L)
})

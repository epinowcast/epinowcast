test_that(".discretise_parametric_pmf() returns a normalised PMF", {
  skip_if_not_installed("primarycensored")
  p <- .discretise_parametric_pmf(1.6, 0.5, 15, "lognormal")
  expect_length(p, 15)
  expect_equal(sum(p), 1, tolerance = 1e-8)
  expect_true(all(p >= 0))
})

test_that(".discretise_parametric_pmf() matches primarycensored", {
  skip_if_not_installed("primarycensored")
  expect_equal(
    .discretise_parametric_pmf(1.6, 0.5, 15, "lognormal"),
    primarycensored::dprimarycensored(
      0:14, pdist = stats::plnorm, pwindow = 1, swindow = 1, D = 15,
      meanlog = 1.6, sdlog = 0.5
    ),
    tolerance = 1e-10
  )
})

test_that(".discretise_parametric_pmf() supports other distributions", {
  skip_if_not_installed("primarycensored")
  for (dist in c("gamma", "exponential", "loglogistic")) {
    p <- .discretise_parametric_pmf(1, 1, 10, dist)
    expect_equal(sum(p), 1, tolerance = 1e-8)
    expect_true(all(p >= 0))
  }
  expect_error(
    .discretise_parametric_pmf(1, 1, 10, "weibull"), "Unknown"
  )
})

# A minimal stub mimicking the `draws()` accessor of a `cmdstanr` fit. It holds
# a named matrix of draws (columns like "refp_mean[1]") and returns the columns
# matching the requested variable as a `posterior` draws object.
stub_fit <- function(draws_matrix) {
  list(
    draws = function(variables = NULL) {
      if (is.null(variables)) {
        cols <- colnames(draws_matrix)
      } else {
        pattern <- paste0("^", variables, "(\\[|$)")
        cols <- grep(pattern, colnames(draws_matrix), value = TRUE)
        if (length(cols) == 0) {
          stop("variable not found", call. = FALSE)
        }
      }
      posterior::as_draws_array(
        posterior::as_draws_matrix(draws_matrix[, cols, drop = FALSE])
      )
    }
  )
}

test_that("enw_posterior_delay() returns long posterior PMF draws", {
  skip_on_cran()
  skip_on_local()

  fit <- enw_example("nowcast")$fit[[1]]
  pmf <- enw_posterior_delay(fit, max_delay = 20, draws = 25)
  expect_data_table(pmf)
  expect_identical(names(pmf), c(".draw", "delay", "pmf"))
  expect_identical(length(unique(pmf$.draw)), 25L)
  # Each draw's PMF integrates to 1
  by_draw <- pmf[, .(total = sum(pmf)), by = ".draw"]
  expect_true(all(abs(by_draw$total - 1) < 1e-6))
})

test_that("enw_posterior_delay() keeps intercept-only output shape", {
  skip_if_not_installed("primarycensored")
  set.seed(1)
  m <- cbind(
    "refp_mean[1]" = rnorm(20, 1.6, 0.05),
    "refp_sd[1]" = rep(0.5, 20)
  )
  pmf <- enw_posterior_delay(stub_fit(m), max_delay = 15)
  expect_data_table(pmf)
  expect_identical(names(pmf), c(".draw", "delay", "pmf"))
  expect_identical(length(unique(pmf$.draw)), 20L)
  by_draw <- pmf[, .(total = sum(pmf)), by = ".draw"]
  expect_true(all(abs(by_draw$total - 1) < 1e-6))
})

test_that("enw_posterior_delay() returns per-row PMFs for a delay model", {
  skip_if_not_installed("primarycensored")
  set.seed(2)
  # Two reference-design rows with clearly different delay means.
  m <- cbind(
    "refp_mean[1]" = rnorm(30, 1.0, 0.01),
    "refp_mean[2]" = rnorm(30, 2.5, 0.01),
    "refp_sd[1]" = rep(0.5, 30),
    "refp_sd[2]" = rep(0.5, 30)
  )
  pmf <- enw_posterior_delay(stub_fit(m), max_delay = 20)
  expect_data_table(pmf)
  expect_identical(names(pmf), c("row", ".draw", "delay", "pmf"))
  expect_identical(sort(unique(pmf$row)), c(1L, 2L))
  # Each (row, draw) PMF integrates to 1.
  by_rd <- pmf[, .(total = sum(pmf)), by = c("row", ".draw")]
  expect_true(all(abs(by_rd$total - 1) < 1e-6))
  # The two rows have genuinely different PMFs (different delay means).
  mean_delay <- pmf[
    , .(md = sum(delay * pmf) / sum(pmf)), by = c("row", ".draw")
  ]
  md_row1 <- mean(mean_delay[row == 1L]$md)
  md_row2 <- mean(mean_delay[row == 2L]$md)
  expect_gt(md_row2, md_row1)
})

test_that("enw_posterior_delay() errors for a non-parametric model", {
  # A fit without `refp_mean` (model_refp == 0) cannot produce a delay PMF.
  m <- cbind("refnp_int[1]" = rnorm(10))
  expect_error(
    enw_posterior_delay(stub_fit(m), max_delay = 10),
    "refp_mean"
  )
})

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

test_that(".discretise_parametric_pmf() returns a normalised PMF", {
  p <- .discretise_parametric_pmf(1.6, 0.5, 15, "lognormal")
  expect_length(p, 15)
  expect_equal(sum(p), 1, tolerance = 1e-8)
  expect_true(all(p >= 0))
})

test_that(".discretise_parametric_pmf() matches the double-censored scheme", {
  # Reference implementation of the max_strat = 2 double-censored lognormal.
  ref <- function(meanlog, sdlog, dmax) {
    u <- dmax
    lcdf <- stats::plnorm(1:u, meanlog, sdlog, log.p = TRUE)
    m <- max(lcdf[u], lcdf[u - 1])
    lcdf <- lcdf - (m + log(sum(exp(c(lcdf[u], lcdf[u - 1]) - m))))
    p <- numeric(u)
    p[1] <- exp(lcdf[1])
    p[2] <- exp(lcdf[2])
    for (i in 3:u) p[i] <- exp(lcdf[i]) - exp(lcdf[i - 2])
    p
  }
  expect_equal(
    .discretise_parametric_pmf(1.6, 0.5, 15, "lognormal"),
    ref(1.6, 0.5, 15),
    tolerance = 1e-10
  )
})

test_that(".discretise_parametric_pmf() supports other distributions", {
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

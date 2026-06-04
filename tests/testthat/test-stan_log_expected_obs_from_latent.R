skip_on_cran()
skip_on_os("windows")
skip_on_os("mac")
skip_on_local()

test_that("log_expected_obs_from_latent_pmf convolves a PMF correctly", {
  # latent series (log scale) and a known forward PMF (delays 0:2)
  rd_n <- 3L
  t <- 8L
  ft <- t + rd_n - 1L
  latent <- log(seq_len(ft) * 10)
  pmf <- c(0.2, 0.5, 0.3)
  prop <- rep(0, t)

  out <- log_expected_obs_from_latent_pmf(
    list(latent), pmf, rd_n, t, 1L, prop
  )[[1]]

  # Manual convolution: obs at reference time s uses latent[s:(s+rd_n-1)]
  # weighted by the reversed PMF.
  natural <- exp(latent)
  expected <- vapply(seq_len(t), function(s) {
    sum(natural[s:(s + rd_n - 1)] * rev(pmf))
  }, numeric(1))

  expect_equal(exp(out), expected, tolerance = 1e-8)
})

test_that("log_expected_obs_from_latent_pmf applies the latent-obs proportion", {
  rd_n <- 2L
  t <- 5L
  ft <- t + rd_n - 1L
  latent <- log(rep(100, ft))
  pmf <- c(0.7, 0.3)
  prop <- log(rep(0.4, t))

  out <- log_expected_obs_from_latent_pmf(
    list(latent), pmf, rd_n, t, 1L, prop
  )[[1]]
  # Convolution of a constant series with a PMF summing to 1 is the constant,
  # then scaled by the proportion.
  expect_equal(exp(out), rep(100 * 0.4, t), tolerance = 1e-8)
})

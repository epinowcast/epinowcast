skip_on_cran()
skip_on_os("windows")
skip_on_os("mac")
skip_on_local()

enw_stan_to_r(
  c("discretised_logit_hazard.stan", "hazard.stan"),
  system.file("stan", "functions", package = "epinowcast")
)
# note these tests require enw_stan_to_r() to be run first

test_that(
  "discretised_logit_hazard() returns log probabilities that sum to 1", {
  expect_equal_to_1 <- function(lp) {
    expect_equal(sum(exp(lp)), 1.0)
  }
  # Exponential
  expect_equal_to_1(discretised_logit_hazard(1, 0.5, 10, 1, 2, 1))
  # Log-normal
  expect_equal_to_1(discretised_logit_hazard(1, 0.5, 10, 2, 2, 1))
  # Gamma
  expect_equal_to_1(discretised_logit_hazard(1, 0.5, 15, 3, 2, 1))
  # Loglogistic
  expect_equal_to_1(discretised_logit_hazard(1, 0.5, 15, 4, 2, 1))
})

test_that(
  "discretised_logit_hazard() returns probabilities as logit hazards that
   sum to 1", {
  expect_equal_to_1 <- function(lh) {
    lh <- plogis(lh)
    lh <- hazard_to_log_prob(lh)
    p <- exp(lh)
    expect_equal(sum(p), 1.0)
  }
  # Exponential
  expect_equal_to_1(discretised_logit_hazard(1, 0.5, 10, 1, 2, 0))
  # Log-normal
  expect_equal_to_1(discretised_logit_hazard(1, 0.5, 10, 2, 2, 0))
  # Gamma
  expect_equal_to_1(discretised_logit_hazard(1, 0.5, 15, 3, 2, 0))
  # Loglogistic
  expect_equal_to_1(discretised_logit_hazard(1, 0.5, 15, 4, 2, 0))
})

test_that("discretised_logit_hazard() returns the same thing in both log
           probability and logit hazard mode when everything is mapped to
           the probability scale", {
  expect_equal_prob <- function(alpha, beta, dist) {
    lp <- discretised_logit_hazard(alpha, beta, 10, dist, 2, 1)
    lh <- discretised_logit_hazard(alpha, beta, 10, dist, 2, 0)
    lh <- plogis(lh)
    lh <- hazard_to_log_prob(lh)
    expect_equal( # nolint: expect_identical_linter.
      round(exp(lp), 4), round(exp(lh), 4)
    )
  }
  # Exponential
  expect_equal_prob(1, 0.5, 1)
  expect_equal_prob(2, 1, 1)
  expect_equal_prob(3, 0.2, 1)
  # Log-normal
  expect_equal_prob(1, 0.5, 2)
  expect_equal_prob(2, 1, 2)
  expect_equal_prob(3, 0.2, 2)
  # Gamma
  expect_equal_prob(1, 0.5, 3)
  expect_equal_prob(2, 1, 3)
  expect_equal_prob(3, 0.2, 3)
  # Loglogistic
  expect_equal_prob(1, 0.5, 4)
  expect_equal_prob(2, 1, 4)
  expect_equal_prob(3, 0.2, 4)
})

# Discretisation for double censoring
double_censored_pmf <- function(n, alpha, beta, fun = plnorm) {
  cdf <- fun(1:(n + 1), alpha, beta)
  pmf <- vector("numeric", n)
  pmf[1] <- cdf[1]
  pmf[2] <- cdf[2]
  pmf[3:n] <- cdf[3:n] - cdf[1:(n - 2)]
  pmf <- pmf / sum(pmf)
  return(pmf)
}

# Discretisation for single censoring
single_censored_pmf <- function(n, alpha, beta, fun = plnorm) {
  cdf <- fun(1:(n + 1), alpha, beta)
  pmf <- vector("numeric", n)
  pmf[1] <- cdf[1]
  pmf[2:n] <- cdf[2:n] - cdf[1:(n - 1)]
  pmf <- pmf / cdf[n]
  return(pmf)
}

# Simulate double censored data
simulate_double_censored_pmf <- function(
    alpha, beta, max, fun = rlnorm, n = 1000) {
  primary <- runif(n, 0, 1)
  secondary <- primary + fun(n, alpha, beta)
  delay <- floor(secondary) - floor(primary)
  cdf <- ecdf(delay)(0:max)
  pmf <- c(cdf[1], diff(cdf))
  return(pmf)
}

# Assume that you have the function hazard_to_log_prob, as it's not provided.
test_that("double_censored_pmf() and discretised_logit_hazard() are similar", {
  truncations <- seq(10, 100, by = 10) # Choose your desired truncation levels
  alphas <- seq(0.1, 2, by = 0.1)
  betas <- seq(0.1, 2, by = 0.1)

  for (truncation in truncations) {
    for (alpha in alphas) {
      for (beta in betas) {
        expect_equal(
          double_censored_pmf(truncation, alpha, beta),
          exp(discretised_logit_hazard(alpha, beta, truncation, 2, 2, 1)),
          tolerance = 1e-4
        )
      }
    }
  }
})

test_that(
  "double_censored_pmf() approximates simulated_double_censored_pmf() well
   enough",
  {
    # Approximation does not perform well at shorter delays due to issues
    # with the discretisation near 0
    for (alpha in seq(0.4, 1.5, by = 0.1)) {
      for (beta in seq(0.3, 1.5, by = 0.1)) {
        sim <- simulate_double_censored_pmf(alpha, beta, 100, rlnorm, 1000)
        n <- length(sim)
        # Double censoring should have the same mean as the simulated data
        expect_equal(
          mean(sim),
          mean(double_censored_pmf(n, alpha, beta)),
          tolerance = 0.1
        )
        # Double censoring should have the same variance as the simulated data
        expect_equal(
          var(sim),
          var(double_censored_pmf(n, alpha, beta)),
          tolerance = 0.1
        )
        # Double censoring should not give an error greater than 0.1 for any
        # single value
        expect_lt(
          max(abs(sim - double_censored_pmf(n, alpha, beta))),
          0.125
        )
        # Double censoring should not have a median error greater than 0.01
        expect_lt(
          median(abs(sim - double_censored_pmf(n, alpha, beta))),
          0.01
        )
        # Double censoring should be closer to the simulated data than single
        # censoring
        expect_lte(
          sum(abs(sim - double_censored_pmf(n, alpha, beta))),
          sum(abs(sim - single_censored_pmf(n, alpha, beta)))
        )
      }
    }
  }
)

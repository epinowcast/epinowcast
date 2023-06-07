skip_on_cran()
skip_on_os("windows")
skip_on_os("mac")
skip_on_local()

epinowcast:::expose_stan_fns(
  c("discretised_logit_hazard.stan", "hazard.stan"),
  system.file("stan/functions", package = "epinowcast")
)

test_that("discretised_logit_hazard returns log probabilities that sum to 1", {
  expect_equal_to_1 <- function(lp) {
    expect_equal(sum(exp(lp)), 1)
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

test_that("discretised_logit_hazard returns probabilities as logit hazards that
           sum to 1", {
  expect_equal_to_1 <- function(lh) {
    lh <- plogis(lh)
    lh <- hazard_to_log_prob(lh)
    p <- exp(lh)
    expect_equal(sum(p), 1)
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

test_that("discretised_logit_hazard returns the same thing in both log
           probability and logit hazard mode when everything is mapped to
           the probability scale", {
  expect_equal_prob <- function(alpha, beta, dist) {
    lp <- discretised_logit_hazard(alpha, beta, 10, dist, 2, 1)
    lh <- discretised_logit_hazard(alpha, beta, 10, dist, 2, 0)
    lh <- plogis(lh)
    lh <- hazard_to_log_prob(lh)
    expect_equal(
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
  cdf <- fun(0:(n+1), alpha, beta)
  m <- n + 1 
  pmf <- vector(length = m)
  pmf[1] <-  cdf[1]
  pmf[2] <- 2 * cdf[2] - 2 * cdf[1]
  pmf[3:m] <- 3:(m+1) * cdf[1:(m+1)] - 2 * (2:m) * cdf[2:m] + (1:(m-1)) * cdf[1:(m-1)]
  return(pmf)
}
double_censored_pmf(10, 0.6, 0.5)
# Compare stan vs R - they should be the same
!(sum(abs((plnorm(c(1:11), 0.6, 0.5) - plnorm(c(0, 0:9), 0.6, 0.5)) / 2 -
  exp(discretised_logit_hazard(0.6, 0.5, 11, 2, 2, 1)))) > 1e-3)


simulate_double_censored_pmf <- function(
  alpha, beta, max, fun = rlnorm, n = 1000
) {
  primary <- runif(n, 0, 1)
  secondary <- primary + fun(n, alpha, beta)
  delay <- floor(secondary) - floor(primary)
  cdf <- ecdf(delay)(0:max)
  pmf <- c(cdf[1], diff(cdf))
  return(pmf)
}
sim <- simulate_double_censored_pmf(0.6, 0.5, 10, rlnorm, 1000)

# Compare simulation to continuous pmf
print(sim - dlnorm(0:10, 0.6, 0.5))

# Compare to naive discretisation
print(sim - (plnorm(1:11, 0.6, 0.5) - plnorm(c(0:10), 0.6, 0.5)))

# Compare to window of 2 discretisation
print(sim - (plnorm(c(1:11), 0.6, 0.5) - plnorm(c(0, 0:9), 0.6, 0.5)) / (plnorm(11, 0.6, 0.5) + plnorm(10, 0.6, 0.5) - plnorm(0, 0.6, 0.5)))


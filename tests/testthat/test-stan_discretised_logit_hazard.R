skip_on_cran()
skip_on_os("windows")
skip_on_os("mac")
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

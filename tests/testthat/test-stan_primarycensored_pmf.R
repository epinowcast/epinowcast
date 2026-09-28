skip_on_cran()
skip_on_os("windows")
skip_on_os("mac")
skip_on_local()
skip_if_not_installed("primarycensored")

# Reference double interval censored PMF from the primarycensored package.
# pwindow = 1 (uniform primary event window), swindow = 1 (daily secondary
# censoring) and right truncation at D = max_delay match the assumptions of
# discretised_pcens_logit_hazard().
pcens_reference_pmf <- function(mu, sigma, dmax, dist) {
  if (dist == 1) {
    pmf <- primarycensored::dprimarycensored(
      0:(dmax - 1), pexp,
      pwindow = 1, swindow = 1, D = dmax,
      rate = exp(-mu)
    )
  } else if (dist == 2) {
    pmf <- primarycensored::dprimarycensored(
      0:(dmax - 1), plnorm,
      pwindow = 1, swindow = 1, D = dmax,
      meanlog = mu, sdlog = sigma
    )
  } else if (dist == 3) {
    pmf <- primarycensored::dprimarycensored(
      0:(dmax - 1), pgamma,
      pwindow = 1, swindow = 1, D = dmax,
      shape = exp(mu), rate = sigma
    )
  } else {
    stop("Unsupported distribution id")
  }
  pmf
}

test_that(
  "discretised_pcens_logit_hazard() log probabilities sum to 1",
  {
    expect_equal_to_1 <- function(lp) {
      expect_equal(sum(exp(lp)), 1.0)
    }
    # Exponential
    expect_equal_to_1(discretised_pcens_logit_hazard(1, 0.5, 10, 1, 1))
    # Lognormal
    expect_equal_to_1(discretised_pcens_logit_hazard(1, 0.5, 10, 2, 1))
    # Gamma
    expect_equal_to_1(discretised_pcens_logit_hazard(1, 0.5, 15, 3, 1))
  }
)

test_that(
  "discretised_pcens_logit_hazard() logit hazards imply a PMF summing to 1",
  {
    expect_equal_to_1 <- function(lh) {
      lh <- plogis(lh)
      lh <- hazard_to_log_prob(lh, length(lh))
      expect_equal(sum(exp(lh)), 1.0)
    }
    # Exponential
    expect_equal_to_1(discretised_pcens_logit_hazard(1, 0.5, 10, 1, 0))
    # Lognormal
    expect_equal_to_1(discretised_pcens_logit_hazard(1, 0.5, 10, 2, 0))
    # Gamma
    expect_equal_to_1(discretised_pcens_logit_hazard(1, 0.5, 15, 3, 0))
  }
)

test_that(
  "discretised_pcens_logit_hazard() agrees in probability and hazard mode",
  {
    expect_equal_prob <- function(mu, sigma, dist) {
      lp <- discretised_pcens_logit_hazard(mu, sigma, 15, dist, 1)
      lh <- discretised_pcens_logit_hazard(mu, sigma, 15, dist, 0)
      lh <- plogis(lh)
      lh <- hazard_to_log_prob(lh, length(lh))
      expect_equal( # nolint: expect_identical_linter.
        round(exp(lp), 5), round(exp(lh), 5)
      )
    }
    for (dist in 1:3) {
      expect_equal_prob(1, 0.5, dist)
      expect_equal_prob(2, 1, dist)
      expect_equal_prob(0.5, 0.7, dist)
    }
  }
)

test_that(
  "discretised_pcens_logit_hazard() matches primarycensored::dprimarycensored",
  {
    for (dist in 1:3) {
      for (mu in c(0.5, 1, 1.5)) {
        for (sigma in c(0.4, 0.7, 1)) {
          dmax <- 20
          expect_equal(
            exp(discretised_pcens_logit_hazard(mu, sigma, dmax, dist, 1)),
            pcens_reference_pmf(mu, sigma, dmax, dist),
            tolerance = 1e-4
          )
        }
      }
    }
  }
)

test_that(
  "discretised_pcens_logit_hazard() rejects unsupported distributions",
  {
    # loglogistic (epinowcast id 4) is not supported by primarycensored
    expect_error(discretised_pcens_logit_hazard(1, 0.5, 10, 4, 1))
  }
)

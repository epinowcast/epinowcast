skip_on_cran()
skip_on_os("windows")
skip_on_os("mac")
skip_on_local()

test_that("expected_obs() works correctly with no reporting day effect", {
  tar_obs <- log(1)
  date_p <- log(
    (plnorm(1:30, 1.5, 2) - plnorm(0:29, 1.5, 2)) / plnorm(30, 1.5, 2)
  )
  rep_lh <- rep(0, 30)
  eobs <- exp(expected_obs(
    tar_obs, date_p + rep(0, 30), 30, 1, 0,
    array(integer(0)), matrix(integer(0), nrow = 0, ncol = 0)
  ))
  expect_equal(eobs, exp(date_p), tolerance = 1e-7)
})

test_that(
  "expected_obs() works correctly with hazard effect only on last date of report", { # nolint
  tar_obs <- log(1)
  date_p <- log(
    (plnorm(1:30, 1.5, 2) - plnorm(0:29, 1.5, 2)) / plnorm(30, 1.5, 2)
  )
  ref_lh <- qlogis(prob_to_hazard(exp(date_p)))
  eobs <- exp(
    expected_obs(
      tar_obs, ref_lh, 30, 0, 0,
      array(integer(0)), matrix(integer(0), nrow = 0, ncol = 0)
    )
  )
  expect_equal(eobs, exp(date_p), tolerance = 1e-7)
})

test_that(
  "expected_obs() works correctly with a single day of additional reporting hazard", { # nolint
  tar_obs <- log(1)
  rep_lh <- rep(0, 30)
  rep_lh[7] <- 2
  equal_lh <- plogis(hazard_to_log_prob(rep(1 / 30, 30), 30))
  eobs <- round(exp(
    expected_obs(
      tar_obs, equal_lh + rep_lh, 30, 0, 0,
      array(integer(0)), matrix(integer(0), nrow = 0, ncol = 0)
    )
  ), 3)
  expected <- c(0.508, 0.250, 0.123, 0.060, 0.030, 0.015, 0.013, 0.001)
  expect_equal(eobs[seq_along(expected)], expected, tolerance = 1e-3)
})

test_that("expected_obs() works correctly with multiple hazards", {
  tar_obs <- log(1)
  rep_lh <- rep(0, 30)
  rep_lh[c(6, 12, 16)] <- 2
  rep_lh[c(2, 20)] <- -2
  equal_lh <- plogis(hazard_to_log_prob(rep(1 / 30, 30), 30))
  eobs <- round(exp(
    expected_obs(
      tar_obs, equal_lh + rep_lh, 30, 0, 0,
      array(integer(0)), matrix(integer(0), nrow = 0, ncol = 0)
    )
  ), 3)
  expected <- c(0.508, 0.060, 0.219, 0.108, 0.053, 0.046, 0.003, 0.002, 0.001,
                rep(0.000, 21))
  expect_equal(eobs, expected, tolerance = 1e-3)
})

test_that("expected_obs() aggregates probabilities with precomputed indices", {
  skip_on_cran()
  skip_on_os("windows")
  skip_on_os("mac")
  skip_on_local()

  tar_obs <- log(1)
  lh <- log(
    (plnorm(1:30, 1.5, 2) - plnorm(0:29, 1.5, 2)) / plnorm(30, 1.5, 2)
  )

  # Create aggregation matrix: every 5th element aggregates the previous 5
  agg_probs <- matrix(c(rep(0, times = 30 * 4),
                        rep(c(rep(1, times = 5),
                              rep(0, times = 6 * 5 + 30 * 4)),
                            times = 5),
                        rep(1, times = 5)), ncol = 30, byrow = TRUE)

  # Precompute indices using helper function
  indices_list <- epinowcast:::.precompute_matrix_indices(agg_probs)

  # Use standalone Stan model via generated quantities
  model <- cmdstanr::cmdstan_model("stan/test_expected_obs.stan")

  stan_data <- list(
    tar_obs = tar_obs,
    lh = lh,
    l = length(lh),
    ref_as_p = 1L,
    rep_agg_p = 1L,
    n_selected = as.integer(indices_list$n_selected),
    selected_idx = matrix(as.integer(indices_list$selected_idx),
                          nrow = nrow(indices_list$selected_idx))
  )

  fit <- model$sample(
    data = stan_data,
    fixed_param = TRUE,
    iter_sampling = 1,
    chains = 1,
    refresh = 0
  )

  exp_obs <- fit$draws("result", format = "matrix")[1, ]

  # Expected output using matrix multiplication
  exp_output <- as.vector(tar_obs + log(agg_probs %*% exp(lh)))

  expect_equal(object = as.vector(exp_obs), expected = exp_output, tolerance = 1e-7)
})

test_that("expected_obs() handles structural zeros with precomputed indices", {
  skip_on_cran()
  skip_on_os("windows")
  skip_on_os("mac")
  skip_on_local()

  # Wednesday-only reporting: only day 4 reports (aggregates days 1-7)
  tar_obs <- log(100)
  lh <- log(c(0.2, 0.2, 0.2, 0.2, 0.1, 0.05, 0.05))

  # Aggregation matrix: only row 4 has entries
  agg_probs <- matrix(0, nrow = 7, ncol = 7)
  agg_probs[4, ] <- 1

  # Precompute indices using helper function
  indices_list <- epinowcast:::.precompute_matrix_indices(agg_probs)

  # Use standalone Stan model via generated quantities
  model <- cmdstanr::cmdstan_model("stan/test_expected_obs.stan")

  stan_data <- list(
    tar_obs = tar_obs,
    lh = lh,
    l = length(lh),
    ref_as_p = 1L,
    rep_agg_p = 1L,
    n_selected = as.integer(indices_list$n_selected),
    selected_idx = matrix(as.integer(indices_list$selected_idx),
                          nrow = nrow(indices_list$selected_idx))
  )

  fit <- model$sample(
    data = stan_data,
    fixed_param = TRUE,
    iter_sampling = 1,
    chains = 1,
    refresh = 0
  )

  exp_obs <- fit$draws("result", format = "matrix")[1, ]

  # Only Wednesday (day 4) should have finite value
  expect_true(is.finite(exp_obs[4]))
  expect_true(all(is.infinite(exp_obs[-4])))

  # Wednesday should aggregate all probabilities
  expect_equal(
    exp_obs[4],
    tar_obs + log(sum(exp(lh))),
    tolerance = 1e-7
  )
})

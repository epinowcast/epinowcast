skip_on_cran()
skip_on_os("windows")
skip_on_os("mac")
skip_on_local()

compile_secondary_model <- function() {
  cmdstanr::cmdstan_model(
    file.path("stan", "test_calculate_secondary.stan"),
    include_paths = system.file("stan", package = "epinowcast")
  )
}

run_secondary <- function(model, data) {
  fit <- model$sample(
    data = data, fixed_param = TRUE, iter_sampling = 1, chains = 1,
    refresh = 0, show_messages = FALSE
  )
  as.vector(fit$draws("result", format = "matrix")[1, ])
}

test_that("calculate_secondary() reproduces an incidence convolution", {
  model <- compile_secondary_model()
  t <- 10
  conv <- as.numeric(1:t)
  data <- list(
    t = t, scaled_reports = rep(0, t), conv_reports = conv,
    obs = rep(0L, t), cumulative = 0L, historic = 1L,
    primary_hist_additive = 1L, current = 0L,
    primary_current_additive = 0L, predict = t
  )
  result <- run_secondary(model, data)
  expect_equal(result, pmax(1e-6, conv), tolerance = 1e-6)
})

test_that("calculate_secondary() scales the current primary term", {
  model <- compile_secondary_model()
  t <- 8
  scaled <- as.numeric(seq(2, by = 2, length.out = t))
  data <- list(
    t = t, scaled_reports = scaled, conv_reports = rep(0, t),
    obs = rep(0L, t), cumulative = 0L, historic = 0L,
    primary_hist_additive = 0L, current = 1L,
    primary_current_additive = 1L, predict = t
  )
  result <- run_secondary(model, data)
  expect_equal(result, scaled, tolerance = 1e-6)
})

test_that("calculate_secondary() accumulates a prevalence target", {
  model <- compile_secondary_model()
  t <- 6
  # Inflow (additive current) minus outflow (subtractive historic)
  inflow <- c(5, 4, 3, 2, 1, 1)
  outflow <- c(0, 1, 1, 2, 2, 1)
  # predict = 0 carries the modelled value forward at every step
  data <- list(
    t = t, scaled_reports = inflow, conv_reports = outflow,
    obs = rep(0L, t), cumulative = 1L, historic = 1L,
    primary_hist_additive = 0L, current = 1L,
    primary_current_additive = 1L, predict = 0L
  )
  result <- run_secondary(model, data)
  # Manual cumulative recursion (floored at 1e-6)
  expected <- numeric(t)
  expected[1] <- max(1e-6, inflow[1] - outflow[1])
  for (i in 2:t) {
    expected[i] <- max(1e-6, expected[i - 1] + inflow[i] - outflow[i])
  }
  expect_equal(result, expected, tolerance = 1e-6)
})

test_that("calculate_secondary() seeds prevalence from observed data", {
  model <- compile_secondary_model()
  t <- 5
  obs <- c(10L, 12L, 14L, 16L, 18L)
  inflow <- c(1, 1, 1, 1, 1)
  data <- list(
    t = t, scaled_reports = inflow, conv_reports = rep(0, t),
    obs = obs, cumulative = 1L, historic = 0L,
    primary_hist_additive = 0L, current = 1L,
    primary_current_additive = 1L, predict = 2L
  )
  result <- run_secondary(model, data)
  # For i <= predict seed from obs[i - 1]; otherwise carry the model forward
  expected <- numeric(t)
  expected[1] <- max(1e-6, inflow[1])
  for (i in 2:t) {
    prev <- if (i > 2) expected[i - 1] else obs[i - 1]
    expected[i] <- max(1e-6, prev + inflow[i])
  }
  expect_equal(result, expected, tolerance = 1e-6)
})

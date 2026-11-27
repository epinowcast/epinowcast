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

# Reference implementation mirroring EpiNow2's per-element ordering exactly:
# clamp the subtractive historic term at 0 before adding the current term, then
# add 1e-6 at the end (allowing a negative result when current is subtractive).
ref_calculate_secondary <- function(scaled, conv, obs, cumulative, historic,
                                    hist_add, current, cur_add, predict) {
  t <- length(scaled)
  out <- numeric(t)
  for (i in seq_len(t)) {
    if (cumulative && i > 1) {
      out[i] <- if (i > predict) out[i - 1] else obs[i - 1]
    }
    if (historic) {
      if (hist_add) {
        out[i] <- out[i] + conv[i]
      } else {
        out[i] <- max(0, out[i] - conv[i])
      }
    }
    if (current) {
      out[i] <- if (cur_add) out[i] + scaled[i] else out[i] - scaled[i]
    }
    out[i] <- out[i] + 1e-6
  }
  out
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
  # EpiNow2 adds 1e-6 at the end rather than flooring
  expect_equal(result, conv + 1e-6, tolerance = 1e-9)
  expect_equal(
    result,
    ref_calculate_secondary(
      rep(0, t), conv, rep(0L, t), FALSE, TRUE, TRUE, FALSE, FALSE, t
    ),
    tolerance = 1e-9
  )
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
  expect_equal(result, scaled + 1e-6, tolerance = 1e-9)
})

test_that(
  "calculate_secondary() clamps subtractive historic at 0 in incidence",
  {
    model <- compile_secondary_model()
    t <- 4
    # Subtractive historic exceeds 0; current additive added afterwards
    conv <- c(5, 5, 5, 5)
    scaled <- c(10, 0, 0, 0)
    data <- list(
      t = t, scaled_reports = scaled, conv_reports = conv,
      obs = rep(0L, t), cumulative = 0L, historic = 1L,
      primary_hist_additive = 0L, current = 1L,
      primary_current_additive = 1L, predict = t
    )
    result <- run_secondary(model, data)
    # fmax(0, 0 - 5) = 0, then + scaled; so element 1 = 10, rest = 0 (+1e-6)
    expect_equal(result, c(10, 0, 0, 0) + 1e-6, tolerance = 1e-9)
  }
)

test_that("calculate_secondary() accumulates a prevalence target", {
  model <- compile_secondary_model()
  t <- 6
  # Inflow (additive current) and outflow (subtractive historic)
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
  expect_equal(
    result,
    ref_calculate_secondary(
      inflow, outflow, rep(0L, t), TRUE, TRUE, FALSE, TRUE, TRUE, 0
    ),
    tolerance = 1e-9
  )
})

test_that(
  "calculate_secondary() matches EpiNow2 outflow-before-inflow ordering",
  {
    # H1 regression: prev = 2, outflow = 5, inflow = 10.
    # EpiNow2 clamps the outflow at 0 BEFORE adding inflow:
    #   fmax(0, 2 - 5) = 0; 0 + 10 = 10 (not 2 - 5 + 10 = 7).
    model <- compile_secondary_model()
    t <- 2
    data <- list(
      t = t, scaled_reports = c(0, 10), conv_reports = c(0, 5),
      obs = rep(0L, t), cumulative = 1L, historic = 1L,
      primary_hist_additive = 0L, current = 1L,
      primary_current_additive = 1L, predict = 0L
    )
    result <- run_secondary(model, data)
    # Element 1: prev = 0, fmax(0, 0 - 0) = 0, + 0 -> 0 (+1e-6)
    # Element 2: prev = secondary[1] = 1e-6, fmax(0, 1e-6 - 5) = 0, + 10 -> 10
    expect_equal(result[2], 10 + 1e-6, tolerance = 1e-9)
    expect_false(isTRUE(all.equal(result[2], 7 + 1e-6)))
  }
)

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
  expect_equal(
    result,
    ref_calculate_secondary(
      inflow, rep(0, t), obs, TRUE, FALSE, FALSE, TRUE, TRUE, 2
    ),
    tolerance = 1e-9
  )
})

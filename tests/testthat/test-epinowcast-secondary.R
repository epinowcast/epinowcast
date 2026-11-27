skip_on_cran()
skip_on_os("windows")
skip_on_os("mac")
skip_on_local()

# Synthetic-recovery integration test: simulate a secondary outcome as a
# scaled (and optionally delayed) function of the primary series, then check
# the jointly fitted secondary model recovers the scaling.
test_that("epinowcast() jointly recovers a primary -> secondary scaling", {
  pd <- enw_example("preprocessed")
  set.seed(202)

  primary <- latest_obs_as_matrix(pd$latest[[1]])[, 1]
  true_scale <- 0.3
  sec_counts <- rpois(length(primary), true_scale * primary)
  obs <- data.table::data.table(
    reference_date = pd$metareference[[1]]$date,
    confirm = as.integer(sec_counts)
  )

  secondary <- enw_secondary(
    secondary = enw_secondary_opts("incidence"),
    obs = obs, scale = ~1, family = "poisson", data = pd
  )

  nowcast <- suppressMessages(epinowcast(
    pd,
    secondary = secondary,
    fit = enw_fit_opts(
      pp = FALSE, chains = 2, parallel_chains = 2,
      iter_warmup = 500, iter_sampling = 500,
      show_messages = FALSE, refresh = 0
    )
  ))

  scale_draws <- nowcast$fit[[1]]$summary("sec_scale_int")
  expect_lt(scale_draws$rhat, 1.1)
  # Recover the true log scaling within a wide interval
  expect_gt(scale_draws$q5, log(true_scale) - 0.5)
  expect_lt(scale_draws$q95, log(true_scale) + 0.5)

  # Expected secondary observations are produced and finite
  exp_sec <- nowcast$fit[[1]]$summary("exp_sec")
  expect_true(all(is.finite(exp_sec$mean)))
  expect_true(all(exp_sec$mean > 0))
})

test_that("epinowcast() fits a prevalence secondary target", {
  pd <- enw_example("preprocessed")
  set.seed(303)

  primary <- latest_obs_as_matrix(pd$latest[[1]])[, 1]
  # Crude prevalence: accumulate a scaled fraction of admissions
  prevalence <- cumsum(0.2 * primary) - cumsum(0.15 * primary)
  sec_counts <- rpois(length(prevalence), pmax(1, prevalence))
  obs <- data.table::data.table(
    reference_date = pd$metareference[[1]]$date,
    confirm = as.integer(sec_counts)
  )

  secondary <- enw_secondary(
    secondary = enw_secondary_opts("prevalence"),
    obs = obs, family = "poisson", data = pd
  )

  nowcast <- suppressMessages(epinowcast(
    pd,
    secondary = secondary,
    fit = enw_fit_opts(
      pp = FALSE, chains = 1,
      iter_warmup = 400, iter_sampling = 400,
      show_messages = FALSE, refresh = 0
    )
  ))

  exp_sec <- nowcast$fit[[1]]$summary("exp_sec")
  expect_true(all(is.finite(exp_sec$mean)))
  expect_true(all(exp_sec$mean > 0))
})

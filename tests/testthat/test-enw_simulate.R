test_that("enw_simulate() validates the growth rate length", {
  pobs <- enw_example("preprocessed")
  expect_error(
    enw_simulate(pobs, model = NULL),
    "growth_rate"
  )
  expect_error(
    enw_simulate(
      pobs,
      growth_rate = c(0.1, 0.2),
      expectation = enw_expectation(r = ~1, data = pobs),
      model = NULL
    ),
    "must have length 1"
  )
})

test_that("enw_simulate() forward-generates from fixed parameters", {
  skip_on_cran()
  skip_on_local()

  pobs <- enw_example("preprocessed")
  sims <- suppressMessages(enw_simulate(
    pobs,
    growth_rate = 0.05,
    parameters = list(
      refp_mean_int = 1.5, refp_sd_int = 0.5, sqrt_phi = 0.5
    ),
    reference = enw_reference(~1, data = pobs),
    expectation = enw_expectation(r = ~1, data = pobs),
    model = model
  ))

  expect_s3_class(sims, "epinowcast")
  expect_identical(class(sims$fit[[1]])[1], "CmdStanMCMC")

  # The supplied growth rate and parameter were used (not sampled)
  expect_equal(
    sims$fit[[1]]$summary("r")$mean[1], 0.05,
    tolerance = 1e-6
  )
  expect_equal(
    sims$fit[[1]]$summary("refp_mean_int")$mean, 1.5,
    tolerance = 1e-6
  )

  # Synthetic nowcast observations were generated. The nowcast spans
  # min(dmax, t) time points per group.
  data_list <- sims$data[[1]]
  expected_rows <- min(data_list$dmax, data_list$t) * data_list$g
  pp_inf <- sims$fit[[1]]$summary("pp_inf_obs")
  expect_identical(nrow(pp_inf), as.integer(expected_rows))
  expect_true(all(pp_inf$mean >= 0))
})

test_that("enw_simulate() growth rate sets the trajectory direction", {
  skip_on_cran()
  skip_on_local()

  pobs <- enw_example("preprocessed")
  sim_growing <- suppressMessages(enw_simulate(
    pobs,
    growth_rate = 0.2,
    parameters = list(refp_mean_int = 1.5, refp_sd_int = 0.5),
    reference = enw_reference(~1, data = pobs),
    expectation = enw_expectation(r = ~1, data = pobs),
    model = model
  ))
  sim_declining <- suppressMessages(enw_simulate(
    pobs,
    growth_rate = -0.2,
    parameters = list(refp_mean_int = 1.5, refp_sd_int = 0.5),
    reference = enw_reference(~1, data = pobs),
    expectation = enw_expectation(r = ~1, data = pobs),
    model = model
  ))

  growing <- sim_growing$fit[[1]]$summary("pp_inf_obs")$mean
  declining <- sim_declining$fit[[1]]$summary("pp_inf_obs")$mean
  expect_gt(growing[length(growing)], declining[length(declining)])
})

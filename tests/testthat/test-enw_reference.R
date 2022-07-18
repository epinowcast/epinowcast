# Use example data
pobs <- enw_example("preprocessed")

test_that("enw_reference supports parametric models", {
  expect_snapshot({
    ref <- enw_reference(
      ~ 1 + (1 | day_of_week) + rw(week),
      distribution = "lognormal",
      data = pobs
    )
    ref$inits <- NULL
    ref
  })
  ref <- enw_reference(
    ~ 1 + (1 | day_of_week) + rw(week),
    distribution = "lognormal", data = pobs
  )
  expect_named(
    ref$init(ref$data, ref$priors)(),
    c(
      "refp_mean_int", "refp_sd_int", "refp_mean_beta",
      "refp_sd_beta", "refp_mean_beta_sd", "refp_sd_beta_sd",
      "refp_mean", "refp_sd"
    )
  )

  expect_equal(
    enw_reference(distribution = "gamma", data = pobs)$data$model_refp, 3
  )
  exp_ref <- enw_reference(distribution = "exponential", data = pobs)
  expect_equal(exp_ref$data$model_refp, 1)
  expect_equal(
    exp_ref$init(exp_ref$data, exp_ref$priors)()$refp_sd_int, numeric(0)
  )
})

test_that("enw_reference does not support non-parametric models", {
  expect_error(
    enw_reference(non_parametric = ~ 1 + day_of_week, data = pobs)
  )
  expect_warning(enw_reference(distribution = "none", data = pobs))
})

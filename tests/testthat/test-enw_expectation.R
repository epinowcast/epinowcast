# Use example data
pobs <- enw_example("preprocessed")

test_that("enw_expectation produces the expected default model", {
  expect_snapshot({
    expectation <- enw_expectation(data = pobs)
    expectation$inits <- NULL
    expectation
  })
  exp <- enw_expectation(~ 1 + day_of_week, data = pobs)
  obs <- enw_obs(data = pobs)
  expect_named(
    exp$init(c(exp$data, obs$data), exp$priors)(),
    c("exp_beta", "exp_beta_sd", "leobs_init", "eobs_lsd", "leobs_resids")
  )
  expect_equal(enw_expectation(order = 2, data = pobs)$data$exp_order, 2)
  expect_error(enw_expectation(order = 3, data = pobs))
})

test_that("enw_expectation supports custom expectation models", {
  expect_snapshot({
    expectation <- enw_expectation(~ 1 + (1 | day_of_week), data = pobs)
    expectation$inits <- NULL
    expectation
  })
  expect_error(ewn_expectation(~0, data = pobs))
})

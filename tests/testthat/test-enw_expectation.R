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
    c("expr_beta", "expr_beta_sd", "expr_lelatent_int", "expr_r_int")
  )
})

test_that("enw_expectation supports custom expectation models", {
  expect_snapshot({
    expectation <- enw_expectation(~ 1 + (1 | day_of_week), data = pobs)
    expectation$inits <- NULL
    expectation
  })
  expect_error(enw_expectation(~0, data = pobs))
})

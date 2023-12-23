test_that("summary.epinowcast passes to lower level functions as expected", {
  fit <- enw_example("nowcast")
  expect_error(summary(fit, type = "not_a_type"))
  expect_equal(
    summary(fit, type = "nowcast"),
    with(fit, enw_nowcast_summary(
      fit[[1]], latest[[1]], max_delay
      ))
  )
  expect_equal(
    summary(fit, type = "nowcast_samples"),
    with(fit, enw_nowcast_samples(
      fit[[1]], latest[[1]], max_delay
      ))
  )
  expect_equal(
    summary(fit, type = "fit"),
    with(fit, enw_posterior(fit[[1]]))
  )
  expect_equal(
    summary(fit, type = "posterior_prediction"),
    with(fit, enw_pp_summary(fit[[1]], new_confirm[[1]]))
  )
})

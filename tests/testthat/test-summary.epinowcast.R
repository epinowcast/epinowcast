test_that("summary.epinowcast passes to lower level functions as expected", {
  fit <- enw_example("nowcast")
  expect_error(summary(fit, type = "not_a_type"))
  expect_identical(
    summary(fit, type = "nowcast"),
    with(fit, enw_nowcast_summary(
      fit[[1]], latest[[1]]
      ))
  )
  expect_identical(
    summary(fit, type = "nowcast_samples"),
    with(fit, enw_nowcast_samples(
      fit[[1]], latest[[1]]
      ))
  )
  expect_identical(
    summary(fit, type = "fit"),
    with(fit, enw_posterior(fit[[1]]))
  )
  expect_identical(
    summary(fit, type = "posterior_prediction"),
    with(fit, enw_pp_summary(fit[[1]], new_confirm[[1]]))
  )
})

test_that(
  "summary.epinowcast throws error when max_delay shorter than modeled",
  {
    fit <- enw_example("nowcast")
    expect_error(
      summary(fit, max_delay = fit$max_delay - 1),
      "specified maximum delay must be equal to or larger than the modeled"
    )
  }
)

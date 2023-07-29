test_that("check_max_delay produces the expected warnings", {
  latest_obs <- enw_example("preprocessed_observations")$latest[[1]]

  expect_warning(
    check_max_delay(latest_obs, list(spec = 20, obs = 10, model = 10)),
    regexp = "You specified a maximum delay of"
  )

  expect_no_warning(
    check_max_delay(latest_obs, list(spec = 20, obs = 20, model = 20))
  )

  expect_no_warning(
    check_max_delay(latest_obs, list(spec = 20, obs = 30, model = 30))
  )

  latest_obs$cum_prop_reported <- rep(0.5, nrow(latest_obs))
  expect_warning(
    check_max_delay(latest_obs, list(spec = 20, obs = 20, model = 20)),
    regexp = "The currently specified maximum reporting delay"
  )
})

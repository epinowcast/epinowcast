test_that("check_max_delay produces the expected warnings", {
  latest_obs <- enw_example("preprocessed_observations")$latest[[1]]
  ex_metamaxdelay <- enw_example("preprocessed_observations")$metamaxdelay[[1]]
  
  ex_metamaxdelay[, delay := c(20, 10, 10)]
  expect_warning(
    check_max_delay(latest_obs, ex_metamaxdelay),
    regexp = "You specified a maximum delay of"
  )

  ex_metamaxdelay[, delay := c(20, 20, 20)]
  expect_no_warning(
    check_max_delay(latest_obs, ex_metamaxdelay)
  )

  ex_metamaxdelay[, delay := c(20, 30, 30)]
  expect_no_warning(
    check_max_delay(latest_obs, ex_metamaxdelay)
  )

  latest_obs$cum_prop_reported <- rep(0.5, nrow(latest_obs))
  ex_metamaxdelay[, delay := c(20, 20, 20)]
  expect_warning(
    check_max_delay(latest_obs, ex_metamaxdelay),
    regexp = "The currently specified maximum reporting delay"
  )
})

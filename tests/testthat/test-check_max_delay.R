test_that("check_max_delay produces the expected warnings", {
  latest_obs <- enw_example("nowcast")$latest[[1]]
  
  expect_warning(
    check_max_delay(latest_obs, list(spec = 20, obs = 10, model = 10)),
    regexp = "will only model delays until the observed maximum delay"
    )
  
  expect_no_warning(
    check_max_delay(latest_obs, list(spec = 20, obs = 20, model = 20))
    )
  
  expect_no_warning(
    check_max_delay(latest_obs, list(spec = 20, obs = 30, model = 30))
  )
  
  latest_obs$cum_prop_reported <- runif(nrow(latest_obs), min = 0.3, max = 0.79)
  expect_warning(
    check_max_delay(latest_obs, list(spec = 20, obs = 20, model = 20)),
    regexp = "Consider using a larger maximum delay"
  )
})

test_that("enw_metadata_maxdelay produces the expected metadata", {
  obs <- enw_example(type = "observations")
  obs <- enw_add_delay(obs)
  expect_equal(
    enw_metadata_maxdelay(obs = obs, max_delay = 20),
    list(spec = 20, obs = 61, model = 20)
  )
  expect_equal(
    enw_metadata_maxdelay(obs = obs, max_delay = 80),
    list(spec = 80, obs = 61, model = 61)
  )
  expect_equal(
    enw_metadata_maxdelay(obs = obs, max_delay = 61),
    list(spec = 61, obs = 61, model = 61)
  )
})
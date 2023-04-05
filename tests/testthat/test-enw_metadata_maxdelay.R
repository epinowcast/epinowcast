test_that("enw_metadata_maxdelay produces the expected metadata", {
  obs <- enw_example(type = "preprocessed_observations")$obs[[1]]
  expect_equal(
    enw_metadata_maxdelay(obs = obs, max_delay = 10),
    list(spec = 10, obs = 20, model = 10)
  )
  expect_equal(
    enw_metadata_maxdelay(obs = obs, max_delay = 30),
    list(spec = 30, obs = 20, model = 20)
  )
  expect_equal(
    enw_metadata_maxdelay(obs = obs, max_delay = 20),
    list(spec = 20, obs = 20, model = 20)
  )
})

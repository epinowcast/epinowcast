test_that("enw_delay_filter can filter for delays as expected", {
  obs <- enw_example("preprocessed")$obs[[1]]
  expect_equal(max(enw_delay_filter(obs, max_delay = 2)$delay, na.rm = TRUE), 1)
})

test_that("enw_delay_filter throws a warning when the empirical delay is less
           than the max specified", {
  obs <- enw_example("preprocessed")$obs[[1]]
  expect_warning(enw_delay_filter(obs, max_delay = 100))
})
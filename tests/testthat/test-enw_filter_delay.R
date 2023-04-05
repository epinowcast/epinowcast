test_that("enw_filter_delay can filter for delays as expected", {
  obs <- enw_example("preprocessed")$obs[[1]]
  expect_equal(max(enw_filter_delay(obs, max_delay = 2)$delay, na.rm = TRUE), 1)
})

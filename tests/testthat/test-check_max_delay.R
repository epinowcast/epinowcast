test_that("check_max_delay produces the expected warnings", {
  obs <- enw_example(type = "preprocessed_observations")$obs[[1]]
  expect_warning(
    check_max_delay(obs, max_delay = 5),
    regexp = "covers less than 80% of cases for the majority"
  )

  expect_no_warning(
    check_max_delay(obs, max_delay = 5, warn = FALSE)
  )

  expect_warning(
    check_max_delay(obs, max_delay = 8, cum_coverage = 0.9),
    regexp = "covers less than 90% of cases for the majority"
  )

  expect_no_warning(
    check_max_delay(obs, 10)
  )
})

test_that("check_max_delay produces the expected output", {
  obs <- enw_example(type = "preprocessed_observations")$obs[[1]]

  expect_equal(check_max_delay(obs, max_delay = 10), 0.073170732)

  expect_equal(
    check_max_delay(obs, max_delay = 10, cum_coverage = 0.9),
    0.48780488
  )

  expect_equal(check_max_delay(obs, max_delay = 20), 0)

  expect_error(check_max_delay(obs, max_delay = 10, cum_coverage = 80))
})

test_that("enw_flag_observed_observations() works as expected with well-behaved data", {
  obs <- data.frame(id = 1:3, confirm = c(NA, 1, 0))
  exp_obs <- data.table::data.table(
    id = 1:3, confirm = c(NA, 1, 0), .observed = c(FALSE, TRUE, TRUE)
  )
  expect_equal(enw_flag_observed_observations(obs), exp_obs)
})

test_that("enw_flag_observed_observations() works when .observed is already present", {
  obs <- data.frame(
    id = 1:3, confirm = c(NA, 1, 0), .observed = c(TRUE, FALSE, TRUE)
  )
  exp_obs <- data.table::data.table(
    id = 1:3, confirm = c(NA, 1, 0), .observed = c(FALSE, FALSE, TRUE)
  )
  expect_equal(enw_flag_observed_observations(obs), exp_obs)
})

test_that("enw_impute_na_observations() works as expected with NA values", {
  obs <- data.frame(
    id = 1:4,
    confirm = c(NA, 1, NA, 2),
    reference_date = "2021-01-01"
  )
  exp_obs <- data.table::data.table(
    id = 1:4,
    confirm = c(0, 1, 1, 2),
    reference_date = "2021-01-01"
  )
  data.table::setkeyv(exp_obs, c("reference_date"))
  expect_equal(enw_impute_na_observations(obs), exp_obs)
})

test_that("enw_impute_na_observations() throws error when confirm or reference_date is missing", {
  obs <- data.frame(id = 1:3)
  expect_error(enw_impute_na_observations(obs), "The following columns are required:\nconfirm, reference_date\nbut are not present among")
  obs <- data.frame(id = 1:3, confirm = c(NA, 1, 0))
  expect_error(enw_impute_na_observations(obs), "he following columns are required: reference_date")
  obs <- data.frame(id = 1:3, reference_date = "2021-02-01")
  expect_error(enw_impute_na_observations(obs), "The following columns are required: confirm but are not present")
})

test_that("enw_inits produces initial conditions with default example data", {
  # This test depends on the output from enw_as_data_list being unchanged
  stan_data <- enw_example("nowcast")$data[[1]]
  inits <- enw_inits(stan_data)()
  expect_snapshot(names(inits))
  expect_snapshot(purrr::compact(purrr::map(inits, length)))
  expect_snapshot(purrr::compact(purrr::map(inits, dim)))
})

test_that("enw_inits produces initial conditions with optional parameters
           inverted", {
  # This test depends on the output from enw_as_data_list being unchanged
  modified_stan_data <- enw_example("nowcast")$data[[1]]
  modified_stan_data$neffs <- 2
  modified_stan_data$neff_sds <- 1
  modified_stan_data$nrd_effs <- 0
  modified_stan_data$nrd_eff_sds <- 0
  inits <- enw_inits(modified_stan_data)()
  expect_snapshot(names(inits))
  expect_snapshot(purrr::compact(purrr::map(inits, length)))
  expect_snapshot(purrr::compact(purrr::map(inits, dim)))
})
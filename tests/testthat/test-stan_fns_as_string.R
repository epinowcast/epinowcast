test_that("stan_fns_as_string can read in a stan function file as expected", {
  expect_error(
    epinowcast:::stan_fns_as_string(
      "hazard.stan", system.file("stan/functions", package = "epinowcast"),
      NA
    )
  )
})

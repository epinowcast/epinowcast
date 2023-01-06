test_that("stan_fns_as_string can read in a stan function file as expected", {
  skip_on_cran()
  skip_on_local()
  expect_error(
    epinowcast:::stan_fns_as_string(
      "hazard.stan", system.file("stan/functions", package = "epinowcast"),
      NA
    )
  )
})

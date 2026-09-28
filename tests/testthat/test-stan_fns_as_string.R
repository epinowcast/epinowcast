test_that("stan_fns_as_string can read in a stan function file as expected", {
  skip_on_cran()
  code <- stan_fns_as_string(
    "hazard.stan", system.file("stan", "functions", package = "epinowcast")
  )
  expect_true(grepl("prob_to_hazard", code, fixed = TRUE))
})

test_that("stan_fns_as_string errors for too many arguments", {
  skip_on_cran()
  expect_error(
    stan_fns_as_string(
      "hazard.stan", system.file("stan", "functions", package = "epinowcast"),
      NA, NA
    )
  )
})

test_that("stan_fns_as_string substitutes an override for a matching file", {
  skip_on_cran()
  code <- stan_fns_as_string(
    "hazard.stan", system.file("stan", "functions", package = "epinowcast"),
    overrides = c("hazard.stan" = "// replaced content")
  )
  expect_true(grepl("replaced content", code, fixed = TRUE))
  expect_false(grepl("prob_to_hazard", code, fixed = TRUE))
})

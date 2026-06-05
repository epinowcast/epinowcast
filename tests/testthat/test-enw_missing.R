# Use example data
pobs <- enw_example("preprocessed")

test_that("enw_missing produces the expected model components", {
  expect_snapshot({
    miss <- enw_missing(formula = ~ 1 + rw(week), data = pobs)
    miss$inits <- NULL
    miss
  })
  miss <- enw_missing(~ 1 + (1 | day_of_week), data = pobs)
  expect_named(
    miss$inits(miss$data, miss$priors)(),
    c(
      "miss_int", "miss_beta", "miss_beta_sd",
      "miss_arima_pacf", "miss_arima_theta", "miss_arima_sigma",
      "miss_gp_rho", "miss_gp_alpha"
    )
  )
})

test_that("enw_missing fails when insupported options are used", {
  pobs$missing_reference[[1]] <- data.table::data.table()
  expect_error(enw_missing(data = pobs))
})

test_that("enw_missing returns an empty model when required", {
  expect_snapshot({
    miss <- enw_missing(formula = ~0, data = pobs)
    miss$inits <- NULL
    miss
  })
})

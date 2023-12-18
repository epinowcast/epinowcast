test_that("enw_fit_opts produces the expected output", {
  expect_snapshot(enw_fit_opts(sampler = NULL, adapt_delta = 0.9))
  expect_identical(enw_fit_opts(pp = TRUE, nowcast = FALSE)$data$cast, 1)
  expect_identical(
    enw_fit_opts(
      likelihood_aggregation = "groups"
    )$data$likelihood_aggregation, 1
  )
  expect_identical(
    enw_fit_opts(
      likelihood_aggregation = "groups",
      threads_per_chain = 2
    )$data$parallelise_likelihood, 1L
  )
})

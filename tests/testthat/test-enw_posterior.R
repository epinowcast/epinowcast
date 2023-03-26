#' fit <- enw_example("nowcast")
test_that("enw_posterior can extract posterior draws as expected", {
  fit <- enw_example("nowcast")
  expect_snapshot(
   round_numerics(
    enw_posterior(
      fit$fit[[1]], variables = "expr_lelatent_int[1,1]")[1:10][!is.na(variable)][, c("rhat", "ess_bulk", "ess_tail") := NULL][]
    )
  )
})
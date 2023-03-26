test_that("enw_quantiles_to_long can manipulate posterior draws as expected", {
  fit <- enw_example("nowcast")
  posterior <- enw_posterior(fit$fit[[1]], var = "expr_lelatent_int[1,1]")
  expect_snapshot(
    round_numerics(
      enw_quantiles_to_long(posterior)[,
        c("rhat", "ess_bulk", "ess_tail") := NULL][!is.na(variable)][]
    )
  )
})
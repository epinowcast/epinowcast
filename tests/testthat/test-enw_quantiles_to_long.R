test_that("enw_quantiles_to_long can manipulate posterior draws as expected", {
  fit <- enw_example("nowcast")
  posterior <- enw_posterior(fit$fit[[1]], var = "expr_lelatent_int[1,1]")
  expect_snapshot(
    round_numerics(
      enw_quantiles_to_long(posterior)[
        ,
        c("rhat", "ess_bulk", "ess_tail") := NULL
      ][!is.na(variable)][]
    )
  )
})

test_that("enw_quantiles_to_long can receive data.frame", {
  # When a data.table is passed to `melt()`, it calls `data.table::melt`, but if
  # anything else is passed to `melt()`, it calls `reshape2::melt`, which is
  # deprecated
  # See this StackOverflow answer
  # https://stackoverflow.com/q/42141989/4439357
  fit <- enw_example("nowcast")
  smry <- as.data.frame(summary(fit))
  expect_no_error(enw_quantiles_to_long(smry))
})

#' fit <- enw_example("nowcast")
#' enw_pp_summary(fit$fit[[1]], fit$new_confirm[[1]], probs = c(0.5))
#'
test_that("enw_pp_summary summarises posterior prediction as expected", {
  fit <- enw_example("nowcast")
  summary <- enw_pp_summary(fit$fit[[1]], fit$new_confirm[[1]], probs = c(0.5))
  expect_snapshot(
    round_numerics(summary[1:10][, c("rhat", "ess_bulk", "ess_tail") := NULL][])
  )
})

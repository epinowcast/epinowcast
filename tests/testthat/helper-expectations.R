expect_data_table <- function(dt) {
  expect_s3_class(dt, "data.table")
}

expect_dates_unique <- function(dt) {
  expect_identical(nrow(dt[, .(n = .N), by = c("date")][n > 1]), 0L)
}

expect_ggplot <- function(p) {
  expect_s3_class(p, "ggplot")
}

expect_diff_abs_lt_per <- function(x, y, diff, tol = 0.1) {
  for (i in seq_along(x)) {
    actual_diff <- abs(x[i] - y[i])
    if (actual_diff > tol) {
      expect_lt(
        actual_diff / abs(y[i]), diff
      )
    }
  }
}

expect_diff_sum_abs_lt <- function(x, y, diff) {
  expect_lt(sum(abs(x - y)), diff)
}

expect_zero_length_or_not <- function(vars, vars_list) {
  purrr::walk(vars_list[vars], \(x)(expect_length(x, 0)))
  purrr::walk(
    vars_list[!names(vars_list) %in% vars], \(x)(expect_true(length(x) > 0))
  )
}

expect_convergence <- function(
    nowcast, per_dts = 0.05, treedepth = 10, rhat = 1.05) {
  expect_identical(class(nowcast$fit[[1]])[1], "CmdStanMCMC")
  expect_lt(nowcast$per_divergent_transitions, per_dts)
  expect_lt(nowcast$max_treedepth, treedepth)
  expect_lt(nowcast$max_rhat, rhat)
}

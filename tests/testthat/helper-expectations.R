expect_data_table <- function(dt) {
  expect_s3_class(dt, "data.table")
}

expect_dates_unique <- function(dt) {
  expect_equal(nrow(dt[, .(n = .N), by = c("date")][n > 1]), 0)
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

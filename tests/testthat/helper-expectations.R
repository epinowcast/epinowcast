expect_data_table <- function(dt) {
  expect_s3_class(dt, "data.table")
}

expect_dates_unique <- function(dt) {
  expect_equal(nrow(dt[, .(n = .N), by = c("date")][n > 1]), 0)
}

expect_ggplot <- function(p) {
  expect_s3_class(p, "ggplot")
}

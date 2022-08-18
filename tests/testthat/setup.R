if (not_on_cran() & FALSE) {
  message("Running tests setup")
  options(mc.cores = 2)
  utils::capture.output(
    source(enw_example("script"))
  )
}

# Toy example data
toy_incidence <- data.table::data.table(
  reference_date = data.table::as.IDate("2021-10-01"),
  report_date = seq(
    data.table::as.IDate("2021-10-01"),
    length.out = 10, by = 1
  ),
  new_confirm = c(1, 2, 3, 4, -2, 5, 5, 6, 7, 9)
)
data.table::setkeyv(toy_incidence, c("reference_date", "report_date"))

toy_cumulative <- data.table::copy(toy_incidence)
toy_cumulative <- toy_cumulative[, confirm := cumsum(new_confirm)]
toy_cumulative <- toy_cumulative[sample(.N, .N)][, new_confirm := NULL]

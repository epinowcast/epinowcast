# Set data.table print options for compatibility
options(datatable.print.class = FALSE)
options(datatable.print.keys = FALSE)

# Set cache for testing
enw_set_cache(tempdir(), type = "session")

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

if (on_ci() && Sys.info()["sysname"] == "Linux" && not_on_cran()) {
  # we only expose stan functions on linux CI
  # because we only test these functions on linux
  suppressMessages(suppressWarnings(enw_stan_to_r()))
}

# Mock weekly data (currently used to test subset_obs() and
# build_ord_obs())
obs_weekly <- data.table(
    reference_date = as.IDate("2021-07-28") + 7 * (0:6),
    report_date = c(as.IDate("2021-08-25") + 7 * (0:2),
                    rep(as.IDate("2021-09-08"), 4)),
    .group = rep(1, times = 7),
    max_confirm = c(625, 856, 1073, 1733, 2268, 2388, 1487),
    confirm = c(615, 847, 1073, 1733, 2268, 2388, 1487),
    cum_prop_reported = c(615 / 625, 847 / 856, rep(1, 5)),
    delay = c(rep(4, 3), 3:0)
)
# Load packages
library(epinowcast)
library(data.table)

# Set cmdstan path
cmdstanr::set_cmdstan_path()

# Use 2 cores
options(mc.cores = 2)

# Load and filter germany hospitalisations
nat_germany_hosp <- germany_covid19_hosp[location == "DE"] |>
  _[age_group == "00+"] |>
  _[, age_group := NULL] |>
  _[, location := NULL]

nat_germany_hosp <- enw_filter_report_dates(
  nat_germany_hosp,
  latest_date = "2021-10-01"
)

nat_germany_hosp <- enw_filter_reference_dates(
  nat_germany_hosp,
  earliest_date = "2021-07-01"
)

nat_germany_hosp <- enw_complete_dates(
  nat_germany_hosp, timestep = "day"
)

enw_flag_report_day <- function(data) {
  data[, .report_day := ifelse(is.na(confirm), 0, 1)]
  return(data)
}

# Aggregate data to weekly reporting cycle
repcycle_germany_hosp <- nat_germany_hosp |>
  _[, day_of_week := weekdays(report_date)] |>
  epinowcast:::aggregate_rolling_sum(
    internal_timestep = 7,
    by = "reference_date",
    value_col = "confirm"
  ) |>
  _[, confirm := fifelse(day_of_week == "Wednesday", confirm, NA_real_)] |>
  enw_flag_report_day() |>
  enw_flag_observed_observations() |>
  enw_impute_na_observations() |>
  enw_add_incidence()

# Make sure observations are complete (we don't need to do this here as we have
# already done this above but for completeness we include it (as it would be
# needed for real data)) 
repcycle_germany_hosp <- enw_complete_dates(
  repcycle_germany_hosp, timestep = "day"
)

# Make a retrospective real-time dataset
rt_nat_germany <- enw_filter_report_dates(
  repcycle_germany_hosp,
  remove_days = 20
)
rt_nat_germany <- enw_filter_reference_dates(
  rt_nat_germany,
  include_days = 90
)

# Get latest observations for the same time period
latest_obs <- enw_latest_data(repcycle_germany_hosp)
latest_obs <- enw_filter_reference_dates(
  latest_obs,
  remove_days = 20, include_days = 90
)

# I think we need to skip data that is not on a reported day in the likelihood
# otherwise we are not identifying the reporting delay properly.

# Preprocess observations (note this maximum delay is likely too short)
pobs <- enw_preprocess_data(rt_nat_germany, max_delay = 35, timestep = "day")

# Create structual reporting data
metadata <- pobs$metareference[[1]] |>
  _[, key := 1] |>
  _[, .(key, .group, date)] |>
  _[pobs$metadelay[[1]][, key := 1], on = "key", allow.cartesian = TRUE] |>
  _[, .(.group, date, report_date = date + delay)] |>
  setorder(.group, date, report_date) |>
  _[, day_of_week := weekdays(report_date)] |>
  _[, report := ifelse(day_of_week == "Wednesday", 1, 0)] |>
  _[, cum_report := cumsum(report) + 1, by = .(.group, date)] |>
  _[day_of_week == "Wednesday", cum_report := cum_report - 1]

# You can view the matrix like this:
# print(agg_matrix)

# If you want to see it in a more readable format:
# library(knitr)
# kable(agg_matrix)

# Define the structural argument for probability aggregation
# We are assigning one 35x35 matrix to each reference day, depending on the DOW
# Report day is Wednesday, and as coded above everything up to & including Wednesday
# is reported on Wednesday.
# Scratch in a function to make the agg_indicator for each wday
generate_agg_indicator <- function(reference_dow_idx, reporting_dow_idx, max_delay) {
  # Indices are as from lubridate::wday
  d <- ifelse(reference_dow_idx < reporting_dow_idx,
              reporting_dow_idx - reference_dow_idx,
              7 - (reference_dow_idx - reporting_dow_idx))
  row_idxs <- d + seq(1, max_delay, by = 7)
  row_idxs <- col_breaks <- row_idxs[row_idxs <= max_delay]
  col_idxs <- lapply(col_breaks, function(idx){
    return(max(idx - 6, 1):idx)
  })
  agg_matrix <- matrix(0, nrow = max_delay, ncol = max_delay)
  # Replace desired elements with 1
  for (i in seq_along(col_idxs)) {
    agg_matrix[row_idxs[i], col_idxs[[i]]] <- 1
  }
  return(agg_matrix)
}
ref_day_matrix_list <- lapply(1:7, FUN = function(day) { 
  generate_agg_indicator(day, 4, 35)
})
# Then get array of these matrices
ref_t_wdays <- wday(pobs$metareference[[1]]$date)
agg_indicators <- lapply(seq_along(ref_t), function(t) {
  ref_day_matrix_list[[ref_t_wdays[t]]]
})
agg_indicators <- array(unlist(agg_indicators), dim = c(35, 35, length(ref_t)))
agg_indicators <- aperm(agg_indicators, c(3, 1, 2))

# Fit a simple nowcasting model with fixed growth rate and a
# log-normal reporting distribution.
# Add probability aggregation to "structural" argument to handle the fixed reporting cycle.
nowcast <- epinowcast(pobs,
  expectation = enw_expectation(~1, data = pobs),
  report = enw_report(structural = agg_indicators, data = pobs),
  fit = enw_fit_opts(
    init_method = "sample",
    save_warmup = FALSE, pp = TRUE,
    chains = 2, iter_warmup = 500, iter_sampling = 500,
  ),
  obs = enw_obs(family = "negbin",
    observation_indicator = ".observed",
    data = pobs),
)

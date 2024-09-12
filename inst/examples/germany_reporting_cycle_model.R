# Load packages
library(epinowcast)
library(data.table)

# Set cmdstan path
cmdstanr::set_cmdstan_path()

# Use 2 cores
options(mc.cores = 2)

# Load and filter germany hospitalisations
nat_germany_hosp <- germany_covid19_hosp[location == "DE"][age_group == "00+"]
nat_germany_hosp <- enw_filter_report_dates(
  nat_germany_hosp,
  latest_date = "2021-10-01"
)

nat_germany_hosp <- enw_filter_reference_dates(
  nat_germany_hosp,
  earliest_date = "2021-07-01"
)

nat_germany_hosp <- enw_complete_dates(
  nat_germany_hosp,
  by = c("location", "age_group"),
  timestep = "day"
)

# Aggregate data to weekly reporting cycle
repcycle_germany_hosp <- nat_germany_hosp |>
  enw_add_incidence() |>
  dplyr::mutate(day_of_week = lubridate::wday(report_date, label = TRUE)) |>
  dplyr::mutate(confirm = new_confirm) |>
  # Aggregate rolling sum sums over "confirm"
  # but we want a sum over "new_confirm"
  epinowcast:::aggregate_rolling_sum(
    internal_timestep = 7,
    by = "reference_date"
  ) |>
  dplyr::mutate(confirm = ifelse(day_of_week == "Wed",
                          confirm,
                          0)) |>
  dplyr::mutate(not_report_day = ifelse(day_of_week != "Wed",
                                 1,
                                 0)) |>
  dplyr::mutate(.observed = ifelse(day_of_week == "Wed",
                                 TRUE,
                                 FALSE)) |>
  # Get confirm as cumulative again
  enw_add_cumulative()

# Make sure observations are complete (we don't need to do this here as we have
# already done this above but for completeness we include it (as it would be
# needed for real data)) 
repcycle_germany_hosp <- enw_complete_dates(
  repcycle_germany_hosp,
  by = c("location", "age_group"),
  timestep = "day"
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

# Preprocess observations (note this maximum delay is likely too short)
pobs <- enw_preprocess_data(rt_nat_germany, max_delay = 35, timestep = "day")

# Define the structural argument for probability aggregation
ref_t <- unique(pobs$obs[[1]]$reference_date)
ref_t <- ref_t[!is.na(ref_t)]
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
ref_t_wdays <- lubridate::wday(ref_t)
agg_indicators <- array(dim = c(1, length(ref_t), 35, 35))
for (t in seq_along(ref_t)) {
  agg_indicators[1, t, , ] <- ref_day_matrix_list[[ref_t_wdays[t]]]
}

# Fit a simple nowcasting model with fixed growth rate and a
# log-normal reporting distribution.
# Add probability aggregation to "structural" argument to handle the fixed reporting cycle.
nowcast <- epinowcast(pobs,
  expectation = enw_expectation(~1, data = pobs),
  report = enw_report(structural = agg_indicators, data = pobs),
  fit = enw_fit_opts(
    save_warmup = FALSE, pp = TRUE,
    chains = 2, iter_warmup = 500, iter_sampling = 500,
  ),
  obs = enw_obs(family = "negbin",
    observation_indicator = ".observed",
    data = pobs),
)

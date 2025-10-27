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
  enw_rolling_sum(
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

# I think we need to skip data that is not on a reported day in the likelihood
# otherwise we are not identifying the reporting delay properly.

max_delay <- 30

# Get latest observations for the nowcast period (max_delay days)
latest_obs <- repcycle_germany_hosp |>
  enw_filter_delay(max_delay = max_delay) |>
  enw_latest_data() |>
  enw_filter_reference_dates(
    remove_days = 20, include_days = max_delay
  )

# Preprocess observations
pobs <- enw_preprocess_data(
  rt_nat_germany, max_delay = max_delay, timestep = "day"
)

# Create structural reporting data for Wednesday reporting
structural <- enw_dayofweek_structural_reporting(pobs, day_of_week = "Wednesday")

# Fit a simple nowcasting model
# Add probability aggregation to "structural" argument to handle the fixed reporting cycle.
nowcast <- epinowcast(
  pobs,
  expectation = enw_expectation(~ rw(week) + (1 | day_of_week), data = pobs),
  report = enw_report(structural = structural, data = pobs),
  fit = enw_fit_opts(
    init_method = "prior",
    save_warmup = FALSE,
    pp = TRUE,
    chains = 2,
    iter_warmup = 250,
    iter_sampling = 500,
    max_treedepth = 12
  ),
  obs = enw_obs(
    family = "negbin",
    observation_indicator = ".observed",
    data = pobs
  ),
)

plot(nowcast, latest_obs = latest_obs)

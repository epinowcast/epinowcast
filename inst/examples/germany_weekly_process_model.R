# Load packages
library(epinowcast)
library(data.table)

# Set cmdstan path
cmdstanr::set_cmdstan_path()

# Use 2 cores
options(mc.cores = 2)

# Load and filter germany hospitalisations
nat_germany_hosp <- germany_covid19_hosp[location == "DE"][age_group %in% "00+"]
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

# Aggregate data to be weekly both by report and reference date
weekly_germany_hosp <- nat_germany_hosp |> 
  enw_aggregate_cumulative(timestep = "week")

# Make sure observations are complete (we don't need to do this here as we have
# already done this above but for completeness we include it (as it would be
# needed for real data)) 
weekly_germany_hosp <- enw_complete_dates(
  weekly_germany_hosp,
  by = c("location", "age_group"),
  timestep = "week"
)

# Make a retrospective real-time dataset
rt_nat_germany <- enw_filter_report_dates(
  weekly_germany_hosp,
  remove_days = 20
)
rt_nat_germany <- enw_filter_reference_dates(
  rt_nat_germany,
  include_days = 90
)

# Get latest observations for the same time period
latest_obs <- enw_latest_data(weekly_germany_hosp)
latest_obs <- enw_filter_reference_dates(
  latest_obs,
  remove_days = 20, include_days = 90
)

# Preprocess observations (note this maximum delay is likely too short)
pobs <- enw_preprocess_data(rt_nat_germany, max_delay = 5, timestep = "week")

# Fit a simple nowcasting model with fixed growth rate and a
# log-normal reporting distribution.
nowcast <- epinowcast(pobs,
  expectation = enw_expectation(~1, data = pobs),
  fit = enw_fit_opts(
    save_warmup = FALSE, pp = TRUE,
    chains = 2, iter_warmup = 500, iter_sampling = 500,
  ),
  obs = enw_obs(family = "negbin", data = pobs),
)

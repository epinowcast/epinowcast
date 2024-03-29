# Load packages
library(epinowcast)
library(data.table)

# Use 2 cores
options(mc.cores = 2)

# Load and filter germany hospitalisations
nat_germany_hosp <- germany_covid19_hosp[location == "DE"][age_group == "00+"]
nat_germany_hosp <- enw_filter_report_dates(
  nat_germany_hosp,
  latest_date = "2021-09-01"
)

# Make sure observations are complete
nat_germany_hosp <- enw_complete_dates(
  nat_germany_hosp,
  by = c("location", "age_group"),
  missing_reference = FALSE
)

# Set proportion missing at 20%
prop_miss <- 0.2

# Simulate using this function
nat_germany_hosp <- enw_simulate_missing_reference(
  nat_germany_hosp,
  proportion = prop_miss, by = c("location", "age_group")
)

# Make a retrospective dataset
retro_nat_germany <- enw_filter_report_dates(
  nat_germany_hosp,
  remove_days = 40
)
retro_nat_germany <- enw_filter_reference_dates(
  retro_nat_germany,
  include_days = 60
)

# Get latest observations for the same time period
latest_obs <- enw_latest_data(nat_germany_hosp)
latest_obs <- enw_filter_reference_dates(
  latest_obs,
  remove_days = 40, include_days = 60
)

# Preprocess observations (note this maximum delay is likely too short)
pobs <- enw_preprocess_data(retro_nat_germany, max_delay = 20)

# Compile the model for use outside of the benchmark
model <- enw_model(target_dir = "touchstone")

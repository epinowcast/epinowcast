# Run preprocessing script
# Load packages
library(epinowcast)
library(data.table)

# Set cmdstan path
cmdstanr::set_cmdstan_path()

# Use 2 cores
options(mc.cores = 2)

# Load and filter germany hospitalisations
nat_germany_hosp <-
  germany_covid19_hosp[location == "DE"][
    age_group %in% c("00+", "00-04", "80+")
  ]
nat_germany_hosp <- enw_filter_report_dates(
  nat_germany_hosp,
  latest_date = "2021-10-01"
)
# Make sure observations are complete
nat_germany_hosp <- enw_complete_dates(
  nat_germany_hosp,
  by = c("location", "age_group")
)
# Make a retrospective dataset
retro_nat_germany <- enw_filter_report_dates(
  nat_germany_hosp,
  remove_days = 40
)
retro_nat_germany <- enw_filter_reference_dates(
  retro_nat_germany,
  include_days = 10
)
# Preprocess observations (note this maximum delay is likely too short)
pobs <- enw_preprocess_data(
  retro_nat_germany, by = "age_group", max_delay = 10
)

# Compile the model for use outside of the benchmark
model <- enw_model(target_dir = "touchstone")

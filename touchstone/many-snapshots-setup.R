# Run preprocessing script
# Load packages
library(epinowcast)
library(data.table)

# Set cmdstan path
cmdstanr::set_cmdstan_path()

# Use 2 cores
options(mc.cores = 2)

# Load and filter germany hospitalisations, keeping only the true age
# strata (excluding the "00+" national total, which double counts the
# other six groups) so each group contributes its own snapshot series.
nat_germany_hosp <-
  germany_covid19_hosp[location == "DE"][age_group != "00+"]

nat_germany_hosp <- enw_filter_report_dates(
  nat_germany_hosp,
  latest_date = "2021-10-01"
)
# Make sure observations are complete
nat_germany_hosp <- enw_complete_dates(
  nat_germany_hosp,
  by = c("location", "age_group")
)
# Make a retrospective dataset with a long reference-date window. Six age
# groups x 60 reference dates gives ~360 snapshots (`s`), around 9x the
# ~40 snapshots of the single-group default touchstone cells, so the
# per-snapshot hazard loop (`expected_obs_from_index()` /
# `combine_logit_hazards()`) dominates total cost rather than being a
# small fraction of it.
retro_nat_germany <- enw_filter_report_dates(
  nat_germany_hosp,
  remove_days = 40
)
retro_nat_germany <- enw_filter_reference_dates(
  retro_nat_germany,
  include_days = 60
)

# Preprocess observations (max_delay matches the other touchstone cells)
pobs <- enw_preprocess_data(
  retro_nat_germany,
  by = "age_group", max_delay = 20
)

# Compile the model for use outside of the benchmark
model <- enw_model(target_dir = "touchstone")

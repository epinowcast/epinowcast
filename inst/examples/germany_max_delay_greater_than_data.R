# Load packages
library(epinowcast)
library(data.table)

# Set cmdstan path
cmdstanr::set_cmdstan_path()
#> CmdStan path set to: /home/seabbs/.cmdstan/cmdstan-2.33.1

# Use 2 cores
options(mc.cores = 2)

# Load and filter germany hospitalisations
nat_germany_hosp <- germany_covid19_hosp[location == "DE"][age_group %in% "00+"]
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
  include_days = 20
)

# Get latest observations for the same time period
latest_obs <- enw_latest_data(nat_germany_hosp)
latest_obs <- enw_filter_reference_dates(
  latest_obs,
  remove_days = 40, include_days = 30
)

# Preprocess observations (note this maximum delay is likely too short)
pobs <- enw_preprocess_data(retro_nat_germany, max_delay = 30)

# Expectation model
expectation_module <- enw_expectation(
  r = ~ rw(week), observation = ~ (1 | day_of_week), data = pobs
)

# Reference date model
reference_module <- enw_reference(
  parametric = ~ 1, data = pobs
)

# Report date model
report_module <- enw_report(~ (1 | day_of_week), data = pobs)

# Observation model
obs_module <- enw_obs(family = "negbin", data = pobs)

# Fit a simple nowcasting model with fixed growth rate and a
# log-normal reporting distribution.
nowcast <- epinowcast(pobs,
  expectation = expectation_module,
  reference = reference_module,
  report = report_module,
  fit = enw_fit_opts(
    save_warmup = FALSE, pp = TRUE,
    chains = 2, iter_warmup = 1000, iter_sampling = 1000,
    adapt_delta = 0.99
  ),
  obs = obs_module,
)

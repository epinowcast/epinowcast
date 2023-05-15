# Load data.table and ggplot2
library(data.table)

# Use 2 cores
options(mc.cores = 2)
# Load and filter germany hospitalisations
nat_germany_hosp <-
  germany_covid19_hosp[location == "DE"][age_group %in% c("00+", "80+")]
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
  include_days = 40
)
# Get latest observations for the same time period
latest_obs <- enw_latest_data(nat_germany_hosp)
latest_obs <- enw_filter_reference_dates(
  latest_obs,
  remove_days = 40, include_days = 20
)
# Preprocess observations (note this maximum delay is likely too short)
pobs <- enw_preprocess_data(retro_nat_germany, by = "age_group", max_delay = 20)

# set reference time indexed reporting process model
reference_module <- enw_reference(
  ~ 1 + (1 | .group), distribution = "lognormal", data = pobs
)

# set reporting time indexed reporting process model
report_module <- enw_report(~ 1 + (1 | .group), data = pobs)

# set expectation module
expectation_module <- enw_expectation(~rw(day, by = .group),  data = pobs)

# Fit the nowcast model and produce a nowcast
# Note that we have reduced samples for this example to reduce runtimes
nowcast <- epinowcast(pobs,
                      reference = reference_module,
                      report = report_module,
                      expectation = expectation_module,
                      fit = enw_fit_opts(
                        save_warmup = FALSE, pp = TRUE,
                        chains = 2, iter_warmup = 500, iter_sampling = 500
                      )
)
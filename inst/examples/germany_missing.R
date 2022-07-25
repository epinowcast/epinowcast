# Load packages
library(epinowcast)
library(data.table)
library(ggplot2)

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
  by = c("location", "age_group"),
  missing_reference = FALSE
)

# Prototypes for simulating missing data - likely to be implemented in 0.2.0
enw_incidence_to_cumulative <- function(obs, by = c()) {
  obs <- data.table::as.data.table(obs)
  obs <- check_dates(obs)

  obs <- obs[!is.na(reference_date)]
  obs[order(reference_date, report_date)]

  obs[, confirm := cumsum(new_confirm), by = c(by, "reference_date")]
  return(obs[])
}

enw_simulate_missing_reference <- function(obs, proportion = 0.4, by = c()) {
  obs <- data.table::as.data.table(obs)
  obs <- check_dates(obs)
  obs <- enw_assign_group(obs, by = by)
  by_with_group_id <- c(".group", by)
  obs <- enw_new_reports(obs)

  obs[, missing := floor(new_confirm * proportion)]
  obs[, new_confirm := new_confirm - missing]

  complete_ref <- enw_incidence_to_cumulative(obs, by = by)
  complete_ref[, c("new_confirm", ".group", "delay", "missing") := NULL]

  missing_ref <- obs[, .(confirm = sum(missing)),
    by = c(by, "report_date")
  ]
  missing_ref[, reference_date := as.IDate(NA)]

  obs <- rbind(complete_ref, missing_ref, use.names = TRUE)
  obs[order(reference_date, report_date)]
  return(obs[])
}

nat_germany_hosp <- enw_simulate_missing_reference(
  nat_germany_hosp,
  proportion = 0.4, by = c("location", "age_group")
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
pobs <- enw_preprocess_data(retro_nat_germany, max_delay = 20)

# Fit the default nowcast model and produce a nowcast
# Note that we have reduced samples for this example to reduce runtimes
nowcast <- epinowcast(pobs,
  missing = enw_missing(~1, data = pobs),
  fit = enw_fit_opts(
    save_warmup = FALSE, pp = TRUE,
    chains = 2, iter_warmup = 500, iter_sampling = 500
  ),
  obs = enw_obs(family = "poisson", data = pobs)
)

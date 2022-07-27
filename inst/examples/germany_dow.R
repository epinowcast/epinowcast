# Load epinowcast and data.table
library(epinowcast)
library(data.table)

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
  include_days = 40
)

# Get latest observations for the same time period
latest_obs <- enw_latest_data(nat_germany_hosp)
latest_obs <- enw_filter_reference_dates(
  latest_obs,
  remove_days = 40, include_days = 20
)

# Preprocess observations
pobs <- enw_preprocess_data(retro_nat_germany, max_delay = 20)

# Reference date model
reference_module <- enw_reference(~1, data = pobs)

# Report date model
report_module <- enw_report(~ (1 | day_of_week), data = pobs)

# Compile nowcasting model
model <- enw_model(threads = TRUE)

# Fit nowcast model and produce a nowcast
# Note that we have reduced samples for this example to reduce runtimes
nowcast <- epinowcast(pobs,
  reference = reference_module,
  report = report_module,
  fit = enw_fit_opts(
    save_warmup = FALSE, pp = TRUE,
    chains = 2, threads_per_chain = 1,
    iter_warmup = 500, iter_sampling = 500
  ),
  model = model,
)

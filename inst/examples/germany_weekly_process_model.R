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
  earliest_date = "2021-08-01"
)

# Aggregate data to be weekly both by report and reference date
weekly_germany_hosp <- nat_germany_hosp[report_date >= min(reference_date) + 7]
weekly_germany_hosp <- weekly_germany_hosp[, rep_dow := wday(report_date)]

weekly_germany_hosp <- weekly_germany_hosp[rep_dow == rep_dow[1]]

setorder(weekly_germany_hosp, reference_date, report_date)

weekly_germany_hosp <- weekly_germany_hosp[,
  `:=`(confirm = frollsum(confirm, c(1:6, rep(7, .N - 6)), adaptive = TRUE)),
  by = c("report_date")
]

weekly_germany_hosp <- weekly_germany_hosp[, ref_dow := wday(reference_date)]
weekly_germany_hosp <- weekly_germany_hosp[ref_dow == rep_dow[1]]
weekly_germany_hosp <- weekly_germany_hosp[reference_date >= min(report_date)]

weekly_germany_hosp[]

# Make sure observations are complete
weekly_germany_hosp <- enw_complete_dates(
  weekly_germany_hosp,
  by = c("location", "age_group"),
  timestep = "week"
)
# Make a retrospective real-time dataset
rt_nat_germany <- enw_filter_report_dates(
  weekly_germany_hosp,
  remove_days = 40
)
rt_nat_germany <- enw_filter_reference_dates(
  rt_nat_germany,
  include_days = 40
)

# Get latest observations for the same time period
latest_obs <- enw_latest_data(weekly_germany_hosp)
latest_obs <- enw_filter_reference_dates(
  latest_obs,
  remove_days = 40, include_days = 20
)

# Preprocess observations (note this maximum delay is likely too short)
pobs <- enw_preprocess_data(rt_nat_germany, max_delay = 5)

# Fit a simple nowcasting model with fixed growth rate and a
# log-normal reporting distribution.
nowcast <- epinowcast(pobs,
  expectation = enw_expectation(~1, data = pobs),
  fit = enw_fit_opts(
    save_warmup = FALSE, pp = TRUE,
    chains = 2, iter_warmup = 500, iter_sampling = 500,
  ),
  obs = enw_obs(family = "poisson", data = pobs),
)

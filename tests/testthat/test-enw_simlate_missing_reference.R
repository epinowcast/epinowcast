# Load and filter germany hospitalisations
germany_hosp <- enw_filter_report_dates(
  germany_covid19_hosp,
  latest_date = "2021-08-01"
)

germany_hosp <- enw_filter_reference_dates(
  germany_hosp,
  include_days = 10
)

# Make sure observations are complete
germany_hosp <- enw_complete_dates(
  germany_hosp,
  by = c("location", "age_group"), missing_reference = FALSE
)

# Simulate
enw_simulate_missing_reference(
  germany_hosp,
  proportion = 0.35, by = c("location", "age_group")
)


# Load epinowcast and data.table
library(epinowcast)
library(data.table)

# Load and filter germany hospitalisations
nat_germany_hosp <- germany_covid19_hosp[location == "DE"][age_group %in% "00+"]
nat_germany_hosp <- nat_germany_hosp[report_date <= as.Date("2021-10-01")]

# Make a retrospective dataset
retro_nat_germany <- enw_retrospective_data(
  nat_germany_hosp,
  rep_days = 40, ref_days = 40
)

# Get latest observations for the same time period
latest_obs <- enw_latest_data(nat_germany_hosp, ref_window = c(80, 40))

# Preprocess observations
pobs <- enw_preprocess_data(retro_nat_germany, max_delay = 20)

# Reference date model
reference_effects <- enw_formula(pobs$metareference[[1]])

# Report date model
report_effects <- enw_formula(pobs$metareport[[1]], random = "day_of_week")

# Compile nowcasting model
model <- enw_model(threads = TRUE)

# Fit nowcast model and produce a nowcast
# Note that we have reduced samples for this example to reduce runtimes
options(mc.cores = 2)
nowcast <- epinowcast(pobs,
  model = model,
  report_effects = report_effects,
  reference_effects = reference_effects,
  save_warmup = FALSE, pp = TRUE,
  chains = 2, threads_per_chain = 2,
  iter_warmup = 500, iter_sampling = 500
)

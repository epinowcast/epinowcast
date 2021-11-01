library(data.table)

germany_hosp <- fread(
  "https://raw.githubusercontent.com/jbracher/hospitalization-nowcast-hub/main/data-truth/COVID-19/COVID-19_hospitalizations_preprocessed.csv" # nolint
)
germany_hosp <- melt(
  germany_hosp,
  variable.name = "delay",
  value.name = "confirm",
  id.vars = c("date", "location", "age_group")
)
setnames(germany_hosp, "date", "reference_date")

germany_hosp[, report_date := as.Date(reference_date) + 0:(.N - 1),
  by = c("reference_date", "location", "age_group")
]
germany_hosp <- germany_hosp[report_date <= max(reference_date)]
germany_hosp[, delay := NULL]
germany_hosp[is.na(confirm), confirm := 0]
germany_hosp[, confirm := cumsum(confirm),
  by = c("reference_date", "location", "age_group")
]
cols <- c("age_group", "location")
germany_hosp <- germany_hosp[, (cols) := lapply(.SD, factor), .SDcols = cols]
# save all observations
germany_covid19_hosp <- germany_hosp
usethis::use_data(germany_covid19_hosp, overwrite = TRUE)

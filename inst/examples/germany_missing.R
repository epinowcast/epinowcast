# Load packages
library(epinowcast)
library(data.table)
library(purrr)
library(ggplot2)

# Use 4 cores
options(mc.cores = 4)

# Load and filter germany hospitalisations
nat_germany_hosp <- germany_covid19_hosp[location == "DE"][age_group %in% "00+"]
nat_germany_hosp <- enw_filter_report_dates(
  nat_germany_hosp,
  latest_date = "2021-08-01"
)

# Make sure observations are complete
nat_germany_hosp <- enw_complete_dates(
  nat_germany_hosp,
  by = c("location", "age_group"),
  missing_reference = FALSE
)

# Set proportion missing at 35%
prop_miss <- 0.15

# Prototypes for simulating missing data - likely to be implemented in 0.2.0
enw_simulate_missing_reference <- function(obs, proportion = 0.2, by = c()) {
  obs <- check_dates(obs)
  obs <- enw_cumulative_to_incidence(obs, by = by)

  obs[, missing := purrr::map2_dbl(
    new_confirm, proportion, ~ rbinom(1, .x, .y)
  )]
  obs[, new_confirm := new_confirm - missing]

  complete_ref <- enw_incidence_to_cumulative(obs, by = by)
  complete_ref[, c("new_confirm", "delay", "missing") := NULL]

  missing_ref <- obs[, .(confirm = sum(missing)),
    by = c(by, "report_date")
  ]
  missing_ref[, reference_date := as.IDate(NA)]

  obs <- rbind(complete_ref, missing_ref, use.names = TRUE)
  obs[order(reference_date, report_date)]
  return(obs[])
}

# Simulate using this function
nat_germany_hosp <- enw_simulate_missing_reference(
  nat_germany_hosp,
  proportion = prop_miss, by = c("location", "age_group")
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

# Compile nowcasting model without multi-threading as only using a single
# group and the missing reference only supports multi-threading across groups
model <- enw_model(threads = FALSE)

# Fit the nowcast model with support for observations with missing reference
# dates and produce a nowcast
# Note that we have reduced samples for this example to reduce runtimes
nowcast <- epinowcast(pobs,
  missing = enw_missing(~1, data = pobs),
  report = enw_report(~ (1 | day_of_week), data = pobs),
  fit = enw_fit_opts(
    save_warmup = FALSE, pp = TRUE,
    chains = 4, iter_warmup = 500, iter_sampling = 500,
    likelihood_aggregation = "groups", adapt_delta = 0.9
  ),
  obs = enw_obs(family = "negbin", data = pobs),
  model = model
)

# Plot nowcast of observed values
plot(nowcast, latest_obs)

# Check posterior predictions for missing reference date proportions
miss_prop <- enw_posterior(nowcast$fit[[1]], variables = "miss_ref_lprop")
cols <- c("mean", "median", "q5", "q20", "q80", "q95")
miss_prop[, (cols) := lapply(.SD, exp), .SDcols = cols]
miss_prop <- cbind(
  pobs$latest[[1]][, .(reference_date, confirm = NA)], miss_prop
)

ggplot(miss_prop) +
  aes(x = reference_date) +
  geom_line(aes(y = median), size = 1, alpha = 0.6) +
  geom_hline(yintercept = prop_miss, linetype = 2) +
  geom_ribbon(aes(ymin = q5, ymax = q95), alpha = 0.2, size = 0.2) +
  geom_ribbon(aes(ymin = q20, ymax = q80, col = NULL), alpha = 0.2) +
  theme_bw() +
  scale_y_continuous(labels = scales::percent, limits = c(0, 1)) +
  labs(
    x = "Reference date",
    y = "Proportion of cases reported with a reference date"
  )

# Plot observed and estimated missing data by report
pp_miss_obs <- enw_posterior(nowcast$fit[[1]], variables = "pp_miss_ref")

miss_obs <- pobs$missing_reference[[1]]
miss_obs <- cbind(
  miss_obs[(nrow(miss_obs) - nrow(pp_miss_obs) + 1):nrow(miss_obs)],
  pp_miss_obs
)

enw_plot_quantiles(miss_obs, x = report_date) +
  labs(x = "Report date", y = "Notificatiosn with a missing reference date")

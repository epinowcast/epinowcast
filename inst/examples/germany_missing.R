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
  latest_date = "2021-09-01"
)

# Make sure observations are complete
nat_germany_hosp <- enw_complete_dates(
  nat_germany_hosp,
  by = c("location", "age_group"),
  missing_reference = FALSE
)

# Set proportion missing at 20%
prop_miss <- 0.2
max_delay <- 20

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
  include_days = 60
)

# Get latest observations for the same time period
latest_obs <- enw_latest_data(nat_germany_hosp)
latest_obs <- enw_filter_reference_dates(
  latest_obs,
  remove_days = 40, include_days = 60
)

# Preprocess observations (note this maximum delay is likely too short)
pobs <- enw_preprocess_data(retro_nat_germany, max_delay = max_delay)
obs <- enw_obs(family = "poisson", data = pobs)

# Compile nowcasting model without multi-threading as only using a single
# group and the missing reference only supports multi-threading across groups
model <- enw_model(threads = FALSE)

if (!exists("nowcast")) nowcast <- list()

# Fit the nowcast model with support for observations with missing reference
# dates and produce a nowcast
# Note that we have reduced samples for this example to reduce runtimes
nowcast[["variable"]] <- epinowcast(pobs,
  missing = enw_missing(~ (1 | week), data = pobs),
  report = enw_report(~ (1 | day_of_week), data = pobs),
  fit = enw_fit_opts(
    save_warmup = FALSE, pp = TRUE,
    chains = 4, iter_warmup = 500, iter_sampling = 500,
    likelihood_aggregation = "groups", adapt_delta = 0.9
  ),
  obs = obs,
  model = model
)

# fixed
model_text <- readLines(here::here("inst", "stan", "epinowcast.stan"))
model_text <- sub(
  "combine_effects\\(miss_int.*$",
  paste0("rep_vector(logit(", prop_miss, "), miss_fnindex)"),
  model_text
)
temp_model <- tempfile(".stan")
writeLines(model_text, temp_model)

model_fixed <- enw_model(model = temp_model, threads = FALSE)

nowcast[["fixed"]] <- epinowcast(pobs,
  missing = enw_missing(~ (1 | week), data = pobs),
  report = enw_report(~ (1 | day_of_week), data = pobs),
  fit = enw_fit_opts(
    save_warmup = FALSE, pp = TRUE,
    chains = 4, iter_warmup = 500, iter_sampling = 500,
    likelihood_aggregation = "groups", adapt_delta = 0.9
  ),
  obs = obs,
  model = model_fixed
)

update_data <- function(pobs, pp_sample) {
  new_obs <- copy(pobs$new_confirm[[1]])
  max_delay <- max(new_obs$delay) + 1
  new_obs$new_confirm <- pp_sample$pp_obs
  new_obs <- enw_incidence_to_cumulative(new_obs)

  rep_w_complete_ref <- enw_reps_with_complete_refs(
    new_obs,
    max_delay = max_delay,
    by = ".group"
  )

  new_obs[, .group := NULL]
  new_obs[, cum_prop_reported := NULL]
  new_obs[, prop_reported := NULL]
  new_obs[, new_confirm := NULL]
  new_obs[, max_confirm := NULL]
  new_obs[, delay := NULL]

  new_miss <- copy(pobs$missing_reference[[1]])[
      rep_w_complete_ref,
      on = c("report_date", ".group")
  ]
  new_miss$confirm <- pp_sample$pp_miss_ref
  new_miss[, .group := NULL]
  new_miss[, prop_missing := NULL]

  final <- rbindlist(list(new_obs, new_miss), fill = TRUE)
  return(final)
}

extract_pp_sample <- function(fit, chain = NULL, sample = NULL) {
  dr <- fit$draws(format = "draws_list")

  nb_chains <- length(dr)
  if (is.null(chain)) chain <- sample(seq_len(nb_chains), 1)
  cdr <- dr[[chain]]

  nb_samples <- length(cdr[["lp__"]])
  if (is.null(sample)) sample <- sample(seq_len(nb_samples), 1)

  ret <- list()

  for (var in c("pp_obs", "pp_miss_ref")) {
    ret[[var]] <- unname(
      vapply(
        cdr[grep(var, names(cdr), value = TRUE)],
        "[",
        sample,
        FUN.VALUE = 0
      )
    )
  }

  return(ret)
}

pp_sample <- extract_pp_sample(nowcast[["fixed"]]$fit[[1]])
new_data <- update_data(pobs, pp_sample)

# Preprocess observations (note this maximum delay is likely too short)
sim_pobs <- enw_preprocess_data(new_data, max_delay = max_delay)
sim_obs <- enw_obs(family = "poisson", data = sim_pobs)

sim_obs <- obs

nowcast[["resim"]] <- epinowcast(pobs,
  missing = enw_missing(~ (1 | week), data = sim_pobs),
  report = enw_report(~ (1 | day_of_week), data = sim_pobs),
  fit = enw_fit_opts(
    save_warmup = FALSE, pp = TRUE,
    chains = 4, iter_warmup = 500, iter_sampling = 500,
    likelihood_aggregation = "groups", adapt_delta = 0.9
  ),
  obs = sim_obs,
  model = model
)

# Plot nowcast of observed values
plot(nowcast[["resim"]], latest_obs)

# Check posterior predictions for missing reference date proportions
miss_prop <- enw_posterior(nowcast[["resim"]]$fit[[1]], variables = "miss_ref_lprop")
cols <- c("mean", "median", "q5", "q20", "q80", "q95")
miss_prop[, (cols) := lapply(.SD, exp), .SDcols = cols]
miss_prop <- cbind(
  sim_pobs$latest[[1]][, .(reference_date, confirm = NA)], miss_prop
)

ggplot(miss_prop) +
  aes(x = reference_date) +
  geom_line(aes(y = median), size = 1, alpha = 0.6) +
  geom_hline(yintercept = prop_miss, linetype = 2) +
  geom_ribbon(aes(ymin = q5, ymax = q95), alpha = 0.2, size = 0.2) +
  geom_ribbon(aes(ymin = q20, ymax = q80, col = NULL), alpha = 0.2) +
  geom_hline(yintercept = prop_miss, linetype = 2) +
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
  labs(x = "Report date", y = "Notifications with a missing reference date")

fit_data <- nowcast[["variable"]]$data[[1]]

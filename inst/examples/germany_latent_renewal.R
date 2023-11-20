# Load packages
library(epinowcast)
library(data.table)
library(ggplot2)

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
  remove_days = 40, include_days = 40
)

# Preprocess observations (note this maximum delay is likely too short)
pobs <- enw_preprocess_data(retro_nat_germany, max_delay = 20)

# Compile nowcasting model
model <- enw_model(stanc_options = list("O1"))

# Reference date model: Fixed log-normal distribution
reference_module <- enw_reference(~1, data = pobs)

# Report date model: Day of week reporting effect
report_module <- enw_report(~ (1 | day_of_week), data = pobs)

# Expectation model:
# - Random walk on the log of expected cases
# - Generation time with probability mass spread over 4 days
# - latent reporting delay representing the incubation period and assumed
# ascertainment
# - Day of week reporting effect
expectation_module <- enw_expectation(
  r = ~ 0 + (1 | day),
  generation_time = c(0.1, 0.4, 0.4, 0.1),
  observation = ~ (1 | day_of_week),
  latent_reporting_delay = 0.4 * c(0.05, 0.3, 0.6, 0.05),
  data = pobs
)

# Fit nowcast model with these modules and produce a nowcast
nowcast <- epinowcast(pobs,
  expectation = expectation_module,
  reference = reference_module,
  report = report_module,
  fit = enw_fit_opts(
    save_warmup = FALSE, pp = TRUE,
    chains = 2, threads_per_chain = 2,
    parallel_chains = 2,
    iter_warmup = 1000, iter_sampling = 1000,
    adapt_delta = 0.95,
    show_messages = FALSE
  ),
  model = model
)

# Plot nowcast of observed values
plot(nowcast, latest_obs)

# Plot Reproduction number estimates
rt <- enw_posterior(nowcast$fit[[1]], variables = "r")
cols <- c("mean", "median", "q5", "q20", "q80", "q95")
rt[, (cols) := lapply(.SD, exp), .SDcols = cols]
rt <- cbind(
  expectation_module$data_raw$r[, .(date)], rt
)

ggplot(rt) +
  aes(x = date) +
  geom_line(aes(y = median), linewidth = 1, alpha = 0.6) +
  geom_line(aes(y = mean), linetype = 2) +
  geom_ribbon(aes(ymin = q5, ymax = q95), alpha = 0.2, linewidth = 0.2) +
  geom_ribbon(aes(ymin = q20, ymax = q80, col = NULL), alpha = 0.2) +
  geom_hline(yintercept = 1, linetype = 2) +
  theme_bw() +
  labs(
    x = "Reference date",
    y = "Effective reproduction number"
  )

# Plot expected latent cases
latent_exp_cases <- enw_posterior(
  nowcast$fit[[1]],
  variables = "exp_llatent"
)
latent_exp_cases[, (cols) := lapply(.SD, exp), .SDcols = cols]
latent_exp_cases <- cbind(
  enw_extend_date(
    expectation_module$data_raw$r[, .(date, .group = 1)],
    days = nowcast$data[[1]]$expl_lrd_n,
    direction = "start"
  ),
  latent_exp_cases
)

ggplot(latent_exp_cases) +
  aes(x = date) +
  geom_line(aes(y = median), linewidth = 1, alpha = 0.6) +
  geom_line(aes(y = mean), linetype = 2) +
  geom_ribbon(aes(ymin = q5, ymax = q95), alpha = 0.2, linewidth = 0.2) +
  geom_ribbon(aes(ymin = q20, ymax = q80, col = NULL), alpha = 0.2) +
  theme_bw() +
  labs(
    x = "Reference date",
    y = "Expected latent cases"
  )

# Plot expected reported cases
exp_cases <- enw_posterior(
  nowcast$fit[[1]],
  variables = "exp_lobs"
)
exp_cases[, (cols) := lapply(.SD, exp), .SDcols = cols]
exp_cases <- cbind(
  expectation_module$data_raw$observation,
  exp_cases
)

exp_cases <- enw_latest_data(nat_germany_hosp)[, date := reference_date][
  exp_cases,
  on = "date"
]

ggplot(exp_cases) +
  aes(x = date) +
  geom_point(aes(y = confirm)) +
  geom_line(aes(y = median), linewidth = 1, alpha = 0.6) +
  geom_line(aes(y = mean), linetype = 2) +
  geom_ribbon(aes(ymin = q5, ymax = q95), alpha = 0.2, linewidth = 0.2) +
  geom_ribbon(aes(ymin = q20, ymax = q80, col = NULL), alpha = 0.2) +
  theme_bw() +
  labs(
    x = "Reference date",
    y = "Expected reported cases"
  )

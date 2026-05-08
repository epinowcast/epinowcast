# Quick sanity check that the centred-RW Stan model runs and produces a
# fit on the ts__latent_renewal cell. We expect roughly the same order of
# divergence magnitude — orders of magnitude more would mean the centred
# implementation is broken.

suppressPackageStartupMessages({
  devtools::load_all(quiet = TRUE)
  library(data.table)
})

# Build the same data used by ts__latent_renewal in runtime-grid/R/cells.R.
build_germany_pobs <- function(max_delay = 20L, include_days = 40L,
                               remove_days = 40L,
                               latest_date = "2021-10-01") {
  d <- germany_covid19_hosp[location == "DE" & age_group == "00+"]
  d <- enw_filter_report_dates(d, latest_date = latest_date)
  d <- enw_complete_dates(d, by = c("location", "age_group"),
                          missing_reference = FALSE)
  retro <- enw_filter_report_dates(d, remove_days = remove_days)
  retro <- enw_filter_reference_dates(retro, include_days = include_days)
  enw_preprocess_data(retro, max_delay = max_delay)
}

pobs <- build_germany_pobs()

t0 <- Sys.time()
fit <- epinowcast(
  pobs,
  expectation = enw_expectation(
    r = ~ 1 + rw(week),
    generation_time = c(0.1, 0.4, 0.4, 0.1),
    observation = ~ (1 | day_of_week),
    latent_reporting_delay = 0.4 * c(0.05, 0.3, 0.6, 0.05),
    data = pobs
  ),
  reference = enw_reference(~1, data = pobs),
  report = enw_report(~ (1 | day_of_week), data = pobs),
  obs = enw_obs(family = "negbin", data = pobs),
  fit = enw_fit_opts(
    chains = 1, iter_warmup = 300, iter_sampling = 300,
    adapt_delta = 0.95, parallel_chains = 1,
    threads_per_chain = 2, seed = 1L
  ),
  model = enw_model(profile = TRUE)
)
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))

diag <- fit$fit[[1]]$diagnostic_summary()
cat("\n----\n")
cat(sprintf("Elapsed: %.1f s\n", elapsed))
cat("Divergent transitions per chain:\n")
print(diag$num_divergent)
cat("Max treedepth hits per chain:\n")
print(diag$num_max_treedepth)
cat("EBFMI per chain:\n")
print(diag$ebfmi)

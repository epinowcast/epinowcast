# NCP vs centred-RW experiment for issue #800.
#
# Strategy: this worktree currently has the centred-RW Stan source in place.
# We run the centred arm here, and we run the NCP arm by checking out the
# original Stan source from `main` into a separate path, compiling against
# the same package. Both arms use the same data, the same sampler config,
# and matched seeds.
#
# We deliberately drop `sw__init_prior` because at tier 2 it is identical
# to `ts__latent_renewal` (init_method=prior is the tier-2 default).
# Cells run: `ts__latent_renewal` and `vig__renewal`.

suppressPackageStartupMessages({
  devtools::load_all(quiet = TRUE)
  library(data.table)
  library(posterior)
})

WORKTREE <- "/Users/lshsa2/code/epinowcast/epinowcast/.claude/worktrees/agent-adf736ec389b2b7e1"
OUT_CSV <- file.path(WORKTREE, "experiments", "ncp_vs_centred.csv")
NCP_STAN_DIR <- file.path(WORKTREE, "experiments", "ncp_stan")

# ---- Stan source variants -------------------------------------------------

# Stage NCP source by copying the Stan tree, then overwriting the centred
# files with their `main` versions. The compiled NCP model lives in
# experiments/ncp_stan/ and the centred model uses inst/stan/.
stage_ncp_stan <- function() {
  if (dir.exists(NCP_STAN_DIR)) unlink(NCP_STAN_DIR, recursive = TRUE)
  dir.create(NCP_STAN_DIR, recursive = TRUE)
  file.copy(file.path(WORKTREE, "inst", "stan"), NCP_STAN_DIR,
            recursive = TRUE)
  # Overwrite with `main` versions (NCP).
  for (rel in c("functions/effects_priors_lp.stan",
                "functions/combine_effects.stan",
                "epinowcast.stan")) {
    src <- system2("git",
                   c("-C", WORKTREE, "show", paste0("main:inst/stan/", rel)),
                   stdout = TRUE)
    out <- file.path(NCP_STAN_DIR, "stan", rel)
    writeLines(src, out)
  }
}

stage_ncp_stan()

compile_model <- function(stan_dir) {
  stan_file <- file.path(stan_dir, "stan", "epinowcast.stan")
  include <- file.path(stan_dir, "stan")
  cmdstanr::cmdstan_model(
    stan_file,
    include_paths = include,
    compile_standalone = FALSE,
    cpp_options = list(stan_threads = TRUE),
    stanc_options = list("O1"),
    force_recompile = FALSE
  )
}

cat("Compiling centred model...\n")
m_centred <- enw_model(profile = TRUE)
cat("Compiling NCP model...\n")
m_ncp <- compile_model(NCP_STAN_DIR)

# ---- data builders --------------------------------------------------------

build_germany_pobs <- function(max_delay) {
  d <- germany_covid19_hosp[location == "DE" & age_group == "00+"]
  d <- enw_filter_report_dates(d, latest_date = "2021-10-01")
  d <- enw_complete_dates(d, by = c("location", "age_group"),
                          missing_reference = FALSE)
  retro <- enw_filter_report_dates(d, remove_days = 40)
  retro <- enw_filter_reference_dates(retro, include_days = 40)
  enw_preprocess_data(retro, max_delay = max_delay)
}

# ---- cell builders --------------------------------------------------------

cell_ts_latent_renewal <- function(stan_model, seed) {
  pobs <- build_germany_pobs(max_delay = 20L)
  epinowcast(
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
      chains = 4, iter_warmup = 1000, iter_sampling = 1000,
      adapt_delta = 0.95, max_treedepth = 10,
      parallel_chains = 4, threads_per_chain = 2,
      seed = seed
    ),
    model = stan_model
  )
}

cell_vig_renewal <- function(stan_model, seed) {
  pobs <- build_germany_pobs(max_delay = 28L)
  epinowcast(
    pobs,
    expectation = enw_expectation(
      r = ~ 1 + rw(week),
      generation_time = c(0.1, 0.4, 0.4, 0.1),
      observation = ~ (1 | day_of_week),
      latent_reporting_delay = 0.4 * c(0.05, 0.3, 0.6, 0.05),
      data = pobs
    ),
    reference = enw_reference(~1, distribution = "lognormal", data = pobs),
    report = enw_report(~ (1 | day_of_week), data = pobs),
    obs = enw_obs(family = "negbin", data = pobs),
    fit = enw_fit_opts(
      chains = 4, iter_warmup = 1000, iter_sampling = 1000,
      adapt_delta = 0.98, max_treedepth = 12,
      parallel_chains = 4, threads_per_chain = 2,
      seed = seed
    ),
    model = stan_model
  )
}

cells <- list(
  ts__latent_renewal = cell_ts_latent_renewal,
  vig__renewal = cell_vig_renewal
)

arms <- list(centred = m_centred, ncp = m_ncp)

# Three replicates with deterministic-per-arm seeds so the comparison is
# matched: same seed across arms ensures the only variable is the
# parameterisation. (cmdstan still varies chain seeds internally.)
seeds <- c(101L, 202L, 303L)

# ---- run ------------------------------------------------------------------

extract_metrics <- function(fit, wall_total_s) {
  cmd_fit <- fit$fit[[1]]
  diag <- cmd_fit$diagnostic_summary(quiet = TRUE)
  draws <- cmd_fit$draws(format = "draws_array")
  summ <- posterior::summarise_draws(draws,
    posterior::default_convergence_measures())
  # Drop log-density rows where ESS isn't meaningful; keep all parameters.
  rhat <- summ$rhat
  ess_bulk <- summ$ess_bulk
  finite_ess <- ess_bulk[is.finite(ess_bulk) & !is.na(ess_bulk)]
  finite_rhat <- rhat[is.finite(rhat) & !is.na(rhat)]
  # Per-chain wall time (sampling+warmup).
  times <- cmd_fit$time()$chains
  total_chain_time <- times$total
  # ESS/sec per chain treated as min(ess_bulk) / max(chain_total_time)
  ess_per_s <- min(finite_ess) / max(total_chain_time)
  # Total leapfrog: sum metadata$num_leapfrog__ across draws.
  sampler_diag <- cmd_fit$sampler_diagnostics(format = "draws_df")
  n_leapfrog <- sum(sampler_diag$n_leapfrog__)
  list(
    divergent_count = sum(diag$num_divergent),
    max_treedepth_count = sum(diag$num_max_treedepth),
    ebfmi_min = min(diag$ebfmi),
    max_rhat = max(finite_rhat),
    min_ess_bulk = min(finite_ess),
    ess_bulk_per_s_slowest = ess_per_s,
    wall_total_s = wall_total_s,
    n_leapfrog_total = n_leapfrog
  )
}

results <- list()
log_path <- file.path(WORKTREE, "experiments", "run.log")
cat(sprintf("Run started: %s\n", Sys.time()), file = log_path)

abort <- FALSE
for (cell_name in names(cells)) {
  for (arm_name in names(arms)) {
    if (abort) break
    for (rep in seq_along(seeds)) {
      seed <- seeds[rep]
      tag <- sprintf("[%s | %s | seed=%d (rep %d/3)]", cell_name, arm_name,
                     seed, rep)
      cat(tag, "starting\n")
      cat(tag, "starting\n", file = log_path, append = TRUE)
      t0 <- Sys.time()
      fit <- tryCatch(
        cells[[cell_name]](arms[[arm_name]], seed),
        error = function(e) {
          cat(tag, "FAILED:", conditionMessage(e), "\n")
          cat(tag, "FAILED:", conditionMessage(e), "\n",
              file = log_path, append = TRUE)
          NULL
        }
      )
      wall <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
      if (is.null(fit)) {
        rec <- list(cell = cell_name, arm = arm_name, rep = rep,
                    seed = seed, wall_total_s = wall,
                    divergent_count = NA_integer_,
                    max_treedepth_count = NA_integer_,
                    ebfmi_min = NA_real_, max_rhat = NA_real_,
                    min_ess_bulk = NA_real_,
                    ess_bulk_per_s_slowest = NA_real_,
                    n_leapfrog_total = NA_integer_,
                    note = "fit failed")
      } else {
        m <- extract_metrics(fit, wall)
        rec <- c(list(cell = cell_name, arm = arm_name, rep = rep,
                      seed = seed), m, list(note = ""))
      }
      results[[length(results) + 1L]] <- rec
      cat(tag, sprintf(
        "wall=%.0fs div=%s ess_min=%s ess/s=%.2f\n",
        wall, format(rec$divergent_count), format(rec$min_ess_bulk),
        rec$ess_bulk_per_s_slowest
      ))
      cat(tag, sprintf(
        "wall=%.0fs div=%s ess_min=%s ess/s=%.2f\n",
        wall, format(rec$divergent_count), format(rec$min_ess_bulk),
        rec$ess_bulk_per_s_slowest
      ), file = log_path, append = TRUE)
      # Periodically write CSV.
      df <- rbindlist(lapply(results, as.data.frame), fill = TRUE)
      fwrite(df, OUT_CSV)
      # Mid-experiment safety check: after the FIRST centred replicate of
      # the FIRST cell, if div is wildly larger than typical NCP (>500),
      # bail out — the centred variant is broken.
      if (cell_name == names(cells)[1] && arm_name == "centred" &&
          rep == 1L && !is.na(rec$divergent_count) &&
          rec$divergent_count > 500) {
        cat("ABORT: centred arm produced", rec$divergent_count,
            "divergences on first replicate. Stopping.\n",
            file = log_path, append = TRUE)
        abort <- TRUE
        break
      }
    }
  }
}

cat("Done. Results:\n")
print(rbindlist(lapply(results, as.data.frame), fill = TRUE))
cat("Saved to:", OUT_CSV, "\n")

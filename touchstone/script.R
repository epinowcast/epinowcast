# see `help(run_script, package = 'touchstone')` on how to run this
# interactively

# installs branches to benchmark
touchstone::branch_install()

# benchmarks.
touchstone::pin_assets("inst/examples")

# run benchmarks
touchstone::benchmark_run(
  simple = {
    source(touchstone::path_pinned_asset("germany_simple.R"))
  },
  n = 3
)

touchstone::benchmark_run(
  day_of_week = {
    source(touchstone::path_pinned_asset("germany_dow.R"))
  },
  n = 3
)


touchstone::benchmark_run(
  missingness = {
    source(touchstone::path_pinned_asset("germany_missing.R"))
  },
  n = 3
)

touchstone::benchmark_run(
  latent_renewal = {
    source(touchstone::path_pinned_asset("germany_latent_renewal.R"))
  },
  n = 3
)

# create artifacts used downstream in the GitHub Action.
touchstone::benchmark_analyze()
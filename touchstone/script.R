# see `help(run_script, package = 'touchstone')` on how to run this
# interactively

# benchmarks.
touchstone::pin_assets("inst/examples")

# installs branches to benchmark
touchstone::branch_install()

# run benchmarks
touchstone::benchmark_run(
  simple = {
    source(path_pinned_asset("inst/examples/germany_simple.R"))
  },
  n = 3
)

touchstone::benchmark_run(
  day_of_week = {
    source(path_pinned_asset("inst/examples/germany_dow.R"))
  },
  n = 3
)

touchstone::benchmark_run(
  missingness = {
    source(path_pinned_asset("inst/examples/germany_missing.R"))
  },
  n = 3
)

touchstone::benchmark_run(
  latent_renewal = {
    source(path_pinned_asset("inst/examples/germany_latent_renewal.R"))
  },
  n = 3
)

# create artifacts used downstream in the GitHub Action
touchstone::benchmark_analyze()
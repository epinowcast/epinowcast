# see `help(run_script, package = 'touchstone')` on how to run this
# interactively

# installs branches to benchmark
touchstone::branch_install()

# run benchmarks
touchstone::benchmark_run(
  simple = {
    print("Hello world!")
  },
  n = 3
)

touchstone::benchmark_run(
  day_of_week = {
    source("inst/examples/germany_dow.R")
  },
  n = 3
)

touchstone::benchmark_run(
  missingness = {
    source("inst/examples/germany_missing.R")
  },
  n = 3
)

touchstone::benchmark_run(
  latent_renewal = {
    source(
      "inst/examples/germany_latent_renewal.R"
    )
  },
  n = 3
)

# create artifacts used downstream in the GitHub Action.
touchstone::benchmark_analyze()
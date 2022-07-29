skip_on_cran()
skip_on_os("windows")
skip_on_os("mac")
epinowcast:::expose_stan_fns(
  c(
    "hazard.stan", "combine_logit_hazards.stan", "expected_obs.stan",
    "expected_obs_from_index.stan", "obs_lmpf.stan", "delay_lmpf"
  ),
  system.file("stan/functions", package = "epinowcast")
)

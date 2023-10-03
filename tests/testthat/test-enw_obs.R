test_that("enw_obs() produces the expected output", {

  # Load and filter germany hospitalisations
  nat_germany_hosp <-
    germany_covid19_hosp[location == "DE"][age_group %in% "00+"]
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
    include_days = 10
  )

  # Preprocess observations (note this maximum delay is likely too short)
  pobs <- enw_preprocess_data(retro_nat_germany, max_delay = 5)

  expect_snapshot({
    obs <- enw_obs(family = "negbin", data = pobs)
    obs$inits <- NULL
    obs
  })
  obs <- enw_obs(data = pobs)
  expect_named(
    obs$init(obs$data, obs$priors)(),
    c("sqrt_phi", "phi")
  )
  expect_equal(enw_obs(family = "poisson", data = pobs)$data$model_obs, 0)
  expect_error(enw_obs(family = "wefgweefw", data = pobs))

  # Check that missing data is handled as expected
  retro_nat_germany[report_date %in% as.Date("2021-08-13"), confirm := NA]
  retro_nat_germany <- enw_flag_observed_observations(
    retro_nat_germany, copy = FALSE
  )
  retro_nat_germany <- enw_impute_na_observations(
    retro_nat_germany, copy = FALSE
  )
  pobs_missing <- enw_preprocess_data(retro_nat_germany, max_delay = 5)
  expect_snapshot({
    obs_missing <- enw_obs(
      family = "negbin", data = pobs_missing,
      observation_indicator = ".observed"
    )
    obs_missing$inits <- NULL
    obs_missing
  })
})

# Use germany data like other preprocessing tests
nat_germany_hosp <- germany_covid19_hosp[location == "DE"][age_group == "00+"]

test_that("enw_structural_reporting_metadata creates correct grid structure", {
  pobs <- enw_preprocess_data(nat_germany_hosp, max_delay = 5)

  metadata <- enw_structural_reporting_metadata(pobs)

  # Check it's a data.table
  expect_data_table(metadata)

  # Check required columns
  expect_true(all(c(".group", "date", "report_date") %in% names(metadata)))

  # Check report_date is reference date + delay
  expect_true(all(metadata$report_date >= metadata$date))
  expect_true(all(metadata$report_date - metadata$date < pobs$max_delay))

  # Check complete grid
  n_groups <- pobs$groups[[1]]
  n_times <- pobs$time[[1]]
  max_delay <- pobs$max_delay
  expected_rows <- n_groups * n_times * max_delay
  expect_equal(nrow(metadata), expected_rows)
})

test_that("enw_dayofweek_structural_reporting works with single weekday", {
  pobs <- enw_preprocess_data(nat_germany_hosp, max_delay = 5)

  structural <- enw_dayofweek_structural_reporting(
    pobs, day_of_week = "Wednesday"
  )

  # Check it's a data.table
  expect_data_table(structural)

  # Check required columns
  required_cols <- c(".group", "date", "report_date", "report")
  expect_true(all(required_cols %in% names(structural)))

  # Check report column is binary
  expect_true(all(structural$report %in% c(0, 1)))

  # Check Wednesday reporting
  structural[, day_name := weekdays(report_date)]
  expect_true(all(structural[day_name == "Wednesday"]$report == 1))
  expect_true(all(structural[day_name != "Wednesday"]$report == 0))
})

test_that("enw_dayofweek_structural_reporting works with multiple weekdays", {
  pobs <- enw_preprocess_data(nat_germany_hosp, max_delay = 5)

  structural <- enw_dayofweek_structural_reporting(
    pobs, day_of_week = c("Monday", "Wednesday", "Friday")
  )

  # Check report column
  expect_true(all(structural$report %in% c(0, 1)))

  # Check multiple day reporting
  structural[, day_name := weekdays(report_date)]
  reporting_days <- c("Monday", "Wednesday", "Friday")
  expect_true(all(structural[day_name %in% reporting_days]$report == 1))
  expect_true(all(structural[!day_name %in% reporting_days]$report == 0))
})

test_that("enw_dayofweek_structural_reporting maintains grid structure", {
  pobs <- enw_preprocess_data(nat_germany_hosp, max_delay = 5)

  structural <- enw_dayofweek_structural_reporting(
    pobs, day_of_week = "Wednesday"
  )

  # Check complete grid
  n_groups <- pobs$groups[[1]]
  n_times <- pobs$time[[1]]
  max_delay <- pobs$max_delay
  expected_rows <- n_groups * n_times * max_delay
  expect_equal(nrow(structural), expected_rows)

  # Check sorted by group, date, report_date
  expect_true(
    all(structural[, .I] ==
        structural[order(.group, date, report_date), .I])
  )
})

test_that("epinowcast() with weekly reporting and structural model converges", {
  skip_on_cran()
  skip_on_local()

  # Prepare weekly reporting data like the example
  obs <- run_window_filter(
    germany_covid19_hosp[age_group == "00+"][location == "DE"]
  )

  # Add day of week and aggregate to weekly
  obs[, day_of_week := weekdays(report_date)]
  weekly_obs <- enw_rolling_sum(
    obs,
    internal_timestep = 7,
    by = "reference_date",
    value_col = "confirm"
  )

  # Keep only Wednesday reports
  weekly_obs[, confirm := fifelse(day_of_week == "Wednesday", confirm, NA_real_)]
  weekly_obs <- enw_flag_observed_observations(weekly_obs)

  # Preprocess
  pobs <- enw_preprocess_data(weekly_obs, max_delay = 10)

  # Create Wednesday structural reporting
  structural <- enw_dayofweek_structural_reporting(pobs, day_of_week = "Wednesday")

  # Fit model
  nowcast <- suppressMessages(epinowcast(pobs,
    expectation = enw_expectation(~1, data = pobs),
    report = enw_report(structural = structural, data = pobs),
    fit = enw_fit_opts(
      save_warmup = FALSE, pp = FALSE,
      chains = 2, iter_warmup = 250, iter_sampling = 250
    ),
    obs = enw_obs(family = "negbin", observation_indicator = ".observed", data = pobs)
  ))

  # Check model structure
  expect_identical(class(nowcast$fit[[1]])[1], "CmdStanMCMC")
  expect_type(nowcast$data[[1]], "list")

  # Check data includes structural aggregation arrays
  expect_true("rep_agg_p" %in% names(nowcast$data[[1]]))
  expect_equal(nowcast$data[[1]]$rep_agg_p, 1)
  expect_true("rep_agg_n_selected" %in% names(nowcast$data[[1]]))
  expect_true("rep_agg_selected_idx" %in% names(nowcast$data[[1]]))

  # Check convergence
  expect_lt(nowcast$max_rhat, 1.05)
  expect_lt(nowcast$per_divergent_transitions, 0.05)
})

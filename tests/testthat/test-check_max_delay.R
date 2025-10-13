test_that("check_max_delay produces the expected warnings", {
  obs <- enw_example(type = "preprocessed_observations")
  expect_warning(
    check_max_delay(obs, max_delay = 5),
    regexp = "covers less than 80% of cases for the majority"
  )

  expect_no_warning(
    check_max_delay(obs, max_delay = 5, warn = FALSE)
  )

  expect_warning(
    check_max_delay(obs, max_delay = 8, cum_coverage = 0.9),
    regexp = "covers less than 90% of cases for the majority"
  )

  expect_no_warning(
    check_max_delay(obs, max_delay = 10)
  )

  expect_warning(
    check_max_delay(obs, max_delay = 40),
    regexp = "but the maximum observed delay is only"
  )

  obs_left_trunc <- obs
  obs_left_trunc$obs[[1]] <- obs_left_trunc$obs[[1]][
    reference_date > "2021-08-10",
    ]
  expect_warning(
    check_max_delay(obs_left_trunc, max_delay = 10),
    regexp = "you can decrease `maxdelay_quantile_outlier` to"
  )
  expect_warning(
    check_max_delay(
      obs_left_trunc, max_delay = 10, warn = TRUE, warn_internal = TRUE
      ),
    regexp = "You can test different maximum delays and obtain coverage"
  )
})

test_that("check_max_delay aborts on invalid inputs", {
  obs <- enw_example(type = "preprocessed_observations")

  expect_error(
    check_max_delay(obs, max_delay = "something"),
    regexp = "must be an integer and not NA"
  )

  expect_error(
    check_max_delay(obs, max_delay = NA),
    regexp = "must be an integer and not NA"
  )

  expect_error(
    check_max_delay(obs, max_delay = 0),
    regexp = "must be greater than or equal to one"
  )

  expect_error(
    check_max_delay(obs, max_delay = -1),
    regexp = "must be greater than or equal to one"
  )

  expect_error(
    check_max_delay(obs, max_delay = 20, cum_coverage = 20),
    regexp = "must be between 0 and 1, e.g. 0.8 for"
  )

  expect_error(
    check_max_delay(obs, max_delay = 20, maxdelay_quantile_outlier = 97),
    regexp = "must be between 0 and 1, e.g. 0.97 for"
  )
})


test_that("check_max_delay produces the expected output", {
  obs <- enw_example(type = "preprocessed_observations")

  expect_equal(
    check_max_delay(obs, max_delay = 10),
    data.table(
      .group = c(1, "all"), coverage = c(0.8, 0.8),
      below_coverage = c(0.2380952, 0.2380952)
    ),
    tolerance = 0.0001
  )

  expect_warning(check_max_delay(obs, max_delay = 13, cum_coverage = 0.9))

  expect_equal(
    check_max_delay(obs, max_delay = 10, cum_coverage = 0.7),
    data.table(
      .group = c(1, "all"), coverage = c(0.7, 0.7),
      below_coverage = c(0.04761905, 0.04761905)
    ),
    tolerance = 0.0001
  )

  expect_identical(
    check_max_delay(obs, max_delay = 20),
    data.table(
      .group = c(1, "all"), coverage = c(0.8, 0.8), below_coverage = c(0, 0)
    )
  )

  expect_error(check_max_delay(obs, max_delay = 10, cum_coverage = 80))

  nat_germany_hosp <- epinowcast::germany_covid19_hosp[location == "DE"]
  pobs <- enw_preprocess_data(
    nat_germany_hosp, max_delay = 15, by = "age_group"
    )
  expect_snapshot(
    check_max_delay(pobs, max_delay = 15)
  )
})

test_that(
  "check_max_delay() works with different timesteps",
  {
    nat_germany_hosp <- germany_covid19_hosp[location == "DE"]
    nat_germany_hosp <- nat_germany_hosp[age_group == "00+"]
    weekly_nat_germany_hosp <- enw_aggregate_cumulative(
      nat_germany_hosp, timestep = "week"
      )

    weekly_nat_germany_hosp <- enw_filter_reference_dates(
      weekly_nat_germany_hosp, earliest_date = "2021-05-10"
      )

    # week
    weekly_pobs <- enw_preprocess_data(
      weekly_nat_germany_hosp,
      max_delay = 5, timestep = "week"
    )

    expect_snapshot(
      check_max_delay(weekly_pobs)
    )

    expect_warning(
      check_max_delay(weekly_pobs, max_delay = 1),
      "specified maximum reporting delay \\(7 days\\) covers less"
    )

    # month
    weekly_nat_germany_hosp <- enw_aggregate_cumulative(
      nat_germany_hosp, timestep = 14
      )

    weekly_nat_germany_hosp <- enw_filter_reference_dates(
      weekly_nat_germany_hosp, earliest_date = "2021-05-10"
      )

    weekly_pobs <- enw_preprocess_data(
      weekly_nat_germany_hosp,
      max_delay = 2, timestep = 14
    )

    expect_snapshot(
      check_max_delay(weekly_pobs)
    )

    expect_warning(
      check_max_delay(weekly_pobs, max_delay = 1),
      "specified maximum reporting delay \\(14 days\\) covers less"
    )

    expect_snapshot(
      suppressWarnings(check_max_delay(weekly_pobs, max_delay = 1))
    )
  }
)

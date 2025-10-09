test_that("Can score nowcasts", {
  skip_on_cran()
  skip_if_not_installed("scoringutils")
  nowcast <- enw_example("nowcast")
  summarised_nowcast <- summary(nowcast)
  obs <- enw_example("observations")

  expect_data_table(
    suppressPackageStartupMessages(suppressWarnings(suppressMessages(
      enw_score_nowcast(summarised_nowcast, obs)
    )))
  )
  expect_data_table(
    suppressWarnings(suppressMessages(
      enw_score_nowcast(
        summarised_nowcast, obs,
        log = TRUE
      )
    ))
  )
  expect_data_table(
    suppressWarnings(suppressMessages(enw_score_nowcast(
      summarised_nowcast, obs,
      check = TRUE
    )))
  )
})

test_that("Can convert epinowcast object to forecast_sample", {
  skip_on_cran()
  skip_if_not_installed("scoringutils")

  nowcast <- enw_example("nowcast")
  obs <- enw_example("observations")

  # Test basic conversion
  test <- expect_s3_class(
    suppressPackageStartupMessages(
      as_forecast_sample(nowcast, obs)
    ),
    "forecast_sample"
  )

  # Test with grouping variables
  obs$group <- "test"
  forecast_data <- suppressPackageStartupMessages(
    as_forecast_sample(nowcast, obs)
  )
  expect_true("group" %in% names(forecast_data))
  expect_true(all(forecast_data$group == "test"))

  expect_true(all(
    c("observed", "predicted", "sample_id") %in% names(forecast_data)
  ))
})

test_that("Date alignment check detects misaligned weekly data", {
  skip_on_cran()
  skip_if_not_installed("scoringutils")

  # Create nowcast with weekly data starting on Monday
  nowcast <- enw_example("nowcast")
  obs <- enw_example("observations")

  # Modify obs to have dates that don't align (start on Wednesday instead)
  # Weekly dates on Mondays: 2021-08-02 (Mon), 2021-08-09, etc.
  # Shift to Wednesdays: 2021-08-04 (Wed), 2021-08-11, etc.
  obs_misaligned <- data.table::copy(obs)
  obs_misaligned[, reference_date := reference_date + 2]

  expect_error(
    suppressPackageStartupMessages(
      as_forecast_sample(nowcast, obs_misaligned)
    ),
    "Date alignment check failed"
  )

  expect_error(
    suppressPackageStartupMessages(
      as_forecast_sample(nowcast, obs_misaligned)
    ),
    "Latest observation date.*not found in nowcast dates"
  )
})

test_that("Date alignment check passes for aligned data", {
  skip_on_cran()
  skip_if_not_installed("scoringutils")

  nowcast <- enw_example("nowcast")
  obs <- enw_example("observations")

  # Should work without error
  expect_s3_class(
    suppressPackageStartupMessages(
      as_forecast_sample(nowcast, obs)
    ),
    "forecast_sample"
  )
})

test_that("Date alignment check handles grouped data", {
  skip_on_cran()
  skip_if_not_installed("scoringutils")

  nowcast <- enw_example("nowcast")
  obs <- enw_example("observations")

  # Add grouping variable
  obs$group_var <- "group1"

  # Should work with aligned grouped data
  expect_s3_class(
    suppressPackageStartupMessages(
      as_forecast_sample(nowcast, obs)
    ),
    "forecast_sample"
  )

  # Test misaligned grouped data
  obs_misaligned <- data.table::copy(obs)
  obs_misaligned[, reference_date := reference_date + 2]

  expect_error(
    suppressPackageStartupMessages(
      as_forecast_sample(nowcast, obs_misaligned)
    ),
    "Date alignment check failed"
  )
})

test_that("Date alignment check works with daily data", {
  skip_on_cran()
  skip_if_not_installed("scoringutils")

  nowcast <- enw_example("nowcast")
  obs <- enw_example("observations")

  # Daily data should work
  expect_s3_class(
    suppressPackageStartupMessages(
      as_forecast_sample(nowcast, obs)
    ),
    "forecast_sample"
  )

  # Misaligned daily data should error
  obs_misaligned <- data.table::copy(obs)
  obs_misaligned[, reference_date := reference_date + 1]

  expect_error(
    suppressPackageStartupMessages(
      as_forecast_sample(nowcast, obs_misaligned)
    ),
    "Date alignment check failed"
  )
})

test_that("Date alignment check handles edge cases", {
  skip_on_cran()
  skip_if_not_installed("scoringutils")

  nowcast <- enw_example("nowcast")
  obs <- enw_example("observations")

  # Test with single observation date
  obs_single <- obs[reference_date == max(reference_date)]
  expect_s3_class(
    suppressPackageStartupMessages(
      as_forecast_sample(nowcast, obs_single)
    ),
    "forecast_sample"
  )
})

test_that(".detect_timestep correctly identifies timesteps", {
  # Test daily data
  daily_dates <- seq(as.IDate("2021-01-01"), by = 1, length.out = 10)
  expect_identical(.detect_timestep(daily_dates), "daily")

  # Test weekly data
  weekly_dates <- seq(as.IDate("2021-01-04"), by = 7, length.out = 10)
  expect_identical(.detect_timestep(weekly_dates), "weekly")

  # Test monthly data (approximate)
  monthly_dates <- as.IDate(c(
    "2021-01-01", "2021-02-01", "2021-03-01", "2021-04-01"
  ))
  expect_identical(.detect_timestep(monthly_dates), "monthly")

  # Test single date
  expect_identical(.detect_timestep(as.IDate("2021-01-01")), "daily")
})

test_that(".check_date_alignment provides informative error messages", {
  # Create misaligned weekly dates
  nowcast_dates <- seq(as.IDate("2021-08-02"), by = 7, length.out = 5)
  obs_dates <- seq(as.IDate("2021-08-04"), by = 7, length.out = 3)

  expect_error(
    .check_date_alignment(nowcast_dates, obs_dates),
    "Date alignment check failed"
  )

  expect_error(
    .check_date_alignment(nowcast_dates, obs_dates),
    "Detected timestep: weekly"
  )

  expect_error(
    .check_date_alignment(nowcast_dates, obs_dates),
    "weekday"
  )

  # Test with group information
  expect_error(
    .check_date_alignment(nowcast_dates, obs_dates, group = "test_group"),
    "group: test_group"
  )
})

test_that(".check_date_alignment passes for aligned dates", {
  # Aligned weekly dates
  nowcast_dates <- seq(as.IDate("2021-08-02"), by = 7, length.out = 5)
  obs_dates <- nowcast_dates[1:3]

  expect_invisible(.check_date_alignment(nowcast_dates, obs_dates))

  # Aligned daily dates
  daily_nowcast <- seq(as.IDate("2021-08-02"), by = 1, length.out = 10)
  daily_obs <- daily_nowcast[1:5]

  expect_invisible(.check_date_alignment(daily_nowcast, daily_obs))
})

test_that(".check_date_alignment handles empty or NA dates", {
  nowcast_dates <- seq(as.IDate("2021-08-02"), by = 7, length.out = 5)

  # Empty obs dates
  expect_invisible(.check_date_alignment(nowcast_dates, as.IDate(character(0))))

  # All NA dates
  expect_invisible(
    .check_date_alignment(nowcast_dates, as.IDate(c(NA, NA)))
  )

  # Empty nowcast dates
  expect_invisible(
    .check_date_alignment(as.IDate(character(0)), nowcast_dates)
  )
})

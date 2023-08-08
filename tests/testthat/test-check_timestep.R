test_that("check_timestep() works correctly", {
  obs <- data.frame(
    date = seq(as.Date("2020-01-01"), by = "day", length.out = 10)
  )
  
  # test with "day" timestep and exact = TRUE
  expect_silent(
    check_timestep(obs, date_var = "date", timestep = "day", exact = TRUE)
  )
  
  # test with "day" timestep and exact = FALSE
  expect_silent(
    check_timestep(obs, date_var = "date", timestep = "day", exact = FALSE)
  )
  
  # test with "month" timestep and exact = TRUE, should fail
  expect_error(
    check_timestep(obs, date_var = "date", timestep = "month", exact = TRUE),
    "date has a shorter timestep than the specified timestep of a month"
  )
  
  # test with "week" timestep and exact = TRUE, should fail
  expect_error(
    check_timestep(obs, date_var = "date", timestep = "week", exact = TRUE),
    "date has a shorter timestep than the specified timestep of 7 day\\(s\\)"
  )

  # test with "month" timestep and exact = FALSE, should fail
  expect_error(
    check_timestep(obs, date_var = "date", timestep = "month", exact = FALSE),
    "date has a shorter timestep than the specified timestep of a month"
  )
})

test_that("check_timestep() works with weekly data", {
  # Weekly data
  obs_weekly <- data.frame(
    date = seq(as.Date("2020-01-01"), by = "week", length.out = 10)
  )
  
  # test with "week" timestep and exact = TRUE
  expect_silent(
    check_timestep(
      obs_weekly, date_var = "date", timestep = "week", exact = TRUE
    )
  )
  
  # test with "week" timestep and exact = FALSE
  expect_silent(
    check_timestep(
      obs_weekly, date_var = "date", timestep = "week", exact = FALSE
    )
  )
  
  # test with default "day" timestep and exact = TRUE, should fail
  expect_error(
    check_timestep(obs_weekly, date_var = "date", exact = TRUE),
    "date does not have the specified timestep of 1 day\\(s\\)"
  )

  # Weekly data with some weeks missing
  obs_weekly_missing <- data.table::as.data.table(obs_weekly)[-c(3,7), ]
  
  # test with "week" timestep and exact = TRUE, should fail
  expect_error(
    check_timestep(
      obs_weekly_missing, date_var = "date", timestep = "week", exact = TRUE,
      "date does not have the specified timestep of 7 day\\(s\\)"
    )
  )
  
  # test with "week" timestep and exact = FALSE, should still pass
  expect_silent(
    check_timestep(
      obs_weekly_missing, date_var = "date", timestep = "week", exact = FALSE
    )
  )
})

test_that("check_timestep() works with monthly data", {
  # Monthly data
  obs_monthly <- data.frame(
    date = seq(as.Date("2020-01-02"), by = "month", length.out = 10)
  )
  
  # test with "month" timestep and exact = TRUE
  expect_silent(
    check_timestep(
      obs_monthly, date_var = "date", timestep = "month", exact = TRUE
    )
  )
  
  # test with "month" timestep and exact = FALSE
  expect_silent(
    check_timestep(
      obs_monthly, date_var = "date", timestep = "month", exact = FALSE
    )
  )

  # Monthly data with some months missing
  obs_monthly_missing <- data.table::as.data.table(obs_monthly)[-c(2,8),]
  
  # test with "month" timestep and exact = TRUE, should fail
  expect_error(
    check_timestep(
      obs_monthly_missing, date_var = "date", timestep = "month", exact = TRUE,
      "date does not have the specified timestep of month"
    )
  )
  
  # test with "month" timestep and exact = FALSE, should still pass
  expect_error(
    check_timestep(
      obs_monthly_missing, date_var = "date", timestep = "month", exact = FALSE
    ),
    "Non-sequential dates are not currently supported for monthly data"
  )
})

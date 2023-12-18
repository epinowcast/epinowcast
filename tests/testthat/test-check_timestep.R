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
      obs_weekly,
      date_var = "date", timestep = "week", exact = TRUE
    )
  )

  # test with "week" timestep and exact = FALSE
  expect_silent(
    check_timestep(
      obs_weekly,
      date_var = "date", timestep = "week", exact = FALSE
    )
  )

  # test with default "day" timestep and exact = TRUE, should fail
  expect_error(
    check_timestep(obs_weekly, date_var = "date", exact = TRUE),
    "date does not have the specified timestep of 1 day\\(s\\)"
  )

  # Weekly data with some weeks missing
  obs_weekly_missing <- data.table::as.data.table(obs_weekly)[-c(3, 7), ]

  # test with "week" timestep and exact = TRUE, should fail
  expect_error(
    check_timestep(
      obs_weekly_missing,
      date_var = "date", timestep = "week", exact = TRUE,
      "date does not have the specified timestep of 7 day\\(s\\)"
    )
  )

  # test with "week" timestep and exact = FALSE, should still pass
  expect_silent(
    check_timestep(
      obs_weekly_missing,
      date_var = "date", timestep = "week", exact = FALSE
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
      obs_monthly,
      date_var = "date", timestep = "month", exact = TRUE
    )
  )

  # test with "month" timestep and exact = FALSE
  expect_silent(
    check_timestep(
      obs_monthly,
      date_var = "date", timestep = "month", exact = FALSE
    )
  )

  # Monthly data with some months missing
  obs_monthly_missing <- data.table::as.data.table(obs_monthly)[-c(2, 8), ]

  # test with "month" timestep and exact = TRUE, should fail
  expect_error(
    check_timestep(
      obs_monthly_missing,
      date_var = "date", timestep = "month", exact = TRUE,
      "date does not have the specified timestep of month"
    )
  )

  # test with "month" timestep and exact = FALSE, should still pass
  expect_error(
    check_timestep(
      obs_monthly_missing,
      date_var = "date", timestep = "month", exact = FALSE
    ),
    "Non-sequential dates are not currently supported for monthly data"
  )
})

test_that("check_timestep() handles problematic inputs", {
  # 1. Test with NA or NULL values
  obs_na <- data.frame(
    date = c(as.Date("2020-01-01"), NA, as.Date("2020-01-03"))
  )
  expect_silent(
    check_timestep(obs_na, date_var = "date", timestep = "day", exact = FALSE)
  )
  expect_error(
    check_timestep(obs_na, date_var = "date", timestep = "day", exact = TRUE),
    "date does not have the specified timestep of 1 day\\(s\\)"
  )

  # 2. Test with only one observation
  obs_one <- data.frame(date = as.Date("2020-01-01"))
  expect_error(
    check_timestep(obs_one, date_var = "date", timestep = "day", exact = TRUE),
    "There must be at least two observations"
  )
  expect_silent(
    check_timestep(
      obs_one,
      date_var = "date", timestep = "day", exact = FALSE,
      check_nrow = FALSE
    )
  )

  # 3. Test with non-Date class data
  obs_char <- data.frame(
    date = c("2020-01-01", "2020-01-02", "2020-01-03"),
    stringsAsFactors = FALSE
  )
  expect_error(
    check_timestep(obs_char, date_var = "date", timestep = "day", exact = TRUE),
    "date must be of class Date"
  )

  # 4. Test with duplicate dates
  obs_duplicate <- data.frame(date = rep(as.Date("2020-01-01"), 3))
  expect_error(
    check_timestep(obs_duplicate, date_var = "date", timestep = "day", exact = TRUE),
    "date has a duplicate date. Please remove duplicate dates."
  )

  # 5. Test with non-sequential days when exact is TRUE
  obs_non_sequential <- data.frame(
    date = as.Date(c("2020-01-01", "2020-01-04", "2020-01-05"))
  )
  expect_error(
    check_timestep(obs_non_sequential, date_var = "date", timestep = "day", exact = TRUE),
    "date does not have the specified timestep of 1 day\\(s\\)"
  )
})

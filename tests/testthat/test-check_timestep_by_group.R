test_that("check_timestep_by_group() handles groups correctly", {
  # Create a dataset with a date column and two groups
  obs <- data.table(
    .group = c(rep("A", 5), rep("B", 5)),
    date = as.Date(rep(seq(as.Date("2020-01-01"), by = "day", length.out = 5), 2))
  )

  # Test for correct timestep
  expect_silent(
    check_timestep_by_group(obs, date_var = "date")
  )

  # Introduce a discrepancy by adding a duplicate date for a given group
  obs <- rbind(
    obs,
    data.table(
      .group = "A",
      date = as.Date("2020-01-01")
    )
  )

  expect_error(
    check_timestep_by_group(obs, date_var = "date"),
    "date has a duplicate date. Please remove duplicate dates."
  )

  # Remove the discrepancy and introduce a discrepancy in one of the groups
  obs <- obs[-nrow(obs)]
  new_duplicated <- data.table::copy(obs)
  new_duplicated[1, date := as.Date("2020-12-31")]
  expect_error(
    check_timestep_by_group(new_duplicated, date_var = "date"),
    "date does not have the specified timestep of 1 day(s)",
    fixed = TRUE
  )

  # Test with "week" timestep and exact = TRUE, should fail
  expect_error(
    check_timestep_by_group(obs, date_var = "date", timestep = "week", exact = TRUE),
    "date has a shorter timestep than the specified timestep of 7 day(s)",
    fixed = TRUE
  )

  # Test with "month" timestep and exact = FALSE, should fail
  expect_error(
    check_timestep_by_group(obs, date_var = "date", timestep = "month", exact = FALSE),
    "date has a shorter timestep than the specified timestep of a month"
  )
})

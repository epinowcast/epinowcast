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
    check_timestep(obs, date_var = "date", timestep = "month", exact = TRUE)
  )
  
  # test with "month" timestep and exact = FALSE, should fail
  expect_error(
    check_timestep(obs, date_var = "date", timestep = "month", exact = FALSE)
  )
})

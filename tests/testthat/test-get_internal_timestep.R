test_that("get_internal_timestep() works as expected", {
  # test with "day" timestep
  expect_equal(get_internal_timestep("day"), 1)
  
  # test with "week" timestep
  expect_equal(get_internal_timestep("week"), 7)
  
  # test with "month" timestep
  expect_equal(get_internal_timestep("month"), "month")
  
  # test with numeric whole number timestep
  expect_equal(get_internal_timestep(10), 10)
  
  # test with invalid string timestep
  expect_error(
    get_internal_timestep("invalid"),
    "Invalid timestep. Acceptable string inputs are 'day', 'week',\n'month'."
  )
  
  # test with non-whole number timestep
  expect_error(
    get_internal_timestep(1.5),
    "Invalid timestep. If timestep is a numeric, it should be a whole\nnumber"
  )
})


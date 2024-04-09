# 1. Basic Functionality Test
test_that("date_to_numeric_modulus() works with a basic example", {
  dt <- data.table(
    date_col = as.Date(c("2022-01-01", "2022-01-02", "2022-01-03"))
  )
  result <- date_to_numeric_modulus(dt, "date_col", 2)
  expect_identical(result$date_col_mod, c(0, 1, 0))
})

# 2. Column Names Test
test_that("date_to_numeric_modulus() new modulus column has the correct name", {
  dt <- data.table(date_col = as.Date(c("2022-01-01", "2022-01-02")))
  result <- date_to_numeric_modulus(dt, "date_col", 2)
  expect_true("date_col_mod" %in% names(result))
})

# 3. Correct Modulus Computation Test
test_that("date_to_numeric_modulus() modulus computation is correct", {
  dt <- data.table(date_col = as.Date(c("2022-01-01", "2022-01-05")))
  result <- date_to_numeric_modulus(dt, "date_col", 3)
  expect_identical(result$date_col_mod, c(0, 1))
})

# 4. NA Handling Test
test_that("date_to_numeric_modulus() handles NA values correctly", {
  dt <- data.table(date_col = as.Date(c("2022-01-01", NA, "2022-01-03")))
  result <- date_to_numeric_modulus(dt, "date_col", 2)
  expect_identical(result$date_col_mod, c(0, NA, 0))
})

# 5. Type Check Test
test_that("date_to_numeric_modulus() gives an error with incorrect types", {
  dt <- data.table(not_date_col = c("2022-01-01", "2022-01-02"))
  expect_error(date_to_numeric_modulus(dt, "not_date_col", 2))
})

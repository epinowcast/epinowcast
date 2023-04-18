test_that("check_by works as expected", {
  expect_equal(check_by(mtcars), mtcars)
  expect_equal(check_by(mtcars, by = "cyl"), mtcars)
  expect_equal(check_by(mtcars, by = c("mpg", "cyl")), mtcars)
  expect_error(check_by(mtcars, by = 2))
  expect_error(check_by(mtcars, by = c("fwfw")))
  expect_error(check_by(mtcars, by = c("fwfwfwe", "fwefwe")))
  expect_error(check_by(mtcars, by = c("fwfwfwe", "mpg")))
})
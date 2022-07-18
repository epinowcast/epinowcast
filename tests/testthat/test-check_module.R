test_that("check_module works as expected", {
  expect_error(
    epinowcast:::check_module(
      list(inits = 1)
    )
  )
  expect_error(
    epinowcast:::check_module(
      list(data = 1)
    )
  )
  expect_error(
    epinowcast:::check_module(
      list(data = list())
    ),
    NA
  )
})

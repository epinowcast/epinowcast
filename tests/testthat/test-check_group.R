test_that("check_group works for example data", {
  expect_error(
    check_group(germany_covid19_hosp), NA
  )
})

test_that("check_group fails when reserved variables are present", {
  expect_error(check_group(data.frame(.group = 1)))
  expect_error(check_group(data.frame(.old_group = 1)))
  expect_error(check_group(data.frame(.new_group = 1)))
})

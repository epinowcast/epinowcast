test_that("add_group adds a group as expected", {
  expect_equal(
    epinowcast:::add_group(data.frame(x = 1)),
    data.table::data.table(x = 1, .group = 1)
  )
})

test_that("add_group doesn't add a group when one is present", {
  expect_equal(
    epinowcast:::add_group(data.frame(x = 1, .group = 1)),
    data.frame(x = 1, .group = 1)
  )
})
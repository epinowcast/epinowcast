test_that("add_group adds a group as expected", {
  expect_equal(
    epinowcast:::add_group(data.table::data.table(x = 1)),
    data.table::data.table(x = 1, .group = 1)
  )
})

test_that("add_group doesn't add a group when one is present", {
  expect_equal(
    epinowcast:::add_group(data.table::data.table(x = 1, .group = 4)),
    data.table::data.table(x = 1, .group = 4)
  )
})

test_that("add_group fails when passed a data.frame", {
  expect_error(epinowcast:::add_group(data.frame(x = 1)))
})

test_that("`add_group` maintains the same `data.table` object", {
  dummy <- data.table::data.table(dummy = 1:10)
  dummy_addr <- data.table::address(dummy)
  add_group(dummy)
  expect_equal(dummy_addr, data.table::address(dummy))
  dummy <- add_group(dummy)
  expect_equal(dummy_addr, data.table::address(dummy))
})
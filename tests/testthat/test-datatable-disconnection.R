
test_that("`add_group` maintains the same `data.table` object", {
  dummy <- data.table::data.table(dummy = 1:10)
  dummy_addr <- data.table::address(dummy)
  add_group(dummy)
  expect_equal(dummy_addr, data.table::address(dummy))
  dummy <- add_group(dummy)
  expect_equal(dummy_addr, data.table::address(dummy))
})

test_that("`coerce_dt` gives new `data.table` object", {
  dummy <- data.table::data.table(dummy = 1:10)
  newdt <- coerce_dt(dummy)
  expect_false(data.table::address(newdt) == data.table::address(dummy))
})

test_that("`coerce_dt` gives new `data.table` object, unless asked not to", {
  dummy <- data.table::data.table(dummy = 1:10)
  newdt <- coerce_dt(dummy, new = FALSE)
  expect_true(data.table::address(newdt) == data.table::address(dummy))
})

test_that("`coerce_dt` gives new `data.table` object", {
  dummy <- data.table::data.table(dummy = 1:10)
  newdt <- coerce_dt(dummy)
  expect_false(data.table::address(newdt) == data.table::address(dummy))
})

test_that("`coerce_dt` gives new `data.table` object, unless asked not to", {
  dummy <- data.table::data.table(dummy = 1:10)
  newdt <- coerce_dt(dummy, copy = FALSE)
  expect_true(data.table::address(newdt) == data.table::address(dummy))
})

test_that("`coerce_dt` requires `required_cols`", {
  present <- data.table::data.table(present = 1:10)
  absent <- data.table::data.table(absent = 1:10)
  expect_no_error(coerce_dt(present, required_cols = "present"))
  expect_error(coerce_dt(absent, required_cols = "present"), regexp = "present")
})

test_that("`coerce_dt` forbids `forbidden_cols`", {
  present <- data.table::data.table(present = 1:10)
  absent <- data.table::data.table(absent = 1:10)
  expect_no_error(coerce_dt(absent, forbidden_cols = "present"))
  expect_error(coerce_dt(present, forbidden_cols = "present"), regexp = "present")
})

test_that("`coerce_dt` selects `select`", {
  both <- data.table::data.table(present = 1:10, absent = 1:10)
  present <- coerce_dt(both, select = "present")
  expect_true("present" %in% colnames(present))
  expect_false("absent" %in% colnames(present))
})

test_that("`coerce_dt` ensures a group if asked", {
  dummy <- data.table::data.table(dummy = 1:10)
  cdummy <- coerce_dt(dummy, group = TRUE)
  expect_true(".group" %in% colnames(cdummy))
  expect_true(all(cdummy$.group == 1))
})

test_that("`coerce_dt` ensures a group if asked, but doesn't overwrite one", {
  dummy <- data.table::data.table(dummy = 1:10, .group = 4)
  cdummy <- coerce_dt(dummy, group = TRUE)
  expect_true(".group" %in% colnames(cdummy))
  expect_true(all(cdummy$.group == 4))
})

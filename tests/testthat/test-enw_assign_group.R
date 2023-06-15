test_that("enw_assign_group assigns groups as expected", {
  ref <- data.frame(x = 1:3, y = 1:3)
  refkeyed <- as.data.table(ref, key = "x")
  ref1 <- as.data.table(ref)[, .group := 1]
  ref2 <- as.data.table(ref)[, .group := x]
  expect_equal(
    enw_assign_group(ref),
    data.table::setkeyv(ref1, c(".group"))
  )
  expect_equal(
    enw_assign_group(ref, by = "x"),
    data.table::setkeyv(
      ref2,
      c(".group")
    )
  )
  expect_equal(
    enw_assign_group(refkeyed, by = "x"),
    data.table::setkeyv(
      ref2,
      c(".group", "x")
    )
  )
  expect_error(enw_assign_group(data.frame(x = 1:3, .group = 1)))
})

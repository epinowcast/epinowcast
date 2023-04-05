test_that("enw_assign_group assigns groups as expected", {
  expect_equal(
    enw_assign_group(data.frame(x = 1:3, y = 1:3)),
    data.table::setkeyv(
      data.table::data.table(x = 1:3, y = 1:3, .group = 1),
      c(".group")
    )
  )
  expect_equal(
    enw_assign_group(data.frame(x = 1:3, y = 1:3), by = "x"),
    data.table::setkeyv(
      data.table::data.table(x = 1:3, y = 1:3, .group = 1:3),
      c(".group", "x")
    )
  )
  expect_error(enw_assign_group(data.frame(x = 1:3, .group = 1)))
})
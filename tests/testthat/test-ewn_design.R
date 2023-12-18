test_that("enw_design can make a design matrix", {
  data <- data.frame(
    a = 1:3,
    b = as.character(1:3),
    c = c(1, 1, 2)
  )
  expect_snapshot(enw_design(a ~ b + c, data))
  expect_snapshot(enw_design(a ~ b + c, data, no_contrasts = TRUE))
  expect_snapshot(enw_design(a ~ b + c, data, no_contrasts = c("b")))
  expect_snapshot(enw_design(a ~ c, data, sparse = TRUE))
  expect_snapshot(enw_design(a ~ c, data, sparse = FALSE))
})

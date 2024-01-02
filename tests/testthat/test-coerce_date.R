nongarbage <- c("2020-05-12", "2021-05-12", "2022-05-12")
refresult <- as.IDate(nongarbage)
garbage <- c("2020-50-12", "2020-O5-12")

test_that("coerce_date works for non-garbage in", {
  expect_error(
    coerce_date(nongarbage), NA
  )
  expect_error(
    coerce_date(refresult), NA
  )
  expect_error(
    coerce_date(NULL), NA
  )
  expect_error(
    coerce_date(NULL), NA
  )
  expect_identical(
    coerce_date(NULL),
    data.table::as.IDate(.Date(numeric()))
  )
  coerced <- coerce_date(nongarbage)
  expect_identical(coerced, refresult)
  expect_identical(class(coerced), class(refresult)) # nolint: expect_s3_class
})

test_that("coerce_date errors for garbage in", {
  expect_error(coerce_date(garbage))
})

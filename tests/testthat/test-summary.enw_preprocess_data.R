pobs <- enw_example("preprocessed_observations")

test_that("summary returns correct class", {
  s <- summary(pobs)
  expect_s3_class(s, "summary.enw_preprocess_data")
})

test_that("summary contains $object and $n fields", {
  s <- summary(pobs)
  expect_true("object" %in% names(s))
  expect_true("n" %in% names(s))
  expect_identical(s$object, pobs)
})

test_that("summary default n is 6", {
  s <- summary(pobs)
  expect_identical(s$n, 6)
})

test_that("summary custom n works", {
  s <- summary(pobs, n = 3)
  expect_identical(s$n, 3)
})

test_that("print output contains key strings", {
  s <- summary(pobs)
  out <- capture.output(print(s))
  combined <- paste(out, collapse = "\n")
  expect_match(combined, "summary", fixed = TRUE)
  expect_match(
    combined, format(min(pobs$latest[[1]]$reference_date)),
    fixed = TRUE
  )
  expect_match(
    combined, format(max(pobs$latest[[1]]$reference_date)),
    fixed = TRUE
  )
  expect_match(combined, "Latest observations", fixed = TRUE)
  expect_match(
    combined, "Reporting triangle", fixed = TRUE
  )
})

test_that("print returns invisibly", {
  s <- summary(pobs)
  out <- withr::with_output_sink(
    tempfile(),
    withVisible(print(s))
  )
  expect_false(out$visible)
  expect_identical(out$value, s)
})

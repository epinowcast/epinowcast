test_that("print.enw_preprocess_data returns x invisibly", {
  pobs <- enw_example("preprocessed_observations")
  expect_invisible(out <- print(pobs))
  expect_identical(out, pobs)
})

test_that("print.enw_preprocess_data shows header text", {
  pobs <- enw_example("preprocessed_observations")
  output <- capture.output(print(pobs))
  expect_true(
    any(grepl("Preprocessed nowcast data", output))
  )
})

test_that("print.enw_preprocess_data shows scalar metadata", {
  pobs <- enw_example("preprocessed_observations")
  output <- capture.output(print(pobs))
  expect_true(any(grepl("Groups:", output)))
  expect_true(any(grepl("Timestep:", output)))
  expect_true(any(grepl("Max delay:", output)))
  expect_true(any(grepl("timepoints", output)))
  expect_true(any(grepl("snapshots", output)))
  expect_true(any(grepl("Max date:", output)))
})

test_that("print.enw_preprocess_data shows dataset names", {
  pobs <- enw_example("preprocessed_observations")
  output <- capture.output(print(pobs))
  expect_true(any(grepl("Datasets", output)))
  expect_true(any(grepl("obs", output)))
  expect_true(any(grepl("new_confirm", output)))
  expect_true(any(grepl("reporting_triangle", output)))
})

test_that("print.enw_preprocess_data shows grouping vars", {
  pobs <- enw_example("preprocessed_observations")
  pobs$by <- list(c("age_group", "location"))
  pobs$groups <- 3L
  output <- capture.output(print(pobs))
  expect_true(any(grepl("Groups: 3", output)))
  expect_true(any(grepl("age_group", output)))
  expect_true(any(grepl("location", output)))
})

test_that("print.epinowcast returns x invisibly", {
  nowcast <- enw_example("nowcast")
  expect_invisible(out <- print(nowcast))
  expect_identical(out, nowcast)
})

test_that("print.epinowcast shows header text", {
  nowcast <- enw_example("nowcast")
  output <- capture.output(print(nowcast))
  expect_true(
    any(grepl("epinowcast model output", output))
  )
})

test_that("print.epinowcast shows priors info", {
  nowcast <- enw_example("nowcast")
  output <- capture.output(print(nowcast))
  expect_true(any(grepl("Priors:", output)))
  expect_true(any(grepl("parameters", output)))
})

test_that("print.epinowcast shows diagnostics info", {
  nowcast <- enw_example("nowcast")
  output <- capture.output(print(nowcast))
  expect_true(any(grepl("Model fit:", output)))
  expect_true(any(grepl("Samples:", output)))
  expect_true(any(grepl("Max Rhat:", output)))
  expect_true(any(grepl("Divergent transitions:", output)))
  expect_true(any(grepl("Run time:", output)))
})

test_that("print.epinowcast shows priors table", {
  nowcast <- enw_example("nowcast")
  output <- capture.output(print(nowcast))
  expect_true(any(grepl("variable", output)))
  expect_true(any(grepl("distribution", output)))
  expect_true(any(grepl("Normal", output)))
})

test_that("print.epinowcast handles missing diagnostics", {
  nowcast <- enw_example("nowcast")
  nowcast[, max_rhat := NULL]
  nowcast[, samples := NULL]
  nowcast[, divergent_transitions := NULL]
  nowcast[, per_divergent_transitions := NULL]
  output <- capture.output(print(nowcast))
  expect_true(
    any(grepl("epinowcast model output", output))
  )
  expect_false(any(grepl("Max Rhat:", output)))
  expect_false(any(grepl("Samples:", output)))
})

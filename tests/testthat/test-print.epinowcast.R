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

test_that("print.epinowcast shows model objects", {
  nowcast <- enw_example("nowcast")
  output <- capture.output(print(nowcast))
  expect_true(any(grepl("Model objects", output)))
  expect_true(any(grepl("priors", output)))
  expect_true(any(grepl("fit", output)))
  expect_true(any(grepl("data", output)))
  expect_true(any(grepl("fit_args", output)))
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

test_that("print.epinowcast shows max treedepth", {
  nowcast <- enw_example("nowcast")
  output <- capture.output(print(nowcast))
  expect_true(any(grepl("Max treedepth:", output)))
  expect_true(any(grepl("at max", output)))
})

test_that("print.epinowcast shows runtime only when MCMC missing", {
  nowcast <- enw_example("nowcast")
  nowcast[, max_rhat := NULL]
  nowcast[, samples := NULL]
  nowcast[, divergent_transitions := NULL]
  nowcast[, per_divergent_transitions := NULL]
  nowcast[, max_treedepth := NULL]
  nowcast[, no_at_max_treedepth := NULL]
  nowcast[, per_at_max_treedepth := NULL]
  output <- capture.output(print(nowcast))
  expect_true(any(grepl("Model fit:", output)))
  expect_true(any(grepl("Run time:", output)))
  expect_false(any(grepl("Max Rhat:", output)))
  expect_false(any(grepl("Samples:", output)))
  expect_false(any(grepl("Max treedepth:", output)))
})

test_that("print.epinowcast hides fit section when all diag missing", {
  nowcast <- enw_example("nowcast")
  nowcast[, max_rhat := NULL]
  nowcast[, samples := NULL]
  nowcast[, divergent_transitions := NULL]
  nowcast[, per_divergent_transitions := NULL]
  nowcast[, max_treedepth := NULL]
  nowcast[, no_at_max_treedepth := NULL]
  nowcast[, per_at_max_treedepth := NULL]
  nowcast[, run_time := NULL]
  output <- capture.output(print(nowcast))
  expect_true(
    any(grepl("epinowcast model output", output))
  )
  expect_false(any(grepl("Model fit:", output)))
})

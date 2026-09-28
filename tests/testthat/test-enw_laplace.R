# Fake `CmdStanModel`-like objects so the validation branches in
# `enw_laplace()` can be exercised without compiling or fitting a real
# CmdStan model.
.fake_laplace_model <- function(draws, time_total = 1.23,
                                 capture_args = NULL) {
  laplace_fn <- function(data, ...) {
    if (!is.null(capture_args)) {
      assign("args", list(data = data, ...), envir = capture_args)
    }
    if (is.function(draws)) {
      draws_fn <- draws
    } else {
      draws_fn <- function() draws
    }
    list(
      draws = draws_fn,
      time = function() list(total = time_total)
    )
  }
  list(laplace = laplace_fn)
}

test_that("enw_laplace errors when the laplace method is unavailable", {
  expect_error(
    enw_laplace(data = list(), model = list(laplace = NULL)),
    "CmdStan"
  )
})

test_that("enw_laplace errors with guidance when draws cannot be retrieved", {
  model <- .fake_laplace_model(
    draws = function() stop("cmdstanr internal failure")
  )
  expect_error(
    enw_laplace(data = list(), model = model),
    "failed to produce usable draws"
  )
})

test_that("enw_laplace errors with guidance when draws contain NaN", {
  model <- .fake_laplace_model(draws = matrix(c(1, NaN, 2, 3), nrow = 2))
  expect_error(
    enw_laplace(data = list(), model = model),
    "produced `NaN` draws"
  )
})

test_that("enw_laplace does not flag structural (non-NaN) Inf as an error", {
  model <- .fake_laplace_model(draws = matrix(c(1, -Inf, 2, 3), nrow = 2))
  expect_error(enw_laplace(data = list(), model = model), NA)
})

test_that("enw_laplace renames threads_per_chain to threads for laplace()", {
  captured <- new.env()
  model <- .fake_laplace_model(
    draws = matrix(c(1, 2), nrow = 1),
    capture_args = captured
  )
  enw_laplace(
    data = list(), model = model, threads_per_chain = 2, init = 0.1
  )
  expect_identical(captured$args$threads, 2)
  expect_null(captured$args$threads_per_chain)
  expect_identical(captured$args$init, 0.1)
})

test_that("enw_laplace returns a data.table with run_time by default", {
  model <- .fake_laplace_model(
    draws = matrix(c(1, 2), nrow = 1), time_total = 4.56
  )
  out <- enw_laplace(data = list(a = 1), model = model)
  expect_s3_class(out, "data.table")
  expect_identical(out$run_time, 4.6)
})

test_that("enw_laplace omits run_time when diagnostics is FALSE", {
  model <- .fake_laplace_model(draws = matrix(c(1, 2), nrow = 1))
  out <- enw_laplace(
    data = list(a = 1), model = model, diagnostics = FALSE
  )
  expect_false("run_time" %in% names(out))
})

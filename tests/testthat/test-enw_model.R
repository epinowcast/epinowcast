test_that("enw_model can compile the default model", {
  skip_on_cran()
  skip_on_local()
  expect_error(enw_model(), NA)
})

test_that("enw_model can compile the multi-threaded model", {
  skip_on_cran()
  skip_on_local()
  expect_error(enw_model(threads = TRUE), NA)
})

test_that("enw_model can compile using profiling", {
  skip_on_cran()
  skip_on_local()
  expect_error(enw_model(profile = TRUE), NA)
})

test_that("enw_model can return stan code without compiling", {
  skip_on_cran()
  skip_on_local()
  expect_error(enw_model(compile = FALSE), NA)
  expect_error(enw_model(compile = FALSE, verbose = FALSE), NA)
})

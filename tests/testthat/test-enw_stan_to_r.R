# Define a simple Stan function for testing
stan_function_code <- "
  real test_function(real x) {
    return x * x;
  }
"

test_that("enw_stan_to_r() exposes Stan functions from test_functions.stan", {
  skip_on_local()
  skip_on_cran()
  temp_dir <- tempdir()
  temp_stan_file_path <- file.path(temp_dir, "test_functions.stan")
  writeLines(stan_function_code, temp_stan_file_path)

  exposed_functions <- suppressMessages(suppressWarnings(enw_stan_to_r(
    files = "test_functions.stan", include = temp_dir,
    force_recompile = TRUE, verbose = FALSE, global = FALSE
  )))
  test_result <- exposed_functions$functions$test_function(2)
  expect_identical(exposed_functions$functions$test_function(2), 4)

  unlink(temp_stan_file_path)
  rm("test_function")
})

test_that("enw_stan_to_r() handles an invalid file", {
  expect_error(
    enw_stan_to_r(
      files = "nonexistent_file.stan", include = tempdir(), verbose = FALSE
    ),
    "The following files are not in the include directory"
  )
})

test_that("enw_stan_to_r() handles an invalid file path", {
  expect_error(
    enw_stan_to_r(
      files = "other_function.stan", include = tempdir(), verbose = FALSE
    ),
    "The following files are not in the include directory"
  )
})

test_that("enw_stan_to_r() warns for overloaded functions", {
  temp_overloaded_stan_file_path <- file.path(tempdir(), "delay_lpmf.stan")
  writeLines(stan_function_code, temp_overloaded_stan_file_path)
  expect_error(
    expect_warning(
      enw_stan_to_r(
        files = "delay_lpmf.stan", include = tempdir(), verbose = FALSE
      ),
      "The following functions are overloaded and cannot be exposed"
    ),
    "No non-overloaded files specified. Please specify files to expose"
  )
  unlink(temp_overloaded_stan_file_path)
})

test_that("enw_stan_to_r() handles empty or NULL file input", {
  expect_error(
    enw_stan_to_r(
      files = NULL, include = tempdir(), verbose = FALSE
    ),
    "No non-overloaded files specified. Please specify files to expose"
  )

  expect_error(
    enw_stan_to_r(
      files = character(0), include = tempdir(), verbose = FALSE
    ),
    "No non-overloaded files specified. Please specify files to expose"
  )
})

test_that("enw_stan_to_r() global exposure flag functionality", {
  skip_on_local()
  skip_on_cran()
  temp_stan_file_path <- file.path(tempdir(), "test_global_exposure.stan")
  writeLines(stan_function_code, temp_stan_file_path)

  exposed_functions <- suppressMessages(suppressWarnings(enw_stan_to_r(
    files = "test_global_exposure.stan",
    include = tempdir(),
    global = FALSE,
    force_recompile = TRUE,
    verbose = FALSE
  )))
  expect_false(exists("test_function"))

  unlink(temp_stan_file_path)
  rm("test_function")
})

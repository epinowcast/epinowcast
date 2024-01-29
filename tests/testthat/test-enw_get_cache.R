test_that("enw_get_cache() can retrieve the enw_cache_location as expected", {
  suppressMessages(withr::with_envvar(new = c(enw_cache_location = "models"),
    expect_identical(
        basename(enw_get_cache()),
        "models"
    )
  ))

  suppressMessages(withr::with_envvar(new = c(enw_cache_location = ""),
    expect_identical(
      enw_get_cache(),
      tempdir()
    )
  ))
})

enw_model_time <- function() {
  time_start <- Sys.time()
  suppressMessages(enw_model(verbose = FALSE))
  time_out <- Sys.time()
  difftime(time_out, time_start, units = "secs")[[1]]
}

test_that("enw_model() can access enw_cache_location", {
  skip_on_cran()
  skip_on_local()
  withr::with_tempdir(
    withr::with_envvar(
      new = c(enw_cache_location = "test"), {
        run_initial <- enw_model_time()
        run_secondary <- enw_model_time()
        expect_lt(run_secondary, run_initial)
      }
    )
  )
})

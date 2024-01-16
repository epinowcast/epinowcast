persistent_tempdir <- file.path(tempdir(), "enw_set_cache")
test_model_cache <- function() {
    withr::with_envvar(
        new = c(enw_cache_location = persistent_tempdir), {
            time_start <- Sys.time()
            suppressMessages(enw_model(verbose = FALSE))
            time_out <- Sys.time()
            difftime(time_out, time_start, units = "secs")[[1]]
        }
    )
}

test_that("enw_model can access enw_cache_location", {
    skip_on_cran()
    run_initial <- test_model_cache()
    run_secondary <- test_model_cache()
    expect_lt(run_secondary, run_initial)
})

cli::test_that_cli("alert", {
    skip_on_cran()
    local_edition(3)
    current_cache <- enw_get_cache()
    testthat::expect_snapshot({
    withr::with_envvar(
        new = c(enw_cache_location = "initial_location"), {
            enw_set_cache("second_location")
        })
    })
    enw_set_cache(current_cache)
})

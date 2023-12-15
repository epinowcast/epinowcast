
persistent_tempdir <- tempdir()
devtools::load_all()
test_model_cache <- function(){
    withr::with_envvar(
        new = c(enw_cache_location = persistent_tempdir), {
            time_start <- Sys.time()
            enw_model()
            time_out <- Sys.time()
            difftime(time_out, time_start, units = "secs")[[1]]
        }
    )
}



test_that("enw_model can access enw_cache_location", {
    skip_on_cran()
    run_inital <- test_model_cache()
    run_secondary <- test_model_cache()
    expect_true(run_secondary < run_inital)
})

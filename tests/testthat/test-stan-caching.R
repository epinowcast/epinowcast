test_that("enw_get_cache can retrieve the enw_cache_location as expected", {
    Sys.setenv(enw_cache_location = "models")
    expect_equal(
        basename(enw_get_cache()), 
        "models"
    )
    Sys.unsetenv("enw_cache_location")

    expect_equal(
        get_enw_cache(), 
        tempdir()
    )
})

test_that("enw_set_cache can set the enw_cache_location as expected", {
    expect_error(enw_set_cache())

     Sys.unsetenv("enw_cache_location")
    expect_equal(enw_set_cache("test"), enw_get_cache())
    enw_unset_cache()
})

test_that("enw_unset_cache can unset the cache directory", {
    Sys.setenv(enw_cache_location = "models")
    enw_unset_cache()
    expect_equal(Sys.getenv("enw_cache_location"), "")
})

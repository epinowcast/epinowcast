test_that("enw_get_cache can retrieve the enw_cache_location as expected", {
    withr::with_envvar(new = c(enw_cache_location = "models"), 
    expect_equal(
        basename(enw_get_cache()), 
        "models"
    )
    )

    withr::with_envvar( new = c(enw_cache_location = ""),
    expect_equal(
        enw_get_cache(), 
        tempdir()
    )
    )
})

test_that("enw_set_cache can set the enw_cache_location as expected", {
    expect_error(enw_set_cache())

    withr::with_envvar(c(enw_cache_location = ""),{
        expect_equal(enw_set_cache("test"), enw_get_cache())
    })
    
})

test_that("enw_unset_cache can unset the cache directory", {
    status <- withr::with_envvar(new = c(enw_cache_location = "models"), {
      enw_unset_cache()
      Sys.getenv("enw_cache_location")
    })
    expect_equal(status,  "")
})
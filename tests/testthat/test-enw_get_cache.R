test_that("enw_get_cache can retrieve the enw_cache_location as expected", {
   withr::with_envvar(new = c(enw_cache_location = "models"),
    expect_identical(
        basename(enw_get_cache()),
        "models"
    )
    )

    withr::with_envvar(new = c(enw_cache_location = ""),
      expect_identical(
        enw_get_cache(),
        tempdir()
      )
    )
})

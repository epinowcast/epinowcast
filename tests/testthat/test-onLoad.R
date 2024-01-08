test_that("onLoad alerts user of enw_cache_location", {
    expect_equal(enw_startup_message(),
      "`enw_cache_location` is not set it. Set it using `enw_set_cache` to reduce future Stan compilation times"
    )
})

test_that(".onLoad alerts user of enw_cache_location", {

    with_envvar(new = c(enw_cache_location = "models"),
      expect_equal(
        enw_startup_message(),
        "Using `models` for the epinowcast model cache location."
      )
    )
})

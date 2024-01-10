test_that("onLoad alerts user of enw_cache_location", {
    with_envvar(new = c(enw_cache_location = ""), {
    expect_length(length(enw_startup_message()),
      3L
    )
    })
})

test_that(".onLoad alerts user of enw_cache_location", {

    with_envvar(new = c(enw_cache_location = "models"),
      expect_identical(
        enw_startup_message(),
        "Using `models` for the epinowcast model cache location."
      )
    )
})

test_that("enw_unset_cache can unset the cache directory", {
  suppressMessages(withr::with_envvar(new = c(enw_cache_location = "models"), {
    enw_unset_cache()
    status <- Sys.getenv("enw_cache_location")
  }))
  expect_identical(status,  "")
})

test_that("enw_unset_cache detects when the cache directory is not set", {
  suppressMessages(withr::with_envvar(new = c(enw_cache_location = ""), {
    enw_unset_cache()
    status <- Sys.getenv("enw_cache_location")
  })
  )
  expect_identical(status,  "")
})

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

test_that("enw_unset_cache() can unset the session cache directory", {
  suppressMessages(withr::with_envvar(c(enw_cache_location = "models"), {
    enw_unset_cache(type = "session")
    status <- Sys.getenv("enw_cache_location")
    expect_identical(status, "")
  }))
})

test_that("enw_unset_cache() can unset the persistent cache directory", {
  suppressMessages(withr::with_dir(
    tempdir(), {
    file.create(".Renviron")
    enw_set_cache(".", type = "persistent")
    enw_unset_cache(type = "persistent")
    expect_false(
      any(grepl("enw_cache_location", readLines(".Renviron")))
    )
  }))
})

test_that("enw_unset_cache can unset both the session and persistent cache directories", { # nolint
  withr::with_envvar(c(enw_cache_location = "models"), {
    suppressMessages(withr::with_dir(
      tempdir(), {
      file.create(".Renviron")
      enw_set_cache(".", type = "persistent")
      enw_unset_cache(type = "all")
      expect_false(
        any(grepl("enw_cache_location", readLines(".Renviron")))
      )
      expect_identical(Sys.getenv("enw_cache_location"), "")
    }))
  })
  if (file.exists("~/.Renviron")) {
    readRenviron("~/.Renviron")
  }
})

# Test handling unset cache
test_that("enw_unset_cache detects when the cache directory is not set", {
  suppressMessages(withr::with_envvar(c(enw_cache_location = ""), {
    enw_unset_cache(type = "session")
    status <- Sys.getenv("enw_cache_location")
    expect_identical(status, "")
  }))
})

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
      any(grepl("enw_cache_location", readLines(".Renviron"), fixed = TRUE))
    )
  }))
})

test_that("enw_unset_cache can unset both the session and persistent cache directories", { # nolint
  env_location <- Sys.getenv("HOME")
  env_path <- file.path(env_location, ".Renviron")
  withr::with_envvar(c(enw_cache_location = "models"), {
    suppressMessages(withr::with_dir(
      tempdir(), {
      file.create(".Renviron")
      enw_set_cache(".", type = "persistent")
      enw_unset_cache(type = "all")
      expect_false(
        any(grepl("enw_cache_location", readLines(".Renviron"), fixed = TRUE))
      )
      expect_identical(Sys.getenv("enw_cache_location"), "")
    }))
  })
  if (file.exists(env_path)) {
    readRenviron(env_path)
  }
})

test_that("enw_unset_cache detects when the cache directory is not set", {
  current_cache <- suppressMessages(enw_get_cache())
  suppressMessages(withr::with_envvar(c(enw_cache_location = ""), {
    enw_unset_cache(type = "session")
    status <- Sys.getenv("enw_cache_location")
    expect_identical(status, "")
  }))
   suppressMessages(enw_set_cache(current_cache, type = "session"))
})

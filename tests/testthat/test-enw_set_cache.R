test_that("enw_set_cache() can set the session cache directory", {
  current_cache <- suppressMessages(enw_get_cache())
  suppressMessages(withr::with_envvar(c(enw_cache_location = ""), {
    path <- file.path(tempdir(), "test_session_cache")
    enw_set_cache(path, type = "session")
    status <- Sys.getenv("enw_cache_location")
    expect_identical(status, suppressWarnings(normalizePath(path)))
  }))
  suppressMessages(enw_set_cache(current_cache, type = "session"))
})

test_that("enw_set_cache() can set the persistent cache directory", {
  suppressMessages(withr::with_dir(
    tempdir(), {
      withr::with_envvar(c(enw_cache_location = "testy"), {
        file.create(".Renviron")
        path <- file.path(tempdir(), "test_persistent_cache")
        enw_set_cache(path, type = "persistent")
        env_contents <- readLines(".Renviron")
        expect_true(
          any(grepl(
            paste0("enw_cache_location=\"",
            suppressWarnings(normalizePath(path)), "\""),
            env_contents, fixed = TRUE
          ))
        )
        # Test that appending doesn't lead to duplicate entries
        enw_set_cache(path, type = "persistent")
        env_contents <- readLines(".Renviron")
        expect_equal(
          sum(any(grepl(
              paste0("enw_cache_location=\"",
              suppressWarnings(normalizePath(path)), "\""),
              env_contents, fixed = TRUE
          ))),
          1
        )
        status <- Sys.getenv("enw_cache_location")
        expect_identical(status, "testy")
      })
  }))
})

test_that("enw_set_cache() can set both the session and persistent cache directories", { # nolint
  current_cache <- suppressMessages(enw_get_cache())
  suppressMessages(withr::with_dir(
    tempdir(), {
      file.create(".Renviron")
      path <- file.path(tempdir(), "test_persistent_cache")
      enw_set_cache(path, type = "all")
      env_contents <- readLines(".Renviron")
      expect_true(
        any(grepl(
            paste0("enw_cache_location=\"",
            suppressWarnings(normalizePath(path)), "\""),
            env_contents, fixed = TRUE
        ))
      )
    status <- Sys.getenv("enw_cache_location")
    expect_identical(status, suppressWarnings(normalizePath(path)))
    }
  ))
  suppressMessages(enw_set_cache(current_cache, type = "session"))
})

test_that("enw_set_cache() fails as expected with incorrect input", {
  expect_error(enw_set_cache(NULL))
  expect_error(enw_set_cache(1))
})

cli::test_that_cli("alert", {
  skip_on_cran()
  skip_on_os("windows")
  skip_on_os("mac")
  local_edition(3)
  current_cache <- suppressMessages(enw_get_cache())
  expect_snapshot({
    withr::with_tempdir(
      withr::with_envvar(
        new = c(enw_cache_location = "initial_location"), {
          enw_set_cache("second_location", type = "session")
      })
    )
  })
  suppressMessages(enw_set_cache(current_cache, type = "session"))
})

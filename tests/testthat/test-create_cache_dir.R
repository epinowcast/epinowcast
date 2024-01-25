test_that("create_cache_dir() creates a new directory if it does not exist", {
  withr::with_tempdir({
    path <- "new_cache_dir"
    expect_false(dir.exists(path))
    suppressMessages(create_cache_dir(path))
    expect_true(dir.exists(path))
  })
})

test_that(
  "create_cache_dir() does not create a directory if it already exists", {
  withr::with_tempdir({
    path <- "existing_cache_dir"
    dir.create(path)
    expect_true(dir.exists(path))
    suppressMessages(create_cache_dir(path))
  })
})

test_that(
  "create_cache_dir() fails as expected on Windows when the path is invalid", {
  skip_on_os("linux")
  skip_on_os("mac")

  invalid_windows_path <- "C:::\\Invalid\\*Path"

  # Expecting an error due to invalid Windows path format
  expect_error(
    create_cache_dir(invalid_windows_path)
  )
})

test_that(
  "create_cache_dir() fails on Unix when attempting to create a directory where a file exists", { # nolint
  skip_on_os("windows")

  withr::with_tempdir({
    dummy_file <- "dummy_file"
    file.create(dummy_file)
    expect_true(file.exists(dummy_file))
    invalid_unix_path <- dummy_file

    expect_error(
      create_cache_dir(invalid_unix_path)
    )
  })
})

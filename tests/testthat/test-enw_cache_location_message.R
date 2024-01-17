test_that(
  "enw_cache_location_message() returns correct message when 'enw_cache_location' is not set", # nolint: line_length
{
  withr::with_envvar(
    new = c(enw_cache_location = NA), {
    message <- enw_cache_location_message()
    expect_length(message, 5L)
    expect_named(message, c("!", "i", "i", "i", "i"))
    expect_true(grepl("enw_cache_location", message["!"], fixed = TRUE))
    expect_true(grepl("enw_set_cache", message[3], fixed = TRUE))
  })
})

# Test when 'enw_cache_location' is set
test_that(
  "enw_cache_location_message() returns correct message when 'enw_cache_location' is set", # nolint: line_length
{
  test_path_location <- file.path("test", "path", "to", "cache")
  withr::with_envvar(
    new = c(enw_cache_location =  test_path_location), {
    message <- enw_cache_location_message()
    expect_length(message, 1L)
    expect_true(grepl(test_path_location, message, fixed = TRUE))
  })
})

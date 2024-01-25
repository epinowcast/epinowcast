# alert [plain]

    Code
      withr::with_tempdir(withr::with_envvar(new = c(enw_cache_location = "initial_location"),
      {
        enw_set_cache("second_location", type = "session")
      }))
    Message
      v Created cache directory at second_location
      ! Environment variable `enw_cache_location` exists and will be overwritten
      v Set `enw_cache_location` to second_location

# alert [ansi]

    Code
      withr::with_tempdir(withr::with_envvar(new = c(enw_cache_location = "initial_location"),
      {
        enw_set_cache("second_location", type = "session")
      }))
    Message
      [32mv[39m Created cache directory at second_location
      [33m![39m Environment variable `enw_cache_location` exists and will be overwritten
      [32mv[39m Set `enw_cache_location` to second_location

# alert [unicode]

    Code
      withr::with_tempdir(withr::with_envvar(new = c(enw_cache_location = "initial_location"),
      {
        enw_set_cache("second_location", type = "session")
      }))
    Message
      ✔ Created cache directory at second_location
      ! Environment variable `enw_cache_location` exists and will be overwritten
      ✔ Set `enw_cache_location` to second_location

# alert [fancy]

    Code
      withr::with_tempdir(withr::with_envvar(new = c(enw_cache_location = "initial_location"),
      {
        enw_set_cache("second_location", type = "session")
      }))
    Message
      [32m✔[39m Created cache directory at second_location
      [33m![39m Environment variable `enw_cache_location` exists and will be overwritten
      [32m✔[39m Set `enw_cache_location` to second_location


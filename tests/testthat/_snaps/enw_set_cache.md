# alert [plain]

    Code
      withr::with_envvar(new = c(enw_cache_location = "initial_location"), {
        enw_set_cache("second_location", type = "session")
      })
    Message
      ! initial_location exists and will be overwritten
      v Set `enw_cache_location` to second_location

# alert [ansi]

    Code
      withr::with_envvar(new = c(enw_cache_location = "initial_location"), {
        enw_set_cache("second_location", type = "session")
      })
    Message
      [33m![39m initial_location exists and will be overwritten
      [32mv[39m Set `enw_cache_location` to second_location

# alert [unicode]

    Code
      withr::with_envvar(new = c(enw_cache_location = "initial_location"), {
        enw_set_cache("second_location", type = "session")
      })
    Message
      ! initial_location exists and will be overwritten
      ✔ Set `enw_cache_location` to second_location

# alert [fancy]

    Code
      withr::with_envvar(new = c(enw_cache_location = "initial_location"), {
        enw_set_cache("second_location", type = "session")
      })
    Message
      [33m![39m initial_location exists and will be overwritten
      [32m✔[39m Set `enw_cache_location` to second_location


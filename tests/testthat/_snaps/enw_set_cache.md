# alert [plain]

    Code
      withr::with_envvar(new = c(enw_cache_location = "initial_location"), {
        enw_set_cache("second_location")
      })
    Message
      i Setting `enw_cache_location` to second_location
      > initial_location exists and will be overwritten

# alert [ansi]

    Code
      withr::with_envvar(new = c(enw_cache_location = "initial_location"), {
        enw_set_cache("second_location")
      })
    Message
      [1m[22m[36mi[39m Setting `enw_cache_location` to second_location
      > initial_location exists and will be overwritten

# alert [unicode]

    Code
      withr::with_envvar(new = c(enw_cache_location = "initial_location"), {
        enw_set_cache("second_location")
      })
    Message
      ℹ Setting `enw_cache_location` to second_location
      → initial_location exists and will be overwritten

# alert [fancy]

    Code
      withr::with_envvar(new = c(enw_cache_location = "initial_location"), {
        enw_set_cache("second_location")
      })
    Message
      [1m[22m[36mℹ[39m Setting `enw_cache_location` to second_location
      → initial_location exists and will be overwritten


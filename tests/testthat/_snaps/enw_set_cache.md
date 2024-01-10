# alert [plain]

    Code
      with_envvar(new = c(enw_cache_location = "initial_location"), {
        enw_set_cache("second_location")
      })
    Message
      > initial_location exists and will be overwritten

# alert [ansi]

    Code
      with_envvar(new = c(enw_cache_location = "initial_location"), {
        enw_set_cache("second_location")
      })
    Message
      > initial_location exists and will be overwritten


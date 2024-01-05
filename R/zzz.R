.onLoad <- function(...) {
    packageStartupMessage(enw_startup_message())
    return(invisible())
}

enw_startup_message <- function(){
    cache_location <- Sys.getenv("enw_cache_location")
    if (epinowcast:::check_environment_setting(cache_location)) {
        msg <- cli_inform("`enw_cache_location` is not set it. Set it using `enw_set_cache` to reduce future Stan compilation times")
    } else {
        msg <- cli_inform("Using `{cache_location}` for the epinowcast model cache location.")
    }

    return(msg)
}

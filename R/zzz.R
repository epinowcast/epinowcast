.onLoad <- function(...) {
    packageStartupMessage(enw_startup_message())
    return(invisible())
}

enw_startup_message <- function(){
    cache_location <- Sys.getenv("enw_cache_location")
    if (check_environment_setting) {
        cli_inform("`enw_cache_location` is not set it. Set it using `enw_set_cache` to reduce future Stan compilation times")
    } else {
        cli_inform("Using `{cache_location}` for the epinowcast model cache location.")
    }
}

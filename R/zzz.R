# Using this approach from the cli package on startup messages.

## nocov start

.onLoad <- function(libname, pkgname) {
    packageStartupMessage(cli_inform(enw_startup_message()))
}

enw_startup_message <- function(){
    cache_location <- Sys.getenv("enw_cache_location")
    if (check_environment_setting(cache_location)) {
        msg <- "`enw_cache_location` is not set it. Set it using `enw_set_cache` to reduce future Stan compilation times"
    } else {
        msg <- sprintf("Using `%s` for the epinowcast model cache location.", cache_location)
    }

    return(msg)
}

## nocov end
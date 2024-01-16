# nocov start
.onAttach <- function(libname, pkgname) {
    cli::cli_inform(
        enw_startup_message(),
        .frequency = "once",
        .frequency_id = "enw_startup_message",
        class = "packageStartupMessage"
    )
}
# nocov end

enw_startup_message <- function() {
    cache_location <- Sys.getenv("enw_cache_location")
    if (check_environment_setting(cache_location)) {
    # nolint start
        msg <- c(
            "!" = "`enw_cache_location` is not set. Set it using `enw_set_cache`
            to reduce future Stan compilation times.",
            "i" = "For example: `enw_set_cache(tools::R_user_dir(package =
            \"epinowcast\", \"cache\"))`.",
            "i" = "See `?enw_set_cache` for details."
        )
    # nolint end 
    } else {
        msg <- c(
            "i" = sprintf(
                "Using `%s` for the epinowcast model cache location.", # nolint line_length
                cache_location
            )
        )
    }

    return(msg)
}

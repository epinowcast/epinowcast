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

#' Startup message for epinowcast package
#'
#' This function generates a startup message for the [epinowcast()] package.
#' It checks the environment setting for the cache location and provides
#' appropriate guidance to the user based on the setting.
#'
#' @details `enw_startup_message` checks if the `enw_cache_location`
#' environment variable is set. If it is not set, the function advises the
#' user to set this variable using the `enw_set_cache` function. This helps in
#' reducing future Stan compilation times. If the `enw_cache_location` is set,
#' the function confirms the current cache location to the user.
#' `enw_cache_location` can be set using [enw_set_cache()].
#'
#' @return A character vector containing messages. If `enw_cache_location` is
#' not set, the function returns instructions on how to set it and where to
#' find more details. If it is set, it returns a confirmation message of the
#' current cache location.
#'
#'
#' @keywords internal
enw_startup_message <- function() {
    cache_location <- Sys.getenv("enw_cache_location")
    if (check_environment_setting(cache_location)) {
    # nolint start
        msg <- c(
            "!" = "`enw_cache_location` is not set. Set it using `enw_set_cache`
            to reduce future Stan compilation times.",
            i = "For example: `enw_set_cache(tools::R_user_dir(package =
            \"epinowcast\", \"cache\"), persistent = TRUE)`.",
            i = "See `?enw_set_cache` for details."
        )
    # nolint end 
    } else {
        msg <- c(
            i = sprintf(
                "Using `%s` for the epinowcast model cache location.", # nolint line_length
                cache_location
            )
        )
    }

    return(msg)
}

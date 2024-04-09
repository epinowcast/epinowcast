# nocov start
.onAttach <- function(libname, pkgname) {
    cli::cli_inform(
        cache_location_message(),
        .frequency = "once",
        .frequency_id = "enw_startup_message",
        class = "packageStartupMessage"
    )
}
# nocov end

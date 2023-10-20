# This helper ensures the package does not modify the session global state. As
# per CRAN policy, packages should not interfere with the user's session state.
# If global settings need to be modified, they should be restored to their
# original values on exit. This can be achieved with the `on.exit()` base
# function, or more conveniently with the `withr` package.
testthat::set_state_inspector(function() {
  list(
    attached    = search(),
    connections = getAllConnections(),
    cwd         = getwd(),
    envvars     = Sys.getenv(),
    handlers    = globalCallingHandlers(),
    libpaths    = .libPaths(),
    locale      = Sys.getlocale(),
    options     = options(),
    par         = par(),
    packages    = .packages(all.available = TRUE),
    sink        = sink.number(),
    timezone    = Sys.timezone(),
    NULL
  )
})

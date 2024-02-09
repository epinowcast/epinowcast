# This helper ensures the package does not modify the session global state. As
# per CRAN policy, packages should not interfere with the user's session state.
# If global settings need to be modified, they should be restored to their
# original values on exit. This can be achieved with the `on.exit()` base
# function, or more conveniently with the `withr` package.
# Note that `globalCallingHandlers` is only available on version of R >= 4.0

testthat::set_state_inspector(function() {
  list(
    attached    = search(),
    connections = getAllConnections(),
    cwd         = getwd(),
    # cmdstanr sets `STAN_NUM_THREADS` based on the value of `threads_per_chain`
    # https://github.com/stan-dev/cmdstanr/blob/bc60419a4d357eb531a2f755ceb7bc0e3651fb76/R/run.R#L375
    #    envvars     = Sys.getenv(),
    handlers    = if (getRversion() >= "4.0.0") {
        globalCallingHandlers()
      } else {
        Sys.getenv("error")
      },
    libpaths    = .libPaths(),
    locale      = Sys.getlocale(),
    # Extra options related to matrixStats are set on macOS. See issue #439.
    #    options     = options(),
    par         = par(),
    packages    = .packages(all.available = TRUE),
    sink        = sink.number(),
    timezone    = Sys.timezone(),
    NULL
  )
})

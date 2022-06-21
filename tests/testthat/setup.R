if (not_on_cran()) {
  message("Running tests setup")
  options(mc.cores = 2)
  utils::capture.output(
    source(enw_example("script"))
  )
}

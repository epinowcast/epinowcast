if (not_on_cran()) {
  message("Running tests setup")
  options(mc.cores = 2)
  utils::capture.output(
    source("inst/scripts/germany_example.R")
  )
}

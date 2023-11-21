# Precompiled vignettes with long run times
library(knitr)

.args <- commandArgs(trailingOnly = TRUE)

if (length(.args) > 0) {
  warning(
    "`make`ing %.Rmd from %.Rmd.orig will not work",
    " without developmental `cmdstanr` installation."
  )
  knit(.args[1], .args[2])
} else if (requireNamespace("usethis")) {
  wd <- getwd()
  # assuming somewhere in the project ...
  setwd(usethis::proj_path("vignettes"))
  markerpat <- "\\.orig$"
  tocompile <- list.files(pattern = markerpat)
  lapply(tocompile, \(x) {
    knit(x, sub(markerpat, "", x))
  })
  setwd(wd)
} else {
  stop(
    "Precompilation requires specific source and destination files,",
    " or `usethis` package."
  )
}

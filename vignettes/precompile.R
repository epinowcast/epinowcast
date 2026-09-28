# Precompiled vignettes with long run times
library(knitr)
library(usethis)

wd <- getwd() # assuming somewhere in the project ...
vignettes_dir <- proj_path("vignettes")
markerpat <- "\\.orig$"
# Recurse so heavy vignettes moved to vignettes/articles/ (pkgdown-only,
# R CMD build ignored) are still picked up.
tocompile <- list.files(vignettes_dir, pattern = markerpat, recursive = TRUE)
knit_vignette <- function(x) {
  setwd(file.path(vignettes_dir, dirname(x)))
  on.exit(setwd(wd))
  knit(basename(x), sub(markerpat, "", basename(x)))
}
lapply(tocompile, knit_vignette)
setwd(wd)

# Precompiled vignettes with long run times
library(knitr)
library(usethis)

wd <- getwd() # assuming somewhere in the project ...
setwd(proj_path("vignettes"))
markerpat <- "\\.orig$"
tocompile <- list.files(pattern = markerpat)
knit_vignette <- function(x) {
  knit(x, sub(markerpat, "", x))
}
lapply(tocompile, knit_vignette)
setwd(wd)

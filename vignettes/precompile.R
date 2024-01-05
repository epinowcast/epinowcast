# Precompiled vignettes with long run times
library(knitr)
library(usethis)

wd <- getwd() # assuming somewhere in the project ...
setwd(proj_path("vignettes"))
markerpat <- "\\.orig$"
tocompile <- list.files(pattern = markerpat)
lapply(tocompile, \(x) {
  knit(x, sub(markerpat, "", x))
})
setwd(wd)

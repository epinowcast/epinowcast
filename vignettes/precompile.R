# Precompiled vignettes with long run times
library(knitr)
setwd("vignettes")

markerpat <- "\\.orig$"

tocompile <- list.files(pattern = markerpat)

lapply(tocompile, \(x) {
  knit(x, sub(markerpat, "", x))
})

setwd("..")

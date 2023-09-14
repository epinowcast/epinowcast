# Precompiled vignettes with long run times
library(knitr)
setwd("vignettes")
knit("germany-age-stratified-nowcasting.Rmd.orig",
     "germany-age-stratified-nowcasting.Rmd"
)

knit(
  "single-timeseries-rt-estimation.Rmd.orig",
  "single-timeseries-rt-estimation.Rmd"
)
setwd("..")

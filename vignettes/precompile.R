# Precompiled vignettes with long run times
library(knitr)
knit(
  file.path("vignettes", "germany-age-stratified-nowcasting.Rmd.orig"),
  file.path("vignettes", "germany-age-stratified-nowcasting.Rmd")
)

# precompiler for vignettes with long run times

library(knitr)

.args <- commandArgs(trailingOnly = TRUE)

knit(.args[1], .args[2])

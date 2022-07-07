source("inst/scripts/germany_example.R")

saveRDS(nowcast, "inst/extdata/nowcast.rds")
saveRDS(pobs, "inst/extdata/preprocessed_observations.rds")
saveRDS(latest_obs, "inst/extdata/observations.rds")

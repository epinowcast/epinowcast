source(file.path("inst", "examples", "germany_dow.R"))

nowcast <- readRDS(file.path("inst", "extdata", "nowcast.rds"))
saveRDS(nowcast, file.path("inst", "extdata", "nowcast.rds"))
saveRDS(pobs, file.path("inst", "extdata", "preprocessed_observations.rds"))
saveRDS(latest_obs, file.path("inst", "extdata", "observations.rds"))

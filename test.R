library(epinowcast)

 nowcast <- enw_example("nowcast")
 summarised_nowcast <- summary(nowcast)
 obs <- enw_example("observations")

enw_score_nowcast(summarised_nowcast, obs)
enw_nowcast_summary <- function(fit, obs,
                                probs = c(0.05, 0.35, 0.5, 0.65, 0.95)) {
  nowcast <- rstan::summary(
    fit,
    par = "pp_inf_obs", digits = 1,
    probs = probs
  )$summary
  nowcast <- data.table::as.data.table(nowcast)

  max_delay <- nrow(nowcast) / max(obs$group)

  ord_obs <- data.table::copy(obs)
  ord_obs <- ord_obs[reference_date > (max(reference_date) - max_delay)]
  data.table::setorderv(ord_obs, c("reference_date", "group"))
  nowcast <- cbind(
    ord_obs,
    nowcast
  )
  data.table::setorderv(nowcast, c("group", "reference_date"))
  return(nowcast[])
}

enw_add_latest_obs_to_nowcast <- function(nowcast, obs) {
  obs <- data.table::as.data.table(obs)
  obs <- obs[, .(reference_date, group, latest_confirm = confirm)]
  out <- merge(
    nowcast, obs,
    by = c("reference_date", "group"), all.x = TRUE
  )
  data.table::setcolorder(
    out,
    neworder = c("reference_date", "group", "latest_confirm", "confirm")
  )
  return(out[])
}

enw_fit <- function(data, model, inits, ...) {
  if (is.null(model)) {
    model <- rstan::stan_model(here("stan", "nowcast.stan"))
  }
  fit <- rstan::sampling(model,
    data = data,
    init = inits,
    ...
  )
  return(fit)
}

epinowcast <- function(pobs,
                       reference_effects = enw_intercept_model(
                         pobs$metareference[[1]]
                       ),
                       report_effects = enw_intercept_model(
                         pobs$metareport[[1]]
                       ),
                       dist = "lognormal",
                       probs = c(0.05, 0.35, 0.5, 0.65, 0.95),
                       model = NULL, nowcast = TRUE, likelihood = TRUE,
                       debug = FALSE, pp = FALSE, ...) {
  stan_data <- enw_stan_data(pobs,
    reference_effects = reference_effects,
    report_effects = report_effects,
    dist = dist, nowcast = nowcast,
    likelihood = likelihood, debug = debug, pp = pp
  )

  inits <- enw_inits(stan_data)

  fit <- enw_fit(data = stan_data, model = model, inits = inits, ...)

  nowcast <- enw_nowcast_summary(fit, pobs$latest[[1]], probs = probs)

  out <- pobs[, `:=`(
    stan_data = list(stan_data),
    inits = list(inits),
    fit = list(fit),
    nowcast = list(nowcast)
  )]

  class(out) <- c("epinowcast", class(out))
  return(out[])
}

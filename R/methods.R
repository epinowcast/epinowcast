#' Summary method for epinowcast
#'
#' @description `summary` method for class "epinowcast".
#'
#' @param object A `data.table` output from [epinowcast()].
#'
#' @param type Character string indicating the summary to return; enforced by
#' [base::match.arg()]. Supported options are:
#'  * "nowcast" which summarises nowcast posterior with [enw_nowcast_summary()],
#'  * "nowcast_samples" which samples latest with [enw_nowcast_samples()],
#'  * "fit" which returns the summarised `cmdstanr` fit with [enw_posterior()],
#'  * "posterior_prediction" which returns summarised posterior predictions for
#'  the observations after fitting using [enw_pp_summary()].
#'
#' @param ... Additional arguments passed to summary specified by `type`.
#'
#' @family epinowcast
#' @seealso summary epinowcast
#' @method summary epinowcast
#' @return A summary data.frame
#' @export
#' @examples
#' nowcast <- enw_example("nowcast")
#'
#' # Summarise nowcast posterior
#' summary(nowcast, type = "nowcast")
#'
#' # Nowcast posterior samples
#' summary(nowcast, type = "nowcast_samples")
#'
#' # Nowcast model fit
#' summary(nowcast, type = "fit")
#'
#' # Posterior predictions
#' summary(nowcast, type = "posterior_prediction")
summary.epinowcast <- function(object, type = c(
                                 "nowcast", "nowcast_samples",
                                 "fit", "posterior_prediction"
                               ), max_delay = NULL, ...) {
  type <- match.arg(type)

  if (is.null(max_delay)) {
    spec_max_delay = object$max_delay
  } else {
    spec_max_delay = max_delay
  }
  
  s <- with(object, switch(type,
    nowcast = enw_nowcast_summary(
      fit = fit[[1]], obs = latest[[1]], max_delay = spec_max_delay, ...
    ),
    nowcast_samples = enw_nowcast_samples(
      fit = fit[[1]], obs = latest[[1]], max_delay = spec_max_delay, ...
      ),
    fit = enw_posterior(fit[[1]], ...),
    posterior_prediction = enw_pp_summary(fit[[1]], new_confirm[[1]], ...),
    stop(sprintf("unimplemented type: %s", type))
  ))

  return(s)
}


#' Plot method for epinowcast
#'
#' @description `plot` method for class "epinowcast".
#'
#' @param x A `data.table` of output as produced by [epinowcast()].
#'
#' @param latest_obs A `data.frame` of observed data which may be passed to
#' lower level methods.
#'
#' @param type Character string indicating the plot required; enforced by
#' [base::match.arg()]. Currently supported options:
#'  * "nowcast" which plots the nowcast for each dataset along with latest
#'  available observed data using [enw_plot_nowcast_quantiles()],
#'  * "posterior_prediction" which plots observations reported at the time
#'  against simulated observations from the model using
#'  [enw_plot_pp_quantiles()].
#'
#' @param ... Additional arguments to the plot function specified by `type`.
#'
#' @family epinowcast
#' @family plot
#' @method plot epinowcast
#' @inheritParams enw_plot_nowcast_quantiles
#' @return `ggplot2` object
#' @export
#' @examples
#' nowcast <- enw_example("nowcast")
#' latest_obs <- enw_example("obs")
#'
#' # Plot nowcast
#' plot(nowcast, latest_obs = latest_obs, type = "nowcast")
#'
#' # Plot posterior predictions by reference date
#' plot(nowcast, type = "posterior_prediction") +
#'  ggplot2::facet_wrap(ggplot2::vars(reference_date), scales = "free")
plot.epinowcast <- function(x, latest_obs = NULL, type = c(
                              "nowcast", "posterior_prediction"
                            ), log = FALSE, ...) {
  type <- match.arg(type)
  n <- summary(x, type = type)

  plot <- switch(type,
    nowcast = enw_plot_nowcast_quantiles(n, latest_obs, log = log, ...),
    posterior_prediction = enw_plot_pp_quantiles(n, log = log, ...),
    stop(sprintf("unimplemented type: %s", type))
  )

  return(plot)
}

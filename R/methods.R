#' Summary method for epinowcast
#'
#' @description `summary` method for class "epinowcast".
#'
#' @param object A `data.table` output from [epinowcast()].
#'
#' @param type A character string indicating the type of summary to return.
#' Currently supported options are "nowcast" which summaries the nowcast
#' posterior using [enw_nowcast_summary()],  "fit" which returns the
#' summarised `cmdstanr` fit using [enw_posterior()], and
#' "posterior_prediction" which returns summarised posterior predictions for
#' observations used in fitting (using [enw_pp_summary()]).
#'
#' @param ... Pass additional arguments to summary functions.
#'
#' @family epinowcast
#' @seealso summary epinowcast
#' @method summary epinowcast
#' @return `ggplot2` object
#' @export
summary.epinowcast <- function(object, type = "nowcast", ...) {
  type <- match.arg(
    type,
    choices = c("nowcast", "fit", "posterior_prediction")
  )

  if (type %in% "nowcast") {
    s <- enw_nowcast_summary(object$fit[[1]], object$latest[[1]], ...)
  } else if (type %in% "fit") {
    s <- enw_posterior(object$fit[[1]], ...)
  } else if (type %in% "posterior_prediction") {
    s <- enw_pp_summary(object$fit[[1]], object$diff[[1]], ...)
  }
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
#' @param type A character string indicating the type of plot required.
#' Currently supported options are "nowcast" which plots the nowcast
#' for each dataset along with the latest available observed data (using
#' [enw_plot_nowcast_quantiles()]), and "posterior_prediction" which plots
#' observations reported at the time against simulated observations from  the
#'  model (using [enw_plot_pp_quantiles()]).
#'
#' @param ... Pass additional arguments to plot functions.
#'
#' @family epinowcast
#' @family plot
#' @method plot epinowcast
#' @inheritParams enw_plot_nowcast_quantiles
#' @return `ggplot2` object
#' @export
plot.epinowcast <- function(x, latest_obs = NULL, type = "nowcast",
                            log = FALSE, ...) {
  type <- match.arg(type, choices = c("nowcast", "posterior_prediction"))

  if (type %in% "nowcast") {
    n <- summary(x, type = "nowcast")
    if (is.null(latest_obs)) {
      atest_obs <- x$latest[[1]]
    }
    plot <- enw_plot_nowcast_quantiles(n, latest_obs, log = log, ...)
  } else if (type %in% "posterior_prediction") {
    n <- summary(x, type = type)
    plot <- enw_plot_pp_quantiles(n, log = log, ...)
  }
  return(plot)
}

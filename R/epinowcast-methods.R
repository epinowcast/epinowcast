#' Summary method for epinowcast
#'
#' @description `summary` method for class "epinowcast".
#'
#' @param object A `data.table` output from [epinowcast()].
#'
#' @param type A character string indicating the type of summary to return.
#' Currently supported options are "nowcast" which summaries the nowcast
#' posterior using [enw_nowcast_summary()], and "fit" which returns the
#' summarised `cmdstanr` fit.
#'
#' @param ... Pass additional arguments to summary functions.
#'
#' @family epinowcast
#' @seealso summary epinowcast
#' @method summary epinowcast
#' @return `ggplot2` object
#' @export
summary.epinowcast <- function(object, type = "nowcast", ...) {
  type <- match.arg(type, choices = c("nowcast", "fit"))

  if (type %in% "nowcast") {
    s <- enw_nowcast_summary(object$fit[[1]], object$latest[[1]], ...)
  } else if (type %in% "fit") {
    s <- fit$fit[[1]]$summary(...)
  }
  return(s)
}

#' Plot method for epinowcast
#'
#' @description `plot` method for class "epinowcast".
#'
#' @param x A list of output as produced by [epinowcast()].
#'
#' @param type A character string indicating the type of plot required.
#' Currently supported options are "nowcast" which plots the nowcast
#' for each dataset along with the latest available observed data, and
#' "posterior" which plots observations reported at the time against
#' simulated observations from  the model.
#'
#' @param ... Pass additional arguments to plot functions.
#'
#' @family epinowcast
#' @seealso plot epinowcast
#' @method plot epinowcast
#' @return `ggplot2` object
#' @export
plot.epinowcast <- function(x, type = "nowcast", ...) {
  type <- match.arg(type, choices = c("nowcast"))
  return(invisible(NULL))
}

#' Summary method for epinowcast
#'
#' @description `summary` method for class "epinowcast".
#'
#' @param object A `data.table` output from [epinowcast()].
#'
#' @param type A character string indicating the type of summary to return.
#' Currently supported options are "nowcast" which summaries the nowcast
#' posterior using [enw_nowcast_summary()], "nowcast_samples" which returns
#' posterior samples from the most recent nowcast, "fit" which returns the
#' summarised `cmdstanr` fit using [enw_posterior()], and
#' "posterior_prediction" which returns summarised posterior predictions for
#' observations used in fitting (using [enw_pp_summary()]).
#'
#' @param ... Pass additional arguments to summary functions.
#'
#' @family epinowcast
#' @seealso summary epinowcast
#' @method summary epinowcast
#' @return A summary data.frame
#' @export
summary.epinowcast <- function(object, type = "nowcast", ...) {
  type <- match.arg(
    type,
    choices = c("nowcast", "nowcast_samples", "fit", "posterior_prediction")
  )

  if (type %in% "nowcast") {
    s <- enw_nowcast_summary(object$fit[[1]], object$latest[[1]], ...)
  } else if (type %in% "nowcast_samples") {
    s <- enw_nowcast_samples(object$fit[[1]], object$latest[[1]], ...)
  } else if (type %in% "fit") {
    s <- enw_posterior(object$fit[[1]], ...)
  } else if (type %in% "posterior_prediction") {
    s <- enw_pp_summary(object$fit[[1]], object$new_confirm[[1]], ...)
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
#' @param ... Pass additional arguments to lower level plot functions.
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
    plot <- enw_plot_nowcast_quantiles(n, latest_obs, log = log, ...)
  } else if (type %in% "posterior_prediction") {
    n <- summary(x, type = type)
    plot <- enw_plot_pp_quantiles(n, log = log, ...)
  }
  return(plot)
}

#' Plot method for enw_preprocess_data
#'
#' @description `plot` method for preprocessed data of class
#' "enw_preprocess_data".
#' Creates different descriptive plots of the empirical reporting delay
#' distribution and time-series of reported cases per reference day.
#'
#' @param x A `data.table` of preprocessed data as produced by
#' [enw_preprocess_data()].
#'
#' @param type A character string indicating the type of the desired plot.
#' Currently supported options are "emp_rep_cum" which plots the empirical
#' cumulative reporting delay distribution for each stratum (using
#' [enw_plot_emprep_cum()]), "emp_rep_frac" (using [enw_plot_emprep_frac()]),
#' "emp_rep_quant" model (using [enw_plot_emprep_quant()]), and "emp_ts_del"
#' (using [enw_plot_emp_ts_del()]).
#'
#' @param delay_group_thresh A vector defining thresholds for the grouping of
#' reporting delays based on left-closed intervals. Smallest value should be
#' zero, largest should correspond to max_delay.
#'
#' @param quantiles A vector of quantiles used for the "emp_rep_quant" plot.
#' Default is NULL, corresponding to the 0.10, 0.50, and 0.90 quantiles.
#'
#' @param ... Pass additional arguments to lower level plot functions.
#'
#' @family epinowcast
#' @family plot
#' @method plot enw_preprocess_data
#'
#' @return `ggplot2` object
#' @export
plot.enw_preprocess_data <- function(x, type = "emp_rep_cum",
                                     delay_group_thresh = NULL,
                                     quantiles = NULL, ...) {
  type <- match.arg(type, choices = c(
    "emp_rep_cum", "emp_rep_frac",
    "emp_rep_quant", "emp_ts_del"
  ))

  if (is.null(delay_group_thresh)) {
    if (x$max_delay >= 8) {
      delay_group_thresh <- unique(c(
        0, 1, 3, seq(8, x$max_delay, by = 7),
        x$max_delay
      ))
    } else {
      delay_group_thresh <- 0:x$max_delay
    }
  }

  if (is.null(quantiles)) {
    quantiles <- c(0.1, 0.5, 0.9)
  } else {
    stopifnot(min(quantiles) > 0)
    stopifnot(max(quantiles) <= 1)
  }

  if (type %in% "emp_rep_cum") {
    plot <- enw_plot_emprep_cum(x,
      delay_group_thresh = delay_group_thresh,
      ...
    )
  } else if (type %in% "emp_rep_frac") {
    plot <- enw_plot_emprep_frac(x,
      delay_group_thresh = delay_group_thresh,
      ...
    )
  } else if (type %in% "emp_rep_quant") {
    plot <- enw_plot_emprep_quant(x,
      quantiles = quantiles,
      ...
    )
  } else if (type %in% "emp_ts_del") {
    plot <- enw_plot_emp_ts_del(x,
      delay_group_thresh = delay_group_thresh,
      ...
    )
  }
  return(plot)
}

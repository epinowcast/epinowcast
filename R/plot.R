#' @title Package plot theme
#'
#' @param plot `ggplot2` plot object.
#' @family plot
#' @return `ggplot2` plot object.
#' @export
enw_plot_theme <- function(plot) {
  plot <- plot +
    theme_bw() +
    labs(x = "Date") +
    theme(legend.position = "bottom", legend.box = "vertical") +
    scale_x_date(date_breaks = "1 week", date_labels = "%b %d") +
    theme(axis.text.x = element_text(angle = 90))
  return(plot)
}

#' Generic quantile plot
#'
#' @param posterior A `data.frame` of summarised posterior estimates
#' containing at least a `confirm` count column and a date variable
#'
#' @param obs A data frame of observed data containing at least a `confirm`
#' count variable and the same date variable as in `posterior`.
#'
#' @param log Logical, defaults to `FALSE`. Should counts be plot on the log
#' scale.
#'
#' @param ... Additional arguments passed to [ggplot2::aes()] must at least
#' specify the x date variable.
#'
#' @return A `ggplot2` plot.
#'
#' @family plot
#' @importFrom scales comma
#' @export
enw_plot_quantiles <- function(posterior, obs = NULL, log = TRUE, ...) {
  check_quantiles(posterior, req_probs = c(0.05, 0.2, 0.8, 0.95))

  plot <- ggplot(posterior) +
    aes(...)

  plot <- plot +
    geom_line(aes(y = median), size = 1, alpha = 0.6) +
    geom_line(aes(y = mean), linetype = 2) +
    geom_ribbon(aes(ymin = q5, ymax = q95), alpha = 0.2, size = 0.2) +
    geom_ribbon(aes(ymin = q20, ymax = q80, col = NULL), alpha = 0.2) +
    geom_point(aes(y = confirm), na.rm = TRUE, alpha = 0.7, size = 1.1)

  if (!is.null(obs)) {
    obs <- data.table::copy(obs)
    obs[, latest_confirm := confirm]
    plot <- plot +
      geom_point(
        data = obs, aes(y = latest_confirm),
        na.rm = TRUE, alpha = 0.7, size = 1.1, shape = 2
      )
  }
  if (log) {
    plot <- plot + scale_y_log10(labels = scales::comma)
  } else {
    plot <- plot + scale_y_continuous(labels = scales::comma)
  }
  plot <- enw_plot_theme(plot)
  return(plot)
}

#' Plot nowcast quantiles
#'
#' @param nowcast A `data.frame` of summarised posterior nowcast
#' estimates containing at least a `confirm` count column and a
#' `reference_date` date variable.
#'
#' @param obs A `data.frame` of observed data containing at least a `confirm`
#' count variable and the same date variable in `nowcast`.
#'
#' @param ... Additional arguments passed to [enw_plot_pp_quantiles()].
#'
#' @return A `ggplot2` plot.
#'
#' @inheritParams enw_plot_quantiles
#' @family plot
#' @importFrom scales comma
#' @export
enw_plot_nowcast_quantiles <- function(nowcast, obs = NULL, log = FALSE, ...) {
  plot <- enw_plot_quantiles(
    nowcast,
    obs = obs, x = reference_date, log = log, ...
  ) +
    labs(y = "Notifications", x = "Reference date")
  return(plot)
}

#' Plot posterior prediction quantiles
#'
#' @param pp A `data.frame` of summarised posterior predictions
#' estimates containing at least a `confirm` count column and a
#' `report_date` date variable.
#'
#' @param ... Additional arguments passed to [enw_plot_pp_quantiles()].
#'
#' @return A `ggplot2` plot.
#'
#' @inheritParams enw_plot_quantiles
#' @family plot
#' @importFrom scales comma
#' @export
enw_plot_pp_quantiles <- function(pp, log = FALSE, ...) {
  pp <- data.table::copy(pp)
  pp[, confirm := new_confirm]
  plot <- enw_plot_quantiles(
    pp,
    x = report_date, log = log, ...
  ) +
    labs(y = "Notifications", x = "Report date")
  return(plot)
}

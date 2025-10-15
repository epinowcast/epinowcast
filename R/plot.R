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
    theme(legend.position = "bottom", legend.box = "horizontal") +
    scale_x_date(date_breaks = "1 week", date_labels = "%b %d") +
    theme(axis.text.x = element_text(angle = 90))
  return(plot)
}

#' Generic quantile plot
#'
#' @param obs A `data.frame` of summarised posterior estimates
#' containing at least a `confirm` count column and a date variable
#'
#' @param latest_obs A `data.frame` of observed data containing at least a
#' `confirm` count variable and the same date variable as in the main data.frame
#' used for plotting.
#'
#' @param log Logical, defaults to `FALSE`. Should counts be plot on the log
#' scale.
#'
#' @param ... Additional arguments passed to [ggplot2::aes()] must at least
#' specify the x date variable.
#' @return A `ggplot2` plot.
#'
#' @family plot
#' @importFrom scales comma
#' @export
#' @examples
#' nowcast <- enw_example("nowcast")
#' obs <- enw_example("obs")
#'
#' # Plot observed data by reference date
#' enw_plot_obs(obs, x = reference_date)
#'
#' # Plot observed data by reference date with more recent data
#' enw_plot_obs(nowcast$latest[[1]], obs, x = reference_date)
enw_plot_obs <- function(obs, latest_obs = NULL, log = TRUE, ...) {
  plot <- ggplot(obs) +
    aes(...)

  plot <- plot +
    geom_point(aes(y = confirm, shape = "At nowcast date", alpha = NULL),
      na.rm = TRUE, alpha = 0.7, size = 1.1
    )

  if (!is.null(latest_obs)) {
    latest_obs <- coerce_dt(latest_obs)
    latest_obs[, latest_confirm := confirm]
    plot <- plot +
      geom_point(
        data = latest_obs,
        aes(y = latest_confirm, shape = "Latest data", alpha = NULL),
        na.rm = TRUE, alpha = 0.7, size = 1.1
      )
  }

  plot <- plot +
    scale_shape_manual(
      name = NULL,
      values = c("At nowcast date" = 19, "Latest data" = 2),
      breaks = if (!is.null(latest_obs)) {
        c("At nowcast date", "Latest data")
      } else {
        "At nowcast date"
      }
    )

  if (log) {
    plot <- plot + scale_y_log10(labels = scales::comma)
  } else {
    plot <- plot + scale_y_continuous(labels = scales::comma)
  }
  plot <- enw_plot_theme(plot)
  return(plot)
}

#' Generic quantile plot
#'
#' @param posterior A `data.frame` of summarised posterior estimates
#' containing at least a `confirm` count column a date variable,
#' quantile estimates for the 5%, 20%, 80%, and 95% quantiles and the
#' mean and median. This function is wrapped in
#' [enw_plot_nowcast_quantiles()] and [enw_plot_pp_quantiles()] with sensible
#' default labels.
#'
#' @return A `ggplot2` plot.
#' @seealso [enw_plot_nowcast_quantiles()], [enw_plot_pp_quantiles()]
#' @family plot
#' @inheritParams enw_plot_obs
#' @export
#' @examples
#' nowcast <- enw_example("nowcast")
#' nowcast <- summary(nowcast, probs = c(0.05, 0.2, 0.8, 0.95))
#' enw_plot_quantiles(nowcast, x = reference_date)
enw_plot_quantiles <- function(posterior, latest_obs = NULL, log = FALSE, ...) {
  check_quantiles(posterior, req_probs = c(0.05, 0.2, 0.8, 0.95))

  plot <- enw_plot_obs(posterior, latest_obs = latest_obs, log = log, ...)

  plot <- plot +
    geom_ribbon(aes(ymin = q5, ymax = q95, alpha = "90% CrI"),
      linewidth = 0.2
    ) +
    geom_ribbon(aes(ymin = q20, ymax = q80, alpha = "60% CrI"),
      linewidth = 0.2
    ) +
    geom_line(aes(y = median, linetype = "Median"), linewidth = 1, alpha = 0.6) +
    geom_line(aes(y = mean, linetype = "Mean"), alpha = 0.6) +
    scale_linetype_manual(
      name = NULL,
      values = c(Median = 1, Mean = 2)
    ) +
    scale_alpha_manual(
      name = NULL,
      values = c("90% CrI" = 0.2, "60% CrI" = 0.2)
    ) +
    guides(
      alpha = guide_legend(order = 1, nrow = 1),
      linetype = guide_legend(order = 2, nrow = 1),
      shape = guide_legend(order = 3, nrow = 1)
    )
  return(plot)
}

#' Plot nowcast quantiles
#'
#' @param nowcast A `data.frame` of summarised posterior nowcast
#' estimates containing at least a `confirm` count column and a
#' `reference_date` date variable.
#'
#' @param ... Additional arguments passed to [enw_plot_pp_quantiles()].
#'
#' @return A `ggplot2` plot.
#'
#' @inheritParams enw_plot_quantiles
#' @family plot
#' @importFrom scales comma
#' @export
#' @examples
#' nowcast <- enw_example("nowcast")
#' nowcast <- summary(nowcast, probs = c(0.05, 0.2, 0.8, 0.95))
#' enw_plot_nowcast_quantiles(nowcast)
enw_plot_nowcast_quantiles <- function(nowcast, latest_obs = NULL,
                                       log = FALSE, ...) {
  plot <- enw_plot_quantiles(
    nowcast,
    latest_obs = latest_obs, x = reference_date, log = log, ...
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
#' @examples
#' nowcast <- enw_example("nowcast")
#' nowcast <- summary(
#'  nowcast, type = "posterior_prediction", probs = c(0.05, 0.2, 0.8, 0.95)
#' )
#' enw_plot_pp_quantiles(nowcast) +
#'  ggplot2::facet_wrap(ggplot2::vars(reference_date), scales = "free")
enw_plot_pp_quantiles <- function(pp, log = FALSE, ...) {
  pp <- coerce_dt(pp)
  pp[, confirm := new_confirm]
  plot <- enw_plot_quantiles(
    pp,
    x = report_date, log = log, ...
  ) +
    labs(y = "Notifications", x = "Report date")
  return(plot)
}

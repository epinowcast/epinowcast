#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param plot PARAM_DESCRIPTION
#' @family plot
#' @return OUTPUT_DESCRIPTION
#' @details DETAILS
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

#' Default generic posterior plot
#'
#' @param obs A data frame of observed data as produced by [latest_obs()].
#'
#' @param ... Additional arguments passed to [ggplot2::aes()]
#'
#' @return A `ggplot2` plot.
#'
#' @family plot
#' @export
enw_plot <- function(posterior, obs = NULL, log = TRUE, ...) {
  check_quantiles(posterior, req_probs = c(0.05, 0.2, 0.8, 0.95))

  plot <- ggplot(posterior) +
    aes(...)

  plot <- plot +
    geom_line(aes(y = median), size = 1, alpha = 0.6) +
    geom_line(aes(y = mean), linetype = 2) +
    geom_ribbon(aes(ymin = q5, ymax = q95), alpha = 0.2, size = 0.2) +
    geom_ribbon(aes(ymin = q20, ymax = q80, col = NULL), alpha = 0.2) +
    geom_point(aes(y = confirm), na.rm = TRUE, alpha = 0.7)

  if (log) {
    plot <- plot + ggplot2::scale_y_log10(labels = scales::comma)
  } else {
    plot <- plot + ggplot2::scale_y_continuous(labels = scales::comma)
  }
  plot <- enw_plot_theme(plot)
  return(plot)
}

plot_nowcast <- function(nowcast, log = FALSE) {
  enw_plot(p, x = reference_date)
}

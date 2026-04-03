# Internal helper: print the common header and dataset dimensions
# shared by print.enw_preprocess_data and print.epinowcast
#' @importFrom cli format_inline
.enw_print_header <- function(x, title) {
  width <- getOption("width", 80)
  rule <- cli::rule(title, width = width)
  cat(rule, "\n")

  by_vars <- x$by[[1]]
  if (length(by_vars) > 0) {
    cat(cli::format_inline(
      "Groups: {x$groups} ({toString(by_vars)})",
      " | Timestep: {x$timestep[[1]]}",
      " | Max delay: {x$max_delay}"
    ), "\n")
  } else {
    cat(cli::format_inline(
      "Groups: {x$groups}",
      " | Timestep: {x$timestep[[1]]}",
      " | Max delay: {x$max_delay}"
    ), "\n")
  }
  cat(cli::format_inline(
    "Observations: {x$time} timepoints",
    " x {x$snapshots} snapshots"
  ), "\n")
  cat(cli::format_inline(
    "Max date: {format(x$max_date)}"
  ), "\n")

  dt_cols <- c(
    "obs", "new_confirm", "latest",
    "missing_reference", "reporting_triangle",
    "metareference", "metareport", "metadelay"
  )
  present <- intersect(dt_cols, names(x))
  if (length(present) > 0) {
    cat("\n")
    cat(cli::format_inline(
      "Datasets (access with",
      ' {.code enw_get_data(x, "<name>")}):'
    ), "\n")
    max_width <- max(nchar(present))
    for (col in present) {
      dt <- x[[col]][[1]]
      label <- formatC(
        col, width = -max_width, flag = "-"
      )
      cat(
        " ", label, ":",
        formatC(
          nrow(dt), width = 7, format = "d",
          big.mark = ","
        ),
        "x", ncol(dt), "\n"
      )
    }
  }
}

#' Print method for enw_preprocess_data
#'
#' @description `print` method for class
#'   `"enw_preprocess_data"`.
#'
#' @param x A `data.table` output from
#'   [enw_preprocess_data()] or [enw_construct_data()].
#'
#' @param ... Additional arguments (not used).
#'
#' @family epinowcast
#' @method print enw_preprocess_data
#' @return Invisibly returns `x`.
#' @export
#' @importFrom cli format_inline rule
#' @examples
#' pobs <- enw_example("preprocessed_observations")
#' pobs
print.enw_preprocess_data <- function(x, ...) {
  .enw_print_header(x, "Preprocessed nowcast data")
  invisible(x)
}

#' Print method for epinowcast
#'
#' @description `print` method for class `"epinowcast"`.
#'
#' @param x A `data.table` output from [epinowcast()].
#'
#' @param ... Additional arguments (not used).
#'
#' @family epinowcast
#' @method print epinowcast
#' @return Invisibly returns `x`.
#' @export
#' @importFrom cli format_inline rule
#' @examples
#' nowcast <- enw_example("nowcast")
#' nowcast
print.epinowcast <- function(x, ...) {
  .enw_print_header(x, "epinowcast model output")

  # Model components
  model_cols <- c(
    "priors", "fit", "data", "fit_args",
    "init_method_output"
  )
  present <- intersect(model_cols, names(x))
  if (length(present) > 0) {
    cat(cli::format_inline(
      "\nModel objects (access with",
      ' {.code enw_get_data(x, "<name>")}):'
    ), "\n")
    for (col in present) {
      obj <- x[[col]][[1]]
      info <- if (is.data.frame(obj)) {
        paste0(nrow(obj), " x ", ncol(obj))
      } else if (is.list(obj)) {
        paste0("list(", length(obj), ")")
      } else {
        class(obj)[1]
      }
      cat(" ", col, ":", info, "\n")
    }
  }

  has_mcmc <- "max_rhat" %in% names(x)
  has_runtime <- "run_time" %in% names(x)
  if (has_mcmc || has_runtime) {
    cat(cli::format_inline(
      "Model fit:"
    ), "\n")
    if (has_mcmc) {
      n_samples <- formatC( # nolint
        x$samples, format = "d", big.mark = ","
      )
      pct_div <- round( # nolint
        x$per_divergent_transitions * 100, 1
      )
      cat(cli::format_inline(
        "  Samples: {n_samples}",
        " | Max Rhat: {x$max_rhat}"
      ), "\n")
      cat(cli::format_inline(
        "  Divergent transitions:",
        " {x$divergent_transitions} ({pct_div}%)"
      ), "\n")
      if ("max_treedepth" %in% names(x)) {
        pct_tree <- round( # nolint
          x$per_at_max_treedepth * 100, 1
        )
        cat(cli::format_inline(
          "  Max treedepth: {x$max_treedepth}",
          " ({x$no_at_max_treedepth} at max,",
          " {pct_tree}%)"
        ), "\n")
      }
    }
    if (has_runtime) {
      cat(cli::format_inline(
        "  Run time: {x$run_time} secs"
      ), "\n")
    }
  }

  invisible(x)
}

#' Summary method for enw_preprocess_data
#'
#' @description `summary` method for class
#'   `"enw_preprocess_data"`. Returns a structured overview of
#'   the preprocessed data including a preview of the latest
#'   observations and a corner of the reporting triangle.
#'
#' @param object A `data.table` output from
#'   [enw_preprocess_data()] or [enw_construct_data()].
#'
#' @param n Integer number of rows to show in previews.
#'   Defaults to 6.
#'
#' @param ... Additional arguments (not used).
#'
#' @family epinowcast
#' @method summary enw_preprocess_data
#' @return A list of class `"summary.enw_preprocess_data"`
#'   containing the preprocessed data object and preview
#'   parameters, printed via
#'   [print.summary.enw_preprocess_data()].
#' @export
#' @examples
#' pobs <- enw_example("preprocessed_observations")
#' summary(pobs)
summary.enw_preprocess_data <- function(object, n = 6, ...) {
  out <- list(object = object, n = n)
  class(out) <- "summary.enw_preprocess_data"
  out
}

#' Print method for summary.enw_preprocess_data
#'
#' @description `print` method for the output of
#'   [summary.enw_preprocess_data()].
#'
#' @param x A `summary.enw_preprocess_data` object.
#'
#' @param ... Additional arguments (not used).
#'
#' @family epinowcast
#' @method print summary.enw_preprocess_data
#' @return Invisibly returns `x`.
#' @export
#' @importFrom cli format_inline rule
print.summary.enw_preprocess_data <- function(x, ...) {
  obj <- x$object
  n <- x$n

  width <- getOption("width", 80)
  rule <- cli::rule(
    "Preprocessed nowcast data summary",
    width = width
  )
  cat(rule, "\n")

  by_vars <- obj$by[[1]]
  if (length(by_vars) > 0) {
    cat(cli::format_inline(
      "Groups: {obj$groups} ({toString(by_vars)})",
      " | Timestep: {obj$timestep[[1]]}",
      " | Max delay: {obj$max_delay}"
    ), "\n")
  } else {
    cat(cli::format_inline(
      "Groups: {obj$groups}",
      " | Timestep: {obj$timestep[[1]]}",
      " | Max delay: {obj$max_delay}"
    ), "\n")
  }

  latest <- obj$latest[[1]]
  dates <- latest$reference_date
  n_days <- as.integer(max(dates) - min(dates)) # nolint
  cat(cli::format_inline(
    "Date range: {format(min(dates))}",
    " to {format(max(dates))} ({n_days} days)"
  ), "\n")
  cat(cli::format_inline(
    "Observations: {obj$time} timepoints",
    " x {obj$snapshots} snapshots"
  ), "\n")

  cat(cli::format_inline(
    "\nLatest observations (first {n} rows):"
  ), "\n")
  print(utils::head(latest, n))

  rt <- obj$reporting_triangle[[1]]
  max_cols <- min(ncol(rt), n + 2)
  rt_corner <- utils::head(
    rt[, seq_len(max_cols), with = FALSE], n
  )
  cat(cli::format_inline(
    "\nReporting triangle corner",
    " (first {n} rows x {max_cols} cols):"
  ), "\n")
  print(rt_corner)
  cat(cli::format_inline(
    "... ({nrow(rt)} rows x {ncol(rt)} cols total)"
  ), "\n")

  invisible(x)
}

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
#' @inheritParams enw_nowcast_summary
#' @param ... Additional arguments passed to summary specified by `type`.
#'
#' @family epinowcast
#' @seealso summary epinowcast
#' @method summary epinowcast
#' @return A summary data.frame
#' @export
#' @importFrom cli cli_abort
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
                               ), max_delay = object$max_delay, ...) {
  type <- match.arg(type)
  arg_max_delay <- max_delay # nolint

  s <- with(object, switch(type,
    nowcast = enw_nowcast_summary(
      fit = fit[[1]], obs = latest[[1]], max_delay = arg_max_delay,
      timestep = timestep[[1]], ...
    ),
    nowcast_samples = enw_nowcast_samples(
      fit = fit[[1]], obs = latest[[1]], max_delay = arg_max_delay,
      timestep = timestep[[1]], ...
      ),
    fit = enw_posterior(fit[[1]], ...),
    posterior_prediction = enw_pp_summary(fit[[1]], new_confirm[[1]], ...),
    cli::cli_abort("unimplemented type: {type}")
  ))

  s
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
#' @importFrom cli cli_abort
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
    cli::cli_abort("unimplemented type: {type}")
  )

  plot
}

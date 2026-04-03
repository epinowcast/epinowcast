# Internal helper: print the common header and dataset dimensions
# shared by print.enw_preprocess_data and print.epinowcast
.enw_print_header <- function(x, title) {
  cat("--", title, "--\n")

  by_vars <- x$by[[1]]
  group_info <- if (length(by_vars) > 0) {
    paste0(
      "Groups: ", x$groups,
      " (", toString(by_vars), ")"
    )
  } else {
    paste0("Groups: ", x$groups)
  }
  cat(
    group_info, "| Timestep:", x$timestep[[1]],
    "| Max delay:", x$max_delay, "\n"
  )
  cat(
    "Observations:", x$time, "timepoints x",
    x$snapshots, "snapshots\n"
  )
  cat("Max date:", format(x$max_date), "\n")

  dt_cols <- c(
    "obs", "new_confirm", "latest",
    "missing_reference", "reporting_triangle",
    "metareference", "metareport", "metadelay"
  )
  present <- intersect(dt_cols, names(x))
  if (length(present) > 0) {
    cat(
      "\nDatasets",
      "(access with enw_get_data(x, \"<name>\")):\n"
    )
    max_width <- max(nchar(present))
    for (col in present) {
      dt <- x[[col]][[1]]
      label <- formatC(col, width = -max_width, flag = "-")
      cat(
        " ", label, ":",
        formatC(nrow(dt), width = 7, format = "d",
                big.mark = ","),
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
#' @examples
#' nowcast <- enw_example("nowcast")
#' nowcast
print.epinowcast <- function(x, ...) {
  .enw_print_header(x, "epinowcast model output")

  if ("priors" %in% names(x)) {
    cat(
      "\nPriors:",
      nrow(x$priors[[1]]), "parameters\n"
    )
  }

  has_mcmc <- "max_rhat" %in% names(x)
  has_runtime <- "run_time" %in% names(x)
  if (has_mcmc || has_runtime) {
    cat("Model fit:\n")
    if (has_mcmc) {
      cat(
        "  Samples:", formatC(
          x$samples, format = "d", big.mark = ","
        ),
        "| Max Rhat:", x$max_rhat, "\n"
      )
      cat(
        "  Divergent transitions:",
        x$divergent_transitions,
        paste0(
          "(",
          round(x$per_divergent_transitions * 100, 1),
          "%)"
        ), "\n"
      )
    }
    if (has_runtime) {
      cat("  Run time:", x$run_time, "secs\n")
    }
  }

  cat("\nUse summary() and plot() for analysis.\n")
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
print.summary.enw_preprocess_data <- function(x, ...) {
  obj <- x$object
  n <- x$n

  cat("-- Preprocessed nowcast data summary --\n")

  by_vars <- obj$by[[1]]
  group_info <- if (length(by_vars) > 0) {
    paste0(
      "Groups: ", obj$groups,
      " (", toString(by_vars), ")"
    )
  } else {
    paste0("Groups: ", obj$groups)
  }
  cat(
    group_info, "| Timestep:", obj$timestep[[1]],
    "| Max delay:", obj$max_delay, "\n"
  )

  latest <- obj$latest[[1]]
  dates <- latest$reference_date
  cat(
    "Date range:", format(min(dates)),
    "to", format(max(dates)),
    paste0("(", as.integer(max(dates) - min(dates)), " days)"),
    "\n"
  )
  cat(
    "Observations:", obj$time, "timepoints x",
    obj$snapshots, "snapshots\n"
  )

  cat("\nLatest observations (first", n, "rows):\n")
  print(utils::head(latest, n))

  rt <- obj$reporting_triangle[[1]]
  max_cols <- min(ncol(rt), n + 2)
  rt_corner <- utils::head(rt[, seq_len(max_cols),
                               with = FALSE], n)
  cat(
    "\nReporting triangle corner (first", n,
    "rows x", max_cols, "cols):\n"
  )
  print(rt_corner)
  cat(
    "... (", nrow(rt), "rows x", ncol(rt),
    "cols total)\n"
  )

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

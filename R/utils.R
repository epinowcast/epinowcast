#' @rawNamespace import(data.table, except = transpose)
#' @import cmdstanr
#' @import ggplot2
#' @importFrom stats median rnorm
NULL

#' @title Check an object is a Date
#' @description Checks that an object is a date
#' @param x An object
#' @return A logical
#' @family utils
is.Date <- function(x) {
  # nolint
  inherits(x, "Date")
}

#' Read in a stan function file as a character string
#'
#' @inheritParams enw_stan_to_r
#' @return A character string in the of stan functions.
#' @family utils
#' @importFrom purrr map_chr
stan_fns_as_string <- function(files, include) {
  functions <- paste0(
    "\n functions{ \n",
    paste(
      purrr::map_chr(
        files,
        ~ paste(readLines(file.path(include, .)), collapse = "\n")
      ),
      collapse = "\n"
    ),
    "\n }"
  )
  return(functions)
}

#' Load a package example
#'
#' Loads examples of nowcasts produce using example scripts. Used to streamline
#' examples, in package tests and to enable users to explore package
#' functionality without needing to install `cmdstanr`.
#'
#' @param type A character string indicating the example to load.
#' Supported options are
#'  * "nowcast", for [epinowcast()] applied to [germany_covid19_hosp]
#'  * "preprocessed_observations", for [enw_preprocess_data()] applied to
#'  [germany_covid19_hosp]
#'  * "observations", for [enw_latest_data()] applied to [germany_covid19_hosp]
#'  * "script", the code used to generate these examples.
#'
#' @return Depending on `type`, a `data.table` of the requested output OR
#' the file name(s) to generate these outputs (`type` = "script")
#'
#' @family data
#' @export
#' @examples
#' # Load the nowcast
#' enw_example(type = "nowcast")
#'
#' # Load the preprocessed observations
#' enw_example(type = "preprocessed_observations")
#'
#' # Load the latest observations
#' enw_example(type = "observations")
#'
#' # Load the script used to generate these examples
#' # Optionally source this script to regenerate the example
#' readLines(enw_example(type = "script"))
enw_example <- function(type = c(
                          "nowcast", "preprocessed_observations",
                          "observations", "script"
                        )) {
  type <- match.arg(type)

  if (type %in% c("nowcast", "preprocessed_observations", "observations")) {
    return(readRDS(
      system.file("extdata", sprintf("%s.rds", type), package = "epinowcast")
    ))
  } else if (type == "script") {
    return(
      system.file("examples", "germany_dow.R", package = "epinowcast")
    )
  }
}

#' @title Coerce Dates
#'
#' @description Provides consistent coercion of inputs to [IDate]
#' with error handling
#'
#' @param dates A vector-like input, which the function attempts
#' to coerce via [data.table::as.IDate()]. Defaults to NULL.
#'
#' @return An [IDate] vector.
#'
#' @details If any of the elements of `dates` cannot be coerced,
#' this function will result in an error, indicating all indices
#' which cannot be coerced to [IDate].
#'
#' Internal methods of [epinowcast] assume dates are represented
#' as [IDate].
#'
#' @export
#' @importFrom data.table as.IDate
#' @importFrom cli cli_abort cli_warn
#' @family utils
#' @examples
#' # works
#' coerce_date(c("2020-05-28", "2020-05-29"))
#' # does not, indicates index 2 is problem
#' tryCatch(
#'   coerce_date(c("2020-05-28", "2020-o5-29")),
#'   error = function(e) {
#'     print(e)
#'   }
#' )
coerce_date <- function(dates = NULL) {
  if (is.null(dates)) {
    return(data.table::as.IDate(numeric()))
  }
  if (length(dates) == 0) {
    return(data.table::as.IDate(dates))
  }

  res <- data.table::as.IDate(vapply(dates, function(d) {
    tryCatch(
      data.table::as.IDate(d, optional = TRUE),
      error = function(e) {
        return(data.table::as.IDate(NA))
      }
    )
  }, FUN.VALUE = data.table::as.IDate(0)))

  if (anyNA(res)) {
    cli::cli_abort(paste0(
      "Failed to parse with `as.IDate`: {toString(dates[is.na(res)])} ",
      "(indices {toString(which(is.na(res)))})."
    ))
  } else {
    return(res)
  }
}

#' Get internal timestep
#'
#' This function converts the string representation of the timestep to its
#' corresponding numeric value or returns the numeric input (if it is a whole
#' number). For "day", "week", it returns 1 and 7 respectively.
#' For "month", it returns "month" as months are not a fixed number of days.
#' If the input is a numeric whole number, it is returned as is.
#'
#' @param timestep The timestep to used. This can be a string ("day",
#' "week", "month") or a numeric whole number representing the number of days.
#'
#' @return A numeric value representing the number of days for "day" and
#' "week", "month" for "month",  or the input value if it is a numeric whole
#' number.
#' @importFrom cli cli_abort
#' @family utils
get_internal_timestep <- function(timestep) {
  # check if the input is a character
  if (is.character(timestep)) {
    switch(
      timestep,
      day = 1,
      week = 7,
      month = "month",  # months are not a fixed number of days
      cli::cli_abort(
        "Invalid timestep. Acceptable string inputs are 'day', 'week', 'month'."
      )
    )
  } else if (is.numeric(timestep) && timestep == round(timestep)) {
    # check if the input is a whole number
    return(timestep)
  } else {
    cli::cli_abort(
      paste0(
        "Invalid timestep. If timestep is a numeric, it should be a whole ",
        "number representing the number of days."
      )
    )
  }
}

#' Internal function to perform rolling sum aggregation
#'
#' This function takes a data.table and applies a rolling sum over a given
#' timestep,
#' aggregating by specified columns. It's particularly useful for aggregating
#' observations over certain periods.
#'
#' @param dt A `data.table` to be aggregated.
#' @param internal_timestep An integer indicating the period over which to
#' aggregate.
#' @param by A character vector specifying the columns to aggregate by.
#'
#' @return A modified data.table with aggregated observations.
#'
#' @importFrom data.table frollsum
#' @family utils
aggregate_rolling_sum <- function(dt, internal_timestep, by = NULL) {
  dt <- dt[,
    `:=`(
      confirm = {
        n_vals <- if (.N <= internal_timestep) {
          seq_len(.N)
        } else {
          c(
            1:(internal_timestep - 1),
            rep(internal_timestep, .N - (internal_timestep - 1))
          )
        }
        frollsum(confirm, n_vals, adaptive = TRUE)
      }
    ),
    by = by
  ]
  return(dt[])
}

#' Convert date column to numeric and calculate its modulus with given timestep.
#'
#' This function processes a date column in a `data.table`, converting it to a
#' numeric representation and then computing the modulus with the provided
#' timestep.
#'
#' @param dt A data.table.
#'
#' @param date_column A character string representing the name of the date
#' column in dt.
#'
#' @param timestep An integer representing the internal timestep.
#'
#' @return A modified data.table with two new columns: one for the numeric
#' representation of the date minus the minimum date and another for its
#' modulus with the timestep.
#'
#' @family utils
date_to_numeric_modulus <- function(dt, date_column, timestep) {
  mod_col_name <- paste0(date_column, "_mod")

  dt[, c(mod_col_name) := as.numeric(
        get(date_column) - min(get(date_column), na.rm = TRUE)
      ) %% timestep
  ]
  return(dt[])
}

#' Set caching location for Stan models
#'
#' This function allows the user to set a cache location for
#' Stan models rather than a temp directory. This can reduce the
#' need for model compilation on every new model run across sessions.
#'
#' @param path A valid filepath representing the desired cache location
#' @param persistent a logical representing if the cache location should be
#' written to the user's `.Renviron` file with default of \code{FALSE}.
#'
#' @return The string of the filepath set
#'
#' @family utils
#' @importFrom cli cli_abort cli_alert cli_inform
#' @export
#' @examplesIf interactive()
#' # Set to local directory
#' my_enw_cache <- enw_set_cache(file.path(tempdir(), "test"))
#' enw_get_cache()
#' \dontrun{
#' # Use the package cache in R >= 4.0
#' if (R.version.string >= 4.0) {
#'   enw_set_cache(tools::R_user_dir(package = "epinowcast", "cache"))
#' }
#'
#' }
enw_set_cache <- function(path, persistent = FALSE) {

  if (!is.character(path)) {
    cli::cli_abort("`path` must be a valid file path.")
  }

  cli::cli_inform(c(
    "i" = "Setting `enw_cache_location` to {path}" # nolint keyword_quote_linter
  ))

  prior_cache <- Sys.getenv("enw_cache_location", unset = "", names = NA)

  if (!check_environment_setting(prior_cache)) {
    cli::cli_alert("{prior_cache} exists and will be overwritten")
  }
  env_contents_active <- enw_get_environment_contents()

  candidate_path <- normalizePath(path, winslash = "\\", mustWork = FALSE)

  enw_environment <- paste0("enw_cache_location=\"", candidate_path, "\"\n")

  new_env_contents <- append(
    env_contents_active[["env_contents"]],
    enw_environment
  )

  if (isTRUE(persistent)) {
    writeLines(
      new_env_contents,
      con = env_contents_active[["env_path"]], sep = "\n"
    )
    cli::cli_inform(c(
      i = "Added `enw_cache_location` to `.Renviron` at {env_contents_active[['env_path']]}" # nolint line_length
    ))
    readRenviron(env_contents_active[["env_path"]])
  } else {
    Sys.setenv(enw_cache_location = candidate_path)
  }

  return(invisible(candidate_path))
}

#' Unset Stan cache location
#'
#' Removes `enw_cache_location` environment variable from
#' the user .Renviron file and removes it from the local
#' environment.
#'
#' @param persistent a logical representing if the cache location should be
#' removed from the user's `.Renviron` file with default of \code{FALSE}.
#'
#' @return the prior cache location, if it existed
#'
#' @importFrom cli cli_inform
#' @family utils
#' @export
#' @examplesIf interactive()
#' enw_unset_cache()
#'
#' enw_unset_cache(enw_set_cache(file.path(tempdir(), "test")))
enw_unset_cache <- function(persistent = FALSE) {
  prior_location <- Sys.getenv("enw_cache_location")
  if (prior_location != "") {
    cli::cli_inform(c(i = "Removing `enw_cache_location = {prior_location}`"))
    Sys.unsetenv("enw_cache_location")

    clean_environ <- enw_get_environment_contents(
      remove_enw_cache_location = TRUE
    )
    if (isTRUE(persistent)) {
      writeLines(clean_environ$env_contents, clean_environ$env_path)
      cli::cli_inform(c(
        i = "Removing `enw_cache_location = {prior_location}` from `.Renviron`"
      ))
    }

    invisible(enw_get_environment_contents(remove_enw_cache_location = TRUE))
  } else {
    cli::cli_inform(c(
      "!" = paste0(
        "`enw_cache_location` not set. ",
        "Nothing to remove from .Renviron or the local environment."
      )
    ))
  }

  return(invisible(prior_location))
}

#' Retrieve Stan cache location
#'
#' Retrieves the user set cache location for Stan models. This
#' path can be set through the `enw_cache_location` function call.
#' If no environmental variable is available the output from
#' `tempdir` will be returned.
#'
#' @return a string representing the file path for the cache location
#' @importFrom cli cli_inform
#' @family utils
#' @export
enw_get_cache <- function() {
  cache_location <- Sys.getenv("enw_cache_location")

  if (check_environment_setting(cache_location)) {
    cache_location <- tempdir()
    cli::cli_inform(c(
      "!" = "`enw_cache_location` not specified. Using `tempdir` at {cache_location}" # nolint line_length
    ))
  } else {
    cli::cli_inform(c(i = "Using `{cache_location}` for the cache location."))
  }

  return(cache_location)
}

#' Check environment setting
#'
#' This internal function checks whether a given environment variable is set or
#' not. It returns `TRUE` if the variable is either null or an empty string,
#' indicating that the environment variable is not set. Otherwise, it returns
#' `FALSE`.
#'
#' @param x The environment variable to be checked.
#'
#' @return Logical value indicating whether the environment variable is not set
#' (either null or an empty string).
#' @keywords internal
check_environment_setting <- function(x) {
  return(is.null(x) || x == "")
}

#' Identify cache location
#'
#' This function retrieves environment variable settings and manages the
#' `.Renviron` file in the user's project or home directory.
#' The project directory will be examined first, if it exists.
#' It can optionally remove the entry for `enw_cache_location`.
#'
#' @param remove_enw_cache_location Logical indicating whether to remove the
#' `enw_cache_location` entry from the `.Renviron` file. Defaults to `TRUE`.
#'
#' @return A list containing the contents of the `.Renviron` file and its path.
#' @keywords internal
enw_get_environment_contents <- function(remove_enw_cache_location = TRUE) {

  env_location <- getwd()

  if (file.exists(file.path(env_location, ".Renviron"))) {
    env_path <- file.path(env_location, ".Renviron")
  } else {
    env_location <- Sys.getenv("HOME")
    env_path <- file.path(env_location, ".Renviron")
  }

  if (!file.exists(env_path)) {
    file.create(env_path)
  }

  env_contents <- readLines(env_path)

  if (remove_enw_cache_location) {
    old_location <- grepl("enw_cache_location", env_contents, fixed = TRUE)
    env_contents <- env_contents[!old_location]
  }

  output <- list(
    env_contents = env_contents,
    env_path = env_path
  )

  return(output)
}

utils::globalVariables(
  c(
    ".", ".draw", "max_treedepth", "no_at_max_treedepth",
    "per_at_max_treedepth", "q20", "q5", "q80", "q95", "quantile",
    "sd", "..by", "cmf", "day_of_week", "delay", "new_confirm",
    "observed", ".old_group", "reference_date", "report_date",
    "reported_cases", "s", "time", "extend_date", "effects",
    "confirm", "effects", "fixed", ".group", "logmean", "logsd",
    ".new_group", "observed", "latest_confirm", "mad", "variable",
    "fit", "patterns", ".draws", "prop_reported", "max_confirm",
    "run_time", "cum_prop_reported", "..by_with_group_id",
    "reference_missing", "prop_missing", "day", "posteriors",
    "formula", ".id", "n", ".confirm_avail", "prediction", "true_value",
    "person", "id", "latest", "num_reference_date", "num_report_date",
    "rep_mod", "ref_mod", "count", "reference_date_mod", "report_date_mod",
    "timestep", ".observed", "lookup", "max_obs_delay"
  )
)

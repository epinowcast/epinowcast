#' Topologically sort a multi-stratum dependency graph
#'
#' @description Builds the dependency graph implied by the per-stratum
#' expectation specification and returns a topological ordering so that a
#' parent stratum is always evaluated before any stratum that depends on
#' it. Independent strata (those with their own latent process) have no
#' parent; dependent strata (those declared with [secondary()]) name a
#' single parent. Chains (`cases -> hosp -> deaths`) and shared parents
#' (a diamond) are allowed; cycles, self-dependencies, and references to
#' an unknown parent are errors.
#'
#' This is part of the Phase 0 R skeleton of the multi-stratum
#' expectation overlay (see the package issue tracker); it validates and
#' orders the graph but does not yet emit Stan data.
#'
#' @param strata_spec A named list keyed by stratum name. Each element
#' describes one stratum and must contain a logical `dependent` flag and,
#' when `dependent` is `TRUE`, a `parent` string naming the stratum it
#' depends on. The structure produced by [enw_expectation()] for a named
#' list `r` satisfies this; the `secondary` element (if present) is also
#' accepted as a source of the parent.
#'
#' @return A list with:
#'  - `order`: a character vector of stratum names in topological order
#'    (parents before dependents).
#'  - `parent`: a named character vector mapping each stratum to its
#'    parent, with `NA` for independent strata.
#'  - `dependent`: a named logical vector flagging dependent strata.
#'
#' @family strata
#' @importFrom cli cli_abort
#' @export
#' @examples
#' spec <- list(
#'   cases = list(dependent = FALSE),
#'   hosp = list(dependent = TRUE, parent = "cases"),
#'   deaths = list(dependent = TRUE, parent = "hosp")
#' )
#' enw_topo_sort_strata(spec)
enw_topo_sort_strata <- function(strata_spec) {
  if (!is.list(strata_spec) || length(strata_spec) == 0L) {
    cli::cli_abort("`strata_spec` must be a non-empty named list.")
  }
  strata_names <- names(strata_spec)
  if (is.null(strata_names) || !all(nzchar(strata_names)) ||
    anyDuplicated(strata_names)) {
    cli::cli_abort(
      "`strata_spec` must be named with unique, non-empty stratum names."
    )
  }

  parent <- vapply(
    strata_spec, .stratum_parent, character(1), USE.NAMES = FALSE
  )
  names(parent) <- strata_names
  dependent <- !is.na(parent)

  # Validate parents: must be known and not self-referential.
  for (s in strata_names) {
    p <- parent[[s]]
    if (is.na(p)) {
      next
    }
    if (identical(p, s)) {
      cli::cli_abort(
        "Stratum {.val {s}} depends on itself; self-dependencies are not allowed." # nolint: line_length_linter.
      )
    }
    if (!p %in% strata_names) {
      cli::cli_abort(
        "Stratum {.val {s}} depends on unknown parent {.val {p}}."
      )
    }
  }

  order <- .topo_order(strata_names, parent)

  list(
    order = order,
    parent = parent,
    dependent = dependent
  )
}

# Internal: extract a single parent string (or NA) from one stratum spec.
.stratum_parent <- function(spec) {
  if (!is.null(spec$secondary) && !is.null(spec$secondary$parent)) {
    return(spec$secondary$parent)
  }
  if (isTRUE(spec$dependent)) {
    if (is.null(spec$parent)) {
      cli::cli_abort(
        "A dependent stratum must supply a `parent`."
      )
    }
    return(spec$parent)
  }
  NA_character_
}

# Internal: Kahn's algorithm topological sort over the parent map.
# `parent` is a named character vector (NA for roots). Detects cycles by
# checking that every node is emitted.
.topo_order <- function(strata_names, parent) {
  # Children of each node, so we can decrement in-degrees as we emit.
  children <- stats::setNames(
    vector("list", length(strata_names)), strata_names
  )
  indegree <- stats::setNames(
    integer(length(strata_names)), strata_names
  )
  for (s in strata_names) {
    p <- parent[[s]]
    if (!is.na(p)) {
      children[[p]] <- c(children[[p]], s)
      indegree[[s]] <- indegree[[s]] + 1L
    }
  }

  queue <- strata_names[indegree == 0L]
  order <- character(0)
  while (length(queue) > 0L) {
    node <- queue[[1L]]
    queue <- queue[-1L]
    order <- c(order, node)
    for (child in children[[node]]) {
      indegree[[child]] <- indegree[[child]] - 1L
      if (indegree[[child]] == 0L) {
        queue <- c(queue, child)
      }
    }
  }

  if (length(order) != length(strata_names)) {
    cli::cli_abort(
      paste0(
        "Stratum dependency graph contains a cycle involving ",
        "{.val {setdiff(strata_names, order)}}."
      )
    )
  }
  order
}

# Internal: build the validated, topologically ordered per-stratum
# expectation structure from a named list `r` and the preprocessed data.
# Used by enw_expectation() in Phase 0. Returns a list with:
#  - `order`: topological stratum order (parents before dependents).
#  - `parent`/`dependent`: as returned by enw_topo_sort_strata().
#  - `strata`: per-stratum list of parsed specs (formula, dependent
#    flag, parent, and for dependents the constructed secondary term).
#  - `independent`/`dependent_strata`: name vectors for convenience.
#  - `primary_formula`: the formula of the first independent stratum,
#    used to drive the existing single-process Stan path in Phase 0.
.build_strata_spec <- function(r, data) {
  if (is.null(names(r)) || !all(nzchar(names(r))) ||
    anyDuplicated(names(r))) {
    cli::cli_abort(
      "A per-stratum `r` must be a named list with unique stratum names."
    )
  }
  strata_names <- names(r)

  valid <- .strata_from_data(data)
  if (!is.null(valid)) {
    unknown <- setdiff(strata_names, valid)
    if (length(unknown) > 0L) {
      cli::cli_abort(
        paste0(
          "Stratum names {.val {unknown}} are not present in the `by` ",
          "variable of the preprocessed data ({.val {valid}})."
        )
      )
    }
  }

  r_features <- data$metareference[[1]]
  strata <- stats::setNames(vector("list", length(strata_names)), strata_names)
  for (s in strata_names) {
    strata[[s]] <- .parse_stratum_formula(r[[s]], s, r_features)
  }

  # Validate parents referenced by secondary() terms are declared strata.
  for (s in strata_names) {
    p <- strata[[s]]$parent
    if (!is.na(p) && !p %in% strata_names) {
      cli::cli_abort(
        "Stratum {.val {s}} depends on undeclared stratum {.val {p}}."
      )
    }
  }

  topo <- enw_topo_sort_strata(strata)

  independent <- strata_names[!topo$dependent[strata_names]]
  if (length(independent) == 0L) {
    cli::cli_abort(
      "At least one stratum must have its own process (no `secondary()`)."
    )
  }

  list(
    order = topo$order,
    parent = topo$parent,
    dependent = topo$dependent,
    strata = strata,
    independent = independent,
    dependent_strata = strata_names[topo$dependent[strata_names]],
    primary_formula = strata[[independent[[1]]]]$formula
  )
}

# Internal: parse and validate a single per-stratum expectation formula.
.parse_stratum_formula <- function(formula, stratum, r_features) {
  if (!inherits(formula, "formula")) {
    cli::cli_abort(
      "The formula for stratum {.val {stratum}} must be a formula."
    )
  }
  if (as_string_formula(formula) == "~0") {
    cli::cli_abort(
      "The formula for stratum {.val {stratum}} must not be `~0`."
    )
  }
  parsed <- parse_formula(formula)
  is_secondary <- length(parsed$secondary) > 0L

  out <- list(
    formula = formula,
    dependent = is_secondary,
    parent = NA_character_,
    secondary = NULL
  )
  if (is_secondary) {
    # `enw_formula()` validates that secondary() is the only term and
    # constructs the secondary metadata.
    fobj <- enw_formula(formula, r_features, sparse = FALSE)
    out$secondary <- fobj$secondary
    out$parent <- fobj$secondary$parent
  }
  out
}

# Internal: extract the candidate stratum names from a preprocessed data
# object. Strata are the unique values of a single `by` variable. Returns
# NULL when there is no `by` (single, unnamed group) so name validation
# is skipped, and errors for multi-column `by` (unsupported in Phase 0).
.strata_from_data <- function(data) {
  by <- data$by[[1]]
  if (is.null(by) || length(by) == 0L) {
    return(NULL)
  }
  if (length(by) > 1L) {
    cli::cli_abort(
      paste0(
        "Per-stratum expectation formulas currently require a single ",
        "`by` variable; got {.val {by}}."
      )
    )
  }
  as.character(sort(unique(data$metareference[[1]][[by]])))
}

test_that("enw_topo_sort_strata() orders a simple chain", {
  spec <- list(
    cases = list(dependent = FALSE),
    hosp = list(dependent = TRUE, parent = "cases"),
    deaths = list(dependent = TRUE, parent = "hosp")
  )
  res <- enw_topo_sort_strata(spec)
  expect_identical(res$order, c("cases", "hosp", "deaths"))
  expect_identical(
    res$parent, c(cases = NA_character_, hosp = "cases", deaths = "hosp")
  )
  expect_identical(
    res$dependent, c(cases = FALSE, hosp = TRUE, deaths = TRUE)
  )
})

test_that("enw_topo_sort_strata() orders parents before dependents in a
  diamond", {
  spec <- list(
    a = list(dependent = FALSE),
    b = list(dependent = TRUE, parent = "a"),
    c = list(dependent = TRUE, parent = "a"),
    d = list(dependent = TRUE, parent = "b")
  )
  order <- enw_topo_sort_strata(spec)$order
  expect_lt(match("a", order), match("b", order))
  expect_lt(match("a", order), match("c", order))
  expect_lt(match("b", order), match("d", order))
})

test_that("enw_topo_sort_strata() reads parents from a secondary spec", {
  spec <- list(
    cases = list(dependent = FALSE),
    deaths = list(secondary = list(parent = "cases"))
  )
  res <- enw_topo_sort_strata(spec)
  expect_identical(res$order, c("cases", "deaths"))
  expect_true(res$dependent[["deaths"]])
})

test_that("enw_topo_sort_strata() detects cycles", {
  spec <- list(
    a = list(dependent = TRUE, parent = "b"),
    b = list(dependent = TRUE, parent = "a")
  )
  expect_error(enw_topo_sort_strata(spec), "cycle")
})

test_that("enw_topo_sort_strata() rejects self-dependencies", {
  spec <- list(a = list(dependent = TRUE, parent = "a"))
  expect_error(enw_topo_sort_strata(spec), "depends on itself")
})

test_that("enw_topo_sort_strata() rejects unknown parents", {
  spec <- list(
    a = list(dependent = FALSE),
    b = list(dependent = TRUE, parent = "z")
  )
  expect_error(enw_topo_sort_strata(spec), "unknown parent")
})

test_that("enw_topo_sort_strata() validates its input", {
  expect_error(enw_topo_sort_strata(list()), "non-empty named list")
  expect_error(
    enw_topo_sort_strata(list(list(dependent = FALSE))),
    "unique, non-empty"
  )
})

test_that(".resolve_stratum_spec() broadcasts a scalar across strata", {
  res <- .resolve_stratum_spec("negbin", c("cases", "deaths"))
  expect_true(res$shared)
  expect_identical(res$values, list(cases = "negbin", deaths = "negbin"))
})

test_that(".resolve_stratum_spec() resolves a per-stratum named list", {
  res <- .resolve_stratum_spec(
    list(cases = "negbin", deaths = "poisson"), c("cases", "deaths")
  )
  expect_false(res$shared)
  expect_identical(res$values, list(cases = "negbin", deaths = "poisson"))
})

test_that(".resolve_stratum_spec() treats an unnamed list as shared", {
  res <- .resolve_stratum_spec(list(1, 2), c("cases", "deaths"))
  expect_true(res$shared)
  expect_identical(res$values$cases, list(1, 2))
})

test_that(".resolve_stratum_spec() errors on missing strata", {
  expect_error(
    .resolve_stratum_spec(list(cases = "negbin"), c("cases", "deaths")),
    "missing strata"
  )
})

test_that(".resolve_stratum_spec() validates strata_names", {
  expect_error(
    .resolve_stratum_spec("negbin", character(0)),
    "non-empty vector of unique"
  )
  expect_error(
    .resolve_stratum_spec("negbin", c("a", "a")),
    "non-empty vector of unique"
  )
})

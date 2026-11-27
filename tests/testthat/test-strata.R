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


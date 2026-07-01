test_that("secondary() builds an enw_secondary_term with defaults", {
  s <- secondary(cases)
  expect_s3_class(s, "enw_secondary_term")
  expect_identical(s$parent, "cases")
  expect_identical(s$distribution, "lognormal")
  expect_identical(s$type, "incidence")
  expect_s3_class(s$delay, "formula")
  expect_s3_class(s$report, "formula")
  expect_s3_class(s$ascertainment, "formula")
})

test_that("secondary() accepts an unquoted name or a string parent", {
  expect_identical(secondary(cases)$parent, "cases")
  expect_identical(secondary("cases")$parent, "cases")
})

test_that("secondary() captures the supplied surfaces and options", {
  s <- secondary(
    cases,
    delay = ~ 1 + week, distribution = "gamma",
    report = ~ 1 + day_of_week, ascertainment = ~ 1 + (1 | region),
    type = "prevalence"
  )
  expect_identical(s$distribution, "gamma")
  expect_identical(s$type, "prevalence")
  expect_identical(as_string_formula(s$delay), "~1 + week")
  expect_identical(as_string_formula(s$report), "~1 + day_of_week")
  expect_identical(as_string_formula(s$ascertainment), "~1 + (1 | region)")
})

test_that("secondary() validates its arguments", {
  expect_error(secondary(), "must be present")
  expect_error(
    secondary(cases, distribution = "weibull"), "must be one of"
  )
  expect_error(secondary(cases, delay = 5), "must be a formula")
  expect_error(secondary(cases, report = "x"), "must be a formula")
  expect_error(
    secondary(cases, ascertainment = 1), "must be a formula"
  )
  expect_error(secondary(cases, type = "other"), "must be one of")
})

test_that("construct_secondary() returns the dependency metadata", {
  m <- construct_secondary(secondary(cases, distribution = "gamma"))
  expect_identical(m$parent, "cases")
  expect_identical(m$distribution, "gamma")
  expect_identical(m$name, "secondary__cases")
})

test_that("construct_secondary() rejects non-secondary terms", {
  expect_error(
    construct_secondary(gp(week)), "must be constructed by"
  )
})

test_that("secondary_terms() and remove_secondary_terms() find/strip", {
  expect_identical(
    secondary_terms(~ secondary(cases)), "secondary(cases)"
  )
  expect_length(secondary_terms(~ 1 + week), 0L)
  expect_identical(
    as_string_formula(remove_secondary_terms(~ 1 + secondary(cases))),
    "~1"
  )
})

test_that("parse_formula() routes secondary() terms", {
  pf <- parse_formula(~ secondary(cases, delay = ~ 1 + week))
  expect_identical(pf$secondary, "secondary(cases, delay = ~1 + week)")
  expect_identical(pf$fixed, "1")
})

test_that("enw_formula() recognises a secondary-only stratum formula", {
  f <- enw_formula(~ secondary(cases), data = data.frame(week = 1:3))
  expect_s3_class(f, "enw_formula")
  expect_identical(f$secondary$parent, "cases")
  expect_null(f$fixed)
})

test_that("enw_formula() errors on secondary() combined with other terms", {
  expect_error(
    enw_formula(~ 1 + week + secondary(cases), data = data.frame(week = 1:3)),
    "must be the only term"
  )
  expect_error(
    enw_formula(
      ~ secondary(cases) + rw(week),
      data = data.frame(week = 1:3)
    ),
    "must be the only term"
  )
})

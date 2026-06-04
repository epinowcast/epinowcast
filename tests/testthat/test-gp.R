# Tests for the gp() formula helper, parser, and constructor.

obs <- enw_filter_report_dates(
  germany_covid19_hosp[location == "DE"][age_group == "00+"],
  remove_days = 10
)
obs <- enw_filter_reference_dates(obs, include_days = 60)
pobs <- suppressWarnings(enw_preprocess_data(
  obs, by = c("age_group", "location"), max_delay = 14
))
data <- pobs$metareference[[1]]

test_that("gp() returns an enw_gp_term with the expected fields", {
  a <- gp(week)
  expect_s3_class(a, "enw_gp_term")
  expect_identical(a$time, "week")
  expect_null(a$by)
  expect_identical(a$kernel, "matern32")
  expect_identical(a$basis_prop, 0.2)

  b <- gp(week, day_of_week, kernel = "se", basis_prop = 0.5)
  expect_identical(b$by, "day_of_week")
  expect_identical(b$kernel, "se")
  expect_identical(b$basis_prop, 0.5)
})

test_that("gp() maps kernel aliases to the right Stan gp_type/nu", {
  expect_identical(gp(week, kernel = "matern32")$gp_type, 2L)
  expect_identical(gp(week, kernel = "matern32")$nu, 1.5)
  expect_identical(gp(week, kernel = "ou")$nu, 0.5)
  expect_identical(gp(week, kernel = "se")$gp_type, 0L)
  expect_identical(gp(week, kernel = "periodic")$gp_type, 1L)
})

test_that("gp() rejects invalid hyperparameters", {
  expect_error(gp(week, kernel = "nonsense"), "kernel")
  expect_error(gp(week, basis_prop = 0), "basis_prop")
  expect_error(gp(week, basis_prop = -1), "basis_prop")
  expect_error(gp(week, basis_prop = "x"), "basis_prop")
  expect_error(gp(week, boundary_scale = 0), "boundary_scale")
})

test_that("gp() requires a time argument", {
  expect_error(gp(), "time")
})

test_that("gp_terms() picks out gp calls only", {
  expect_identical(
    gp_terms(~ 1 + age_group + gp(week)),
    "gp(week)"
  )
  expect_identical(
    gp_terms(~ 1 + gp(week, kernel = "se") + gp(day)),
    c("gp(week, kernel = \"se\")", "gp(day)")
  )
  expect_identical(gp_terms(~ 1 + age_group + arima(week)), character(0))
  # Must not match inside a random effect term.
  expect_identical(gp_terms(~ 1 + (1 | gp)), character(0))
})

test_that("remove_gp_terms() strips gp calls", {
  expect_identical(
    format(remove_gp_terms(~ 1 + age_group + gp(week))),
    "~1 + age_group"
  )
  expect_identical(
    format(remove_gp_terms(~ 1 + gp(week) + gp(day))),
    "~1"
  )
  # Leaves other terms (including arima) untouched.
  expect_identical(
    format(remove_gp_terms(~ 1 + arima(week) + gp(day))),
    "~1 + arima(week)"
  )
})

test_that("parse_formula() routes gp terms separately", {
  parsed <- parse_formula(~ 1 + age_group + gp(week) + arima(day))
  expect_identical(parsed$gp, "gp(week)")
  expect_identical(parsed$arima, "arima(day)")
  expect_identical(parsed$fixed, c("1", "age_group"))
})

test_that("construct_gp() builds correct basis metadata", {
  spec <- construct_gp(gp(week), data)
  expect_identical(spec$T, length(unique(data$week)))
  expect_identical(spec$G, 1L)
  expect_identical(length(spec$time_idx), nrow(data))
  expect_true(all(spec$time_idx >= 1L & spec$time_idx <= spec$T))
  expect_true(all(spec$group_idx == 1L))
  expect_identical(spec$gp_type, 2L)
  expect_identical(spec$nu, 1.5)
  # M = ceiling(T * basis_prop)
  expect_identical(spec$M, as.integer(ceiling(spec$T * 0.2)))
  # Basis matrix PHI is T x M.
  expect_identical(dim(spec$PHI), c(spec$T, spec$M))

  grouped <- construct_gp(gp(week, day_of_week), data)
  expect_identical(grouped$G, length(unique(data$day_of_week)))
  expect_true(all(grouped$group_idx >= 1L & grouped$group_idx <= grouped$G))
})

test_that("construct_gp() errors on missing or non-numeric time", {
  expect_error(construct_gp(gp(missing_var), data), "not present")
  data2 <- data.table::copy(data)
  data2[, day_of_week := as.character(day_of_week)]
  expect_error(construct_gp(gp(day_of_week), data2), "must be numeric")
})

test_that("construct_gp() rejects a term it did not build", {
  expect_error(
    construct_gp(list(time = "week"), data),
    "constructed by"
  )
})

test_that("enw_formula() collects gp specs alongside fixed/random", {
  f <- enw_formula(~ 1 + (1 | day_of_week) + gp(week), data)
  expect_s3_class(f, "enw_formula")
  expect_length(f$gp, 1L)
  expect_identical(f$gp[[1]]$gp_type, 2L)
  expect_false(any(grepl("gp", colnames(f$fixed$design))))
})

test_that("enw_formula_as_data_list() ships the gp Stan data", {
  f <- enw_formula(~ 1 + gp(week, day_of_week), data)
  dl <- enw_formula_as_data_list(f, "ref")

  expect_identical(dl$ref_gp_present, 1L)
  expect_identical(dl$ref_gp_type, 2L)
  expect_identical(dl$ref_gp_nu, 1.5)
  expect_identical(dl$ref_gp_T, length(unique(data$week)))
  expect_identical(dl$ref_gp_G, length(unique(data$day_of_week)))
  expect_identical(dl$ref_gp_M, as.integer(ceiling(dl$ref_gp_T * 0.2)))
  expect_identical(dim(dl$ref_gp_PHI), c(dl$ref_gp_T, dl$ref_gp_M))

  spec <- construct_gp(gp(week, day_of_week), data)
  expect_identical(
    dl$ref_gp_flat_idx,
    as.integer((spec$group_idx - 1L) * spec$T + spec$time_idx)
  )
  expect_true(all(
    dl$ref_gp_flat_idx >= 1L &
      dl$ref_gp_flat_idx <= dl$ref_gp_T * dl$ref_gp_G
  ))
})

test_that("enw_formula_as_data_list() returns inert defaults without gp", {
  f <- enw_formula(~ 1 + (1 | day_of_week), data)
  dl <- enw_formula_as_data_list(f, "ref")
  expect_identical(dl$ref_gp_present, 0L)
  expect_identical(dl$ref_gp_T, 0L)
  expect_identical(dl$ref_gp_M, 0L)
  expect_identical(dl$ref_gp_n_obs, 0L)
})

test_that("enw_formula_as_data_list() rejects multiple gp terms", {
  expect_error(
    enw_formula_as_data_list(
      enw_formula(~ 1 + gp(week) + gp(month), data),
      "ref"
    ),
    "Only one `gp\\(\\)` term"
  )
})

test_that("enw_expectation() wires a gp() growth-rate term to Stan", {
  exp <- enw_expectation(r = ~ 1 + gp(week), data = pobs)
  expect_identical(exp$data$expr_gp_present, 1L)
  expect_identical(exp$data$expr_gp_type, 2L)
  expect_true(exp$data$expr_gp_M > 0L)
  # GP length-scale and magnitude priors must be exposed as data.
  expect_true("expr_gp_rho" %in% exp$priors$variable)
  expect_true("expr_gp_alpha" %in% exp$priors$variable)
})

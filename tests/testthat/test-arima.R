# Tests for the arima() formula helper, parser, and constructor.

obs <- enw_filter_report_dates(
  germany_covid19_hosp[location == "DE"][age_group == "00+"],
  remove_days = 10
)
obs <- enw_filter_reference_dates(obs, include_days = 60)
pobs <- suppressWarnings(enw_preprocess_data(
  obs, by = c("age_group", "location"), max_delay = 14
))
data <- pobs$metareference[[1]]

test_that("arima() returns an enw_arima_term with the expected fields", {
  a <- arima(week)
  expect_s3_class(a, "enw_arima_term")
  expect_identical(a$time, "week")
  expect_null(a$by)
  expect_identical(a$p, 1L)
  expect_identical(a$d, 0L)
  expect_identical(a$q, 0L)
  expect_identical(a$type, "dependent")

  b <- arima(week, day_of_week, p = 2, d = 1, q = 1, type = "dependent")
  expect_identical(b$by, "day_of_week")
  expect_identical(b$p, 2L)
  expect_identical(b$d, 1L)
  expect_identical(b$q, 1L)
  expect_identical(b$type, "dependent")
})

test_that("arima() rejects invalid orders", {
  expect_error(arima(week, p = -1), "non-negative integer")
  expect_error(arima(week, d = 1.5), "non-negative integer")
  expect_error(arima(week, p = 0, d = 0, q = 0), "degenerate")
})

test_that("arima_terms() picks out arima calls only", {
  expect_identical(
    arima_terms(~ 1 + age_group + arima(week)),
    "arima(week)"
  )
  expect_identical(
    arima_terms(~ 1 + arima(week, day_of_week, p = 2)),
    "arima(week, day_of_week, p = 2)"
  )
  expect_identical(
    arima_terms(~ 1 + age_group + rw(week)),
    character(0)
  )
})

test_that("remove_arima_terms() strips arima calls", {
  f <- remove_arima_terms(~ 1 + age_group + arima(week))
  expect_identical(format(f), "~1 + age_group")

  f <- remove_arima_terms(~ 1 + arima(week) + age_group)
  expect_identical(format(f), "~1 + age_group")
})

test_that("parse_formula() routes arima terms separately from rw and fixed", {
  p <- parse_formula(~ 1 + age_group + arima(week, p = 1, d = 1))
  expect_identical(p$arima, "arima(week, p = 1, d = 1)")
  expect_identical(p$rw, character(0))
  expect_identical(p$fixed, c("1", "age_group"))
})

test_that("construct_arima() builds correct lookup metadata", {
  spec <- construct_arima(arima(week), data)
  expect_identical(spec$T, length(unique(data$week)))
  expect_identical(spec$G, 1L)
  expect_identical(length(spec$time_idx), nrow(data))
  expect_true(all(spec$time_idx >= 1L & spec$time_idx <= spec$T))
  expect_true(all(spec$group_idx == 1L))
  expect_identical(spec$p, 1L)
  expect_identical(spec$d, 0L)
  expect_identical(spec$q, 0L)

  grouped <- construct_arima(
    arima(week, day_of_week, p = 1, d = 1, q = 1), data
  )
  expect_identical(grouped$G, length(unique(data$day_of_week)))
  expect_true(all(grouped$group_idx >= 1L & grouped$group_idx <= grouped$G))
  expect_identical(grouped$p, 1L)
  expect_identical(grouped$d, 1L)
  expect_identical(grouped$q, 1L)
})

test_that("construct_arima() rejects too-short series", {
  expect_error(
    construct_arima(arima(week, p = 100), data),
    "ARIMA series has only"
  )
})

test_that("construct_arima() errors on missing or non-numeric time", {
  expect_error(
    construct_arima(arima(missing_var), data),
    "not present"
  )
  data2 <- data.table::copy(data)
  data2[, day_of_week := as.character(day_of_week)]
  expect_error(
    construct_arima(arima(day_of_week), data2),
    "must be numeric"
  )
})

test_that("enw_formula() collects arima specs alongside fixed/random/rw", {
  f <- enw_formula(
    ~ 1 + (1 | day_of_week) + arima(week, p = 2, d = 1, q = 1),
    data
  )
  expect_s3_class(f, "enw_formula")
  expect_length(f$arima, 1L)
  expect_identical(f$arima[[1]]$p, 2L)
  expect_identical(f$arima[[1]]$d, 1L)
  expect_identical(f$arima[[1]]$q, 1L)
  # The arima term must not have leaked into the fixed design
  expect_false(any(grepl("arima", colnames(f$fixed$design))))
})

test_that("enw_formula_as_data_list() ships the arima Stan data", {
  f <- enw_formula(
    ~ 1 + arima(week, day_of_week, p = 1, d = 1, type = "dependent"),
    data
  )
  dl <- enw_formula_as_data_list(f, "ref")

  expect_identical(dl$ref_arima_present, 1L)
  expect_identical(dl$ref_arima_p, 1L)
  expect_identical(dl$ref_arima_d, 1L)
  expect_identical(dl$ref_arima_q, 0L)
  expect_identical(dl$ref_arima_type, 1L) # 1 == "dependent"
  expect_identical(dl$ref_arima_T, length(unique(data$week)))
  expect_identical(dl$ref_arima_G, length(unique(data$day_of_week)))
  expect_identical(length(dl$ref_arima_flat_idx), nrow(data))
})

test_that("enw_formula_as_data_list() returns inert defaults without arima", {
  f <- enw_formula(~ 1 + (1 | day_of_week), data)
  dl <- enw_formula_as_data_list(f, "ref")
  expect_identical(dl$ref_arima_present, 0L)
  expect_identical(dl$ref_arima_T, 0L)
  expect_identical(dl$ref_arima_n_obs, 0L)
})

test_that("enw_formula_as_data_list() rejects multiple arima terms", {
  expect_error(
    enw_formula_as_data_list(
      structure(
        list(
          fixed = list(design = matrix(1, 1, 1), index = 1L),
          random = list(design = matrix(1, 1, 1)),
          arima = list(list(), list())
        ),
        class = "enw_formula"
      ),
      "ref"
    ),
    "Only one"
  )
})

test_that(
  "enw_expectation() supports an arima() term on the growth rate", {
    skip_on_cran()
    skip_on_os("windows")
    skip_on_local()
    pobs <- enw_example("preprocessed")
    exp <- enw_expectation(
      r = ~ 1 + arima(day, p = 1, d = 1), data = pobs
    )
    expect_identical(exp$data$expr_arima_present, 1L)
    expect_identical(exp$data$expr_arima_p, 1L)
    expect_identical(exp$data$expr_arima_d, 1L)
    expect_true(any(exp$priors$variable == "expr_arima_sigma"))
    fit <- epinowcast(
      pobs,
      expectation = exp,
      fit = enw_fit_opts(
        save_warmup = FALSE, pp = FALSE, chains = 2, parallel_chains = 2,
        iter_warmup = 250, iter_sampling = 250, show_messages = FALSE,
        show_exceptions = FALSE, refresh = 0, adapt_delta = 0.95
      )
    )
    draws <- summary(fit, type = "fit")
    arima_pars <- draws[grepl("expr_arima_(pacf|sigma)", variable)]
    expect_true(nrow(arima_pars) >= 2)
    expect_true(all(arima_pars$rhat < 1.1))
  }
)

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

  b <- arima(week, day_of_week, p = 2, d = 1, q = 1)
  expect_identical(b$by, "day_of_week")
  expect_identical(b$p, 2L)
  expect_identical(b$d, 1L)
  expect_identical(b$q, 1L)
})

test_that("ar(), ma(), arma() aliases produce the right enw_arima_term", {
  ar1 <- ar(week)
  expect_s3_class(ar1, "enw_arima_term")
  expect_identical(c(ar1$p, ar1$d, ar1$q), c(1L, 0L, 0L))

  ar2 <- ar(week, location, p = 2)
  expect_identical(ar2$by, "location")
  expect_identical(c(ar2$p, ar2$d, ar2$q), c(2L, 0L, 0L))

  ma1 <- ma(week, q = 2)
  expect_identical(c(ma1$p, ma1$d, ma1$q), c(0L, 0L, 2L))

  arma1 <- arma(week, location, p = 1, q = 1)
  expect_identical(arma1$by, "location")
  expect_identical(c(arma1$p, arma1$d, arma1$q), c(1L, 0L, 1L))
})

test_that("arima_terms() picks up ar/ma/arma alias calls", {
  expect_identical(
    arima_terms(~ 1 + age_group + ar(week, p = 2)),
    "ar(week, p = 2)"
  )
  expect_identical(
    arima_terms(~ 1 + ar(week) + ma(day) + arma(month, p = 1, q = 1)),
    c("ar(week)", "ma(day)", "arma(month, p = 1, q = 1)")
  )
})

test_that("remove_arima_terms() strips ar/ma/arma alias calls", {
  expect_identical(
    format(remove_arima_terms(~ 1 + age_group + ar(week, p = 2))),
    "~1 + age_group"
  )
  expect_identical(
    format(remove_arima_terms(~ 1 + ar(week) + ma(day))),
    "~1"
  )
})

test_that("arima() rejects invalid orders", {
  expect_error(arima(week, p = -1), "non-negative integer")
  expect_error(arima(week, d = 1.5), "non-negative integer")
  expect_error(arima(week, p = NA), "non-negative integer")
  expect_error(arima(week, q = Inf), "non-negative integer")
  expect_error(arima(week, p = c(1, 2)), "non-negative integer")
  expect_error(arima(week, p = "x"), "non-negative integer")
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
    ~ 1 + arima(week, day_of_week, p = 1, d = 1),
    data
  )
  dl <- enw_formula_as_data_list(f, "ref")

  expect_identical(dl$ref_arima_present, 1L)
  expect_identical(dl$ref_arima_p, 1L)
  expect_identical(dl$ref_arima_d, 1L)
  expect_identical(dl$ref_arima_q, 0L)
  expect_identical(dl$ref_arima_T, length(unique(data$week)))
  expect_identical(dl$ref_arima_G, length(unique(data$day_of_week)))

  # flat_idx must be the column-major (T x G) index for each observation,
  # (group_idx - 1) * T + time_idx, so the Stan-side gather picks the
  # right latent cell. Check the values, not just the length.
  spec <- construct_arima(arima(week, day_of_week, p = 1, d = 1), data)
  expect_identical(
    dl$ref_arima_flat_idx,
    as.integer((spec$group_idx - 1L) * spec$T + spec$time_idx)
  )
  expect_true(all(
    dl$ref_arima_flat_idx >= 1L &
      dl$ref_arima_flat_idx <= dl$ref_arima_T * dl$ref_arima_G
  ))
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

test_that("arima helpers require a time argument", {
  expect_error(arima(), "`time` must be present")
  expect_error(rw(), "`time` must be present")
  expect_error(ar(), "`time` must be present")
  expect_error(ma(), "`time` must be present")
  expect_error(arma(), "`time` must be present")
})

test_that("parse_formula() rejects non-formula input", {
  expect_error(parse_formula("a + b"), "must be a formula")
})

test_that("remove_rw_terms()/remove_arima_terms() fall back to ~1", {
  # stripping the only term leaves an empty formula, which must degrade
  # to an intercept-only formula rather than erroring.
  expect_identical(format(remove_rw_terms(~ rw(week))), "~1")
  expect_identical(format(remove_arima_terms(~ arima(week))), "~1")
})

test_that("construct_arima() rejects a term it did not build", {
  expect_error(
    construct_arima(list(time = "week", p = 1, d = 0, q = 0), data),
    "constructed by"
  )
})

test_that("construct_arima() errors on missing values or absent group", {
  d_na_time <- data.table::copy(data)
  d_na_time[1, week := NA]
  expect_error(construct_arima(arima(week), d_na_time), "missing values")

  expect_error(
    construct_arima(arima(week, not_a_column), data), "not present"
  )

  d_na_by <- data.table::copy(data)
  d_na_by[1, day_of_week := NA]
  expect_error(
    construct_arima(arima(week, day_of_week), d_na_by), "missing values"
  )
})

test_that("construct_arima() ignores a grouping variable with one level", {
  one_level <- data.table::copy(data)
  one_level[, single := 1L]
  expect_message(
    spec <- construct_arima(arima(week, single), one_level),
    "fewer than 2 levels"
  )
  expect_identical(spec$G, 1L)
  expect_true(all(spec$group_idx == 1L))
})

test_that(".arima_inits() sizes AR, MA and sd-scale inits to the orders", {
  data_list <- list(
    refp_arima_T = 5L, refp_arima_G = 2L, refp_arima_p = 2L,
    refp_arima_q = 1L, refp_arima_present = 1L, model_refp = 2L
  )
  priors <- list(
    refp_arima_sigma_p = c(0, 1), refp_arima_sd_sigma_p = c(0, 1)
  )
  init <- .arima_inits(data_list, priors, "refp", with_sd_sigma = TRUE)
  expect_length(init$refp_arima_pacf, 2L) # p = 2
  expect_length(init$refp_arima_theta, 1L) # q = 1
  expect_length(init$refp_arima_z, 10L) # T * G
  expect_length(init$refp_arima_sigma, 1L)
  expect_length(init$refp_arima_sd_sigma, 1L) # filled when model_refp > 1
  expect_true(all(abs(init$refp_arima_pacf) < 1))
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
    # Posterior may cap ESS for the small-iter integration fit and emit
    # a benign warning; the convergence check below is what matters.
    draws <- suppressWarnings(summary(fit, type = "fit"))
    arima_pars <- draws[grepl("expr_arima_(pacf|sigma)", variable)]
    expect_true(nrow(arima_pars) >= 2)
    expect_true(all(arima_pars$rhat < 1.1))
  }
)

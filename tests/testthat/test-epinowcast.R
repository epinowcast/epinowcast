# load example preprocessed data (already regression tested)
pobs <- enw_example("preprocessed")
if (not_on_cran()) {
  model <- enw_model()
  options(mc.cores = 2)
  silent_enw_sample <- function(...) {
    utils::capture.output(
      fit <- suppressMessages(enw_sample(...))
    )
    return(fit)
  }
}

test_that("epinowcast preprocesses data and model modules as expected", {
  nowcast <- suppressMessages(epinowcast(pobs,
    fit = enw_fit_opts(
      sampler = function(init, data, ...) {
        return(data.table::data.table(init = list(init), data = list(data)))
      },
      save_warmup = FALSE, pp = TRUE,
      chains = 2, iter_warmup = 500, iter_sampling = 500
    ),
    model = NULL
  ))
  expect_true(is.list(nowcast$data[[1]]))
  expect_error(nowcast$init())
  class(pobs) <- c("epinowcast", class(pobs))
  expect_equal(nowcast[, c("init", "data") := NULL], pobs)
})

test_that("epinowcast can fit a simple reporting model", {
  skip_on_cran()
  nowcast <- suppressMessages(epinowcast(pobs,
    fit = enw_fit_opts(
      sampler = silent_enw_sample,
      save_warmup = FALSE, pp = TRUE,
      chains = 2, iter_warmup = 500, iter_sampling = 500,
      refresh = 0, show_messages = FALSE
    ),
    model = model
  ))

  expect_equal(
    setdiff(colnames(nowcast), colnames(pobs)),
    c(
      "fit", "data", "fit_args", "samples", "max_rhat",
      "divergent_transitions", "per_divergent_transitions", "max_treedepth",
      "no_at_max_treedepth", "per_at_max_treedepth", "run_time"
    )
  )
  expect_equal(class(nowcast$fit[[1]])[1], "CmdStanMCMC")
  expect_type(nowcast$fit_args[[1]], "list")
  expect_type(nowcast$data[[1]], "list")
  expect_lt(nowcast$per_divergent_transitions, 0.05)
  expect_lt(nowcast$max_treedepth, 10)
  expect_lt(nowcast$max_rhat, 1.05)
  expect_error(
    nowcast$fit[[1]]$summary(c("refp_mean_int", "refp_sd_int", "sqrt_phi")), NA
  )
  expect_error(nowcast$fit[[1]]$summary("refp_beta"))
  expect_error(nowcast$fit[[1]]$summary("rep_beta"))
})

test_that("epinowcast can fit a reporting model with a day of the week random
           effect", {
  skip_on_cran()
  regression_nowcast <- enw_example("nowcast")
  nowcast <- suppressMessages(epinowcast(pobs,
    report = enw_report(~ 1 + (1 | day_of_week), data = pobs),
    fit = enw_fit_opts(
      sampler = silent_enw_sample,
      save_warmup = FALSE, pp = TRUE,
      chains = 2, iter_warmup = 500, iter_sampling = 500,
      refresh = 0, show_messages = FALSE
    ),
    model = model
  ))
  expect_equal(class(nowcast$fit[[1]])[1], "CmdStanMCMC")
  expect_type(nowcast$fit_args[[1]], "list")
  expect_type(nowcast$data[[1]], "list")
  expect_lt(nowcast$per_divergent_transitions, 0.05)
  expect_lt(nowcast$max_treedepth, 10)
  expect_lt(nowcast$max_rhat, 1.05)
  posterior <- as.data.table(nowcast$fit[[1]]$summary())
  regression_posterior <- as.data.table(regression_nowcast$fit[[1]]$summary())
  expect_equal(
    posterior$variable,
    regression_posterior$variable
  )
})

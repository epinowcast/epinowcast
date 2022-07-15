# load example preprocessed data (already regression tested)
pobs <- enw_example("preprocessed")
model <- enw_model()

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
  nowcast <- epinowcast(pobs,
    fit = enw_fit_opts(
      save_warmup = FALSE, pp = TRUE,
      chains = 2, iter_warmup = 500, iter_sampling = 500
    ),
    model = model
  )
})

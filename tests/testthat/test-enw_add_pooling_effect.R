test_that("enw_add_pooling_effect can add a pooling effect", {
  data <- data.frame(a = 1:3, b = as.character(1:3), c = c(1, 1, 2))
  design <- enw_design(a ~ b + c, data)$design
  effects <- enw_effects_metadata(design)
  expect_equal(
    enw_add_pooling_effect(effects, prefix = "b"),
    data.table::data.table(
      effects = c("b2", "b3", "c"),
      fixed = c(0, 0, 1),
      sd = c(1, 1, 0)
    )
  )
})

test_that("enw_add_pooling_effect handles more general functions", {
  data <- data.frame(a = 1:3, b = as.character(1:3), c = c(1, 1, 2))
  design <- enw_design(a ~ b + c, data)$design
  effects1 <- enw_effects_metadata(design)
  effects2 <- enw_effects_metadata(design)
  dummyfn <- function(x, prefix, dummy) {
    startsWith(x, prefix) & dummy
  }
  expect_equal(
    enw_add_pooling_effect(
      effects1,
      finder_fn = dummyfn, prefix = "b", dummy = TRUE
    ),
    data.table::data.table(
      effects = c("b2", "b3", "c"),
      fixed = c(0, 0, 1),
      sd = c(1, 1, 0)
    )
  )
  expect_equal(
    enw_add_pooling_effect(
      effects2,
      finder_fn = dummyfn, prefix = "b", dummy = FALSE
    ),
    data.table::data.table(
      effects = c("b2", "b3", "c"),
      fixed = c(1, 1, 1),
      sd = c(0, 0, 0)
    )
  )
})

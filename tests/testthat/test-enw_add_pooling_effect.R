test_that("enw_add_pooling_effect can add a pooling effect", {
  data <- data.frame(a = 1:3, b = as.character(1:3), c = c(1,1,2))
  design <- enw_design(a ~ b + c, data)$design
  effects <- enw_effects_metadata(design)
  expect_equal(
    enw_add_pooling_effect(effects, string = "b"),
    data.table::data.table(
      effects = c("b2", "b3", "c"),
      fixed = c(0, 0, 1),
      sd = c(1, 1, 0)
    )
  )
})
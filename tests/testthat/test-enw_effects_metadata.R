test_that(
  "enw_effects_metadata can make a data table of design matrix effects",
  {
    data <- data.frame(
      a = 1:3,
      b = as.character(1:3),
      c = c(1, 1, 2)
    )
    design <- enw_design(a ~ b + c, data)$design
    expect_identical(
      enw_effects_metadata(design),
      data.table::data.table(
        effects = c("b2", "b3", "c"), fixed = 1
      )
    )
  }
)

test_cars <- data.table::as.data.table(mtcars)[1:5, ]

test_that("enw_formula_as_data_list fails when expected", {
  expect_error(enw_formula_as_data_list(~ 1 + 1))
  expect_error(enw_formula_as_data_list(enw_formula(~1, test_cars)))
})

test_that(
  "enw_formula_as_data_list produces expected output using a simple formula",
  {
    expect_snapshot(
      enw_formula_as_data_list(
        enw_formula(~ 1 + (1 | cyl), test_cars),
        prefix = "simple"
      )
    )
    expect_snapshot(
      enw_formula_as_data_list(
        enw_formula(~ 0 + (1 | cyl), test_cars),
        prefix = "simple"
      )
    )
    expect_snapshot(
      enw_formula_as_data_list(
        enw_formula(~ 1 + (1 | cyl), test_cars),
        prefix = "simple", drop_intercept = TRUE
      )
    )
  }
)

test_that("enw_formula_as_data_list produces expected output using a more complex formula", { # nolint: line_length_linter.
  expect_snapshot(
    enw_formula_as_data_list(
      enw_formula(~ 1 + disp + (1 + gear | cyl) + (0 + wt | am), test_cars),
      prefix = "complex"
    )
  )
  expect_snapshot(
    enw_formula_as_data_list(
      enw_formula(
        ~ 1 + disp + (1 + gear | cyl) + (0 + wt | am), test_cars
      ),
      prefix = "comple", drop_intercept = TRUE
    )
  )
})

test_that("enw_formula_as_data_list produces expected default output", {
  expect_identical(
    enw_formula_as_data_list(
      prefix = "c"
    ),
    list(
      c_fdesign = numeric(0), c_fintercept = 0, c_fnrow = 0,
      c_findex = numeric(0), c_fnindex = 0,
      c_fncol = 0, c_rdesign = numeric(0), c_rncol = 0
    )
  )
})

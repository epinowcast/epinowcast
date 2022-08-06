test_that("enw_formula_as_data_list fails when expected", {
  expect_error(enw_formula_as_data_list(~ 1 + 1))
  expect_error(enw_formula_as_data_list(enw_formula(~1, mtcars)))
})

test_that("enw_formula_as_data_list produces expected output using a simple
           formula", {
  expect_snapshot(
    enw_formula_as_data_list(
      enw_formula(~ 1 + (1 | cyl), mtcars),
      prefix = "simple"
    )
  )
  expect_snapshot(
    enw_formula_as_data_list(
      enw_formula(~ 1 + (1 | cyl), mtcars),
      prefix = "simple", drop_intercept = TRUE
    )
  )
})

test_that("enw_formula_as_data_list produces expected output using a more
           complex formula", {
  expect_snapshot(
    enw_formula_as_data_list(
      enw_formula(~ 1 + disp + (1 + gear | cyl) + (0 + wt | am), mtcars),
      prefix = "complex"
    )
  )
  expect_snapshot(
    enw_formula_as_data_list(
      enw_formula(
        ~ 1 + disp + (1 + gear | cyl) + (0 + wt | am), mtcars
      ),
      prefix = "comple", drop_intercept = TRUE
    )
  )
})


test_that("enw_formula_as_data_list produces expected default output", {
  expect_equal(
    enw_formula_as_data_list(
      prefix = "c"
    ),
    list(
      c_fdesign = numeric(0), c_fnrow = 0, c_findex = numeric(0), c_fnindex = 0,
      c_fncol = 0, c_rdesign = numeric(0), c_rncol = 0
    )
  )
})

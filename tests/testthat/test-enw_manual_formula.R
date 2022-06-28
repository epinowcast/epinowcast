# test data
test_data <- enw_example("prep")$metareference[[1]]

test_that("enw_manual_formula can return a basic fixed effects formula", {
 expect_snapshot(enw_manual_formula(test_data, fixed = "day_of_week"))
})

test_that("enw_manual_formula can return a basic random effects formula", {
 expect_snapshot(enw_manual_formula(test_data, random = "day_of_week"))
})

test_that("enw_manual_formula can return a basic custom random effects
           formula", {
 expect_snapshot(enw_manual_formula(test_data, custom_random = "day_of"))
})

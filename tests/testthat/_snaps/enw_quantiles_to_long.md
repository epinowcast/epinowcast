# enw_quantiles_to_long can manipulate posterior draws as expected

    Code
      round_numeric(enw_quantiles_to_long(posterior)[, c("rhat", "ess_bulk",
        "ess_tail") := NULL][!is.na(variable)][])
    Output
                       variable mean median sd mad quantile prediction
      1: expr_lelatent_int[1,1]    4      4  0   0        0          4
      2: expr_lelatent_int[1,1]    4      4  0   0        0          4
      3: expr_lelatent_int[1,1]    4      4  0   0        1          4
      4: expr_lelatent_int[1,1]    4      4  0   0        1          4


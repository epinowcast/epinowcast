# enw_quantiles_to_long can manipulate posterior draws as expected

    Code
      enw_quantiles_to_long(posterior)[, c("rhat", "ess_bulk", "ess_tail") := NULL][
        !is.na(variable)][]
    Output
                       variable mean median    sd   mad quantile prediction
      1: expr_lelatent_int[1,1] 4.14   4.14 0.154 0.155     0.05       3.89
      2: expr_lelatent_int[1,1] 4.14   4.14 0.154 0.155     0.20       4.02
      3: expr_lelatent_int[1,1] 4.14   4.14 0.154 0.155     0.80       4.28
      4: expr_lelatent_int[1,1] 4.14   4.14 0.154 0.155     0.95       4.40


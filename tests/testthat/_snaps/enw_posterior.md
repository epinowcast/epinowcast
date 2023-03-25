# enw_posterior can extract posterior draws as expected

    Code
      enw_posterior(fit$fit[[1]], variables = "expr_lelatent_int[1,1]")[1:10][!is.na(
        variable)][, c("rhat", "ess_bulk", "ess_tail") := NULL][]
    Output
                       variable mean median    sd   mad   q5  q20  q80  q95
      1: expr_lelatent_int[1,1] 4.14   4.14 0.154 0.155 3.89 4.02 4.28 4.40


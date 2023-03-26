# enw_posterior can extract posterior draws as expected

    Code
      round_numerics(enw_posterior(fit$fit[[1]], variables = "expr_lelatent_int[1,1]")[
        1:10][!is.na(variable)][, c("rhat", "ess_bulk", "ess_tail") := NULL][])
    Output
                       variable mean median sd mad q5 q20 q80 q95
      1: expr_lelatent_int[1,1]    4      4  0   0  4   4   4   4


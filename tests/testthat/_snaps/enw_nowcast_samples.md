# enw_nowcast_samples can extract nowcast samples as expected

    Code
      round_numeric(enw_nowcast_samples(fit$fit[[1]], fit$latest[[1]])[1:10])
    Output
          reference_date report_date .group max_confirm location age_group confirm
       1:     2021-08-03  2021-08-22      1         149       DE       00+     149
       2:     2021-08-03  2021-08-22      1         149       DE       00+     149
       3:     2021-08-03  2021-08-22      1         149       DE       00+     149
       4:     2021-08-03  2021-08-22      1         149       DE       00+     149
       5:     2021-08-03  2021-08-22      1         149       DE       00+     149
       6:     2021-08-03  2021-08-22      1         149       DE       00+     149
       7:     2021-08-03  2021-08-22      1         149       DE       00+     149
       8:     2021-08-03  2021-08-22      1         149       DE       00+     149
       9:     2021-08-03  2021-08-22      1         149       DE       00+     149
      10:     2021-08-03  2021-08-22      1         149       DE       00+     149
          cum_prop_reported delay prop_reported .chain .iteration .draw sample
       1:                 1    19             0      1          1     1    149
       2:                 1    19             0      1          2     2    149
       3:                 1    19             0      1          3     3    149
       4:                 1    19             0      1          4     4    149
       5:                 1    19             0      1          5     5    149
       6:                 1    19             0      1          6     6    149
       7:                 1    19             0      1          7     7    149
       8:                 1    19             0      1          8     8    149
       9:                 1    19             0      1          9     9    149
      10:                 1    19             0      1         10    10    149


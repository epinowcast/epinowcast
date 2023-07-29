# enw_nowcast_samples can extract nowcast samples as expected

    Code
      round_numerics(enw_nowcast_samples(fit$fit[[1]], fit$latest[[1]], fit$
        metamaxdelay[[1]])[1:10])
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
          cum_prop_reported delay prop_reported sample .chain .iteration .draw
       1:                 1    19             0    149      1          1     1
       2:                 1    19             0    149      1          2     2
       3:                 1    19             0    149      1          3     3
       4:                 1    19             0    149      1          4     4
       5:                 1    19             0    149      1          5     5
       6:                 1    19             0    149      1          6     6
       7:                 1    19             0    149      1          7     7
       8:                 1    19             0    149      1          8     8
       9:                 1    19             0    149      1          9     9
      10:                 1    19             0    149      1         10    10


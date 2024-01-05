# enw_nowcast_samples can extract nowcast samples as expected

    Code
      round_numerics(enw_nowcast_samples(fit$fit[[1]], fit$latest[[1]], max_delay = fit$
        max_delay)[1:10])
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

# enw_nowcast_samples can extract nowcast samples as expected when a delay larger than modelled is specified

    Code
      round_numerics(enw_nowcast_samples(fit$fit[[1]], fit$latest[[1]], max_delay = 22)[
        c(1:10, 1001:1010, 2001:2010)])
    Output
          reference_date report_date .group max_confirm location age_group confirm
       1:     2021-08-01  2021-08-20      1          77       DE       00+      77
       2:     2021-08-01  2021-08-20      1          77       DE       00+      77
       3:     2021-08-01  2021-08-20      1          77       DE       00+      77
       4:     2021-08-01  2021-08-20      1          77       DE       00+      77
       5:     2021-08-01  2021-08-20      1          77       DE       00+      77
       6:     2021-08-01  2021-08-20      1          77       DE       00+      77
       7:     2021-08-01  2021-08-20      1          77       DE       00+      77
       8:     2021-08-01  2021-08-20      1          77       DE       00+      77
       9:     2021-08-01  2021-08-20      1          77       DE       00+      77
      10:     2021-08-01  2021-08-20      1          77       DE       00+      77
      11:     2021-08-02  2021-08-21      1          59       DE       00+      59
      12:     2021-08-02  2021-08-21      1          59       DE       00+      59
      13:     2021-08-02  2021-08-21      1          59       DE       00+      59
      14:     2021-08-02  2021-08-21      1          59       DE       00+      59
      15:     2021-08-02  2021-08-21      1          59       DE       00+      59
      16:     2021-08-02  2021-08-21      1          59       DE       00+      59
      17:     2021-08-02  2021-08-21      1          59       DE       00+      59
      18:     2021-08-02  2021-08-21      1          59       DE       00+      59
      19:     2021-08-02  2021-08-21      1          59       DE       00+      59
      20:     2021-08-02  2021-08-21      1          59       DE       00+      59
      21:     2021-08-03  2021-08-22      1         149       DE       00+     149
      22:     2021-08-03  2021-08-22      1         149       DE       00+     149
      23:     2021-08-03  2021-08-22      1         149       DE       00+     149
      24:     2021-08-03  2021-08-22      1         149       DE       00+     149
      25:     2021-08-03  2021-08-22      1         149       DE       00+     149
      26:     2021-08-03  2021-08-22      1         149       DE       00+     149
      27:     2021-08-03  2021-08-22      1         149       DE       00+     149
      28:     2021-08-03  2021-08-22      1         149       DE       00+     149
      29:     2021-08-03  2021-08-22      1         149       DE       00+     149
      30:     2021-08-03  2021-08-22      1         149       DE       00+     149
          reference_date report_date .group max_confirm location age_group confirm
          cum_prop_reported delay prop_reported .chain .iteration .draw sample
       1:                 1    19             0     NA         NA     1     77
       2:                 1    19             0     NA         NA     2     77
       3:                 1    19             0     NA         NA     3     77
       4:                 1    19             0     NA         NA     4     77
       5:                 1    19             0     NA         NA     5     77
       6:                 1    19             0     NA         NA     6     77
       7:                 1    19             0     NA         NA     7     77
       8:                 1    19             0     NA         NA     8     77
       9:                 1    19             0     NA         NA     9     77
      10:                 1    19             0     NA         NA    10     77
      11:                 1    19             0     NA         NA     1     59
      12:                 1    19             0     NA         NA     2     59
      13:                 1    19             0     NA         NA     3     59
      14:                 1    19             0     NA         NA     4     59
      15:                 1    19             0     NA         NA     5     59
      16:                 1    19             0     NA         NA     6     59
      17:                 1    19             0     NA         NA     7     59
      18:                 1    19             0     NA         NA     8     59
      19:                 1    19             0     NA         NA     9     59
      20:                 1    19             0     NA         NA    10     59
      21:                 1    19             0      1          1     1    149
      22:                 1    19             0      1          2     2    149
      23:                 1    19             0      1          3     3    149
      24:                 1    19             0      1          4     4    149
      25:                 1    19             0      1          5     5    149
      26:                 1    19             0      1          6     6    149
      27:                 1    19             0      1          7     7    149
      28:                 1    19             0      1          8     8    149
      29:                 1    19             0      1          9     9    149
      30:                 1    19             0      1         10    10    149
          cum_prop_reported delay prop_reported .chain .iteration .draw sample


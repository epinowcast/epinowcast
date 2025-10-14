# enw_pp_summary summarises posterior prediction as expected

    Code
      round_numerics(summary[1:10][, c("rhat", "ess_bulk", "ess_tail") := NULL][])
    Output
          reference_date report_date .group max_confirm location age_group confirm
       1:     2021-07-14  2021-07-14      1          72       DE       00+      22
       2:     2021-07-14  2021-07-15      1          72       DE       00+      34
       3:     2021-07-14  2021-07-16      1          72       DE       00+      38
       4:     2021-07-14  2021-07-17      1          72       DE       00+      43
       5:     2021-07-14  2021-07-18      1          72       DE       00+      43
       6:     2021-07-14  2021-07-19      1          72       DE       00+      44
       7:     2021-07-14  2021-07-20      1          72       DE       00+      54
       8:     2021-07-14  2021-07-21      1          72       DE       00+      56
       9:     2021-07-14  2021-07-22      1          72       DE       00+      61
      10:     2021-07-14  2021-07-23      1          72       DE       00+      64
          cum_prop_reported delay new_confirm prop_reported mean median sd mad q50
       1:                 0     0          22             0   22     20 10   9  20
       2:                 0     1          12             0   22     21 10  10  21
       3:                 1     2           4             0    8      8  4   4   8
       4:                 1     3           5             0    4      4  3   3   4
       5:                 1     4           0             0    1      1  1   1   1
       6:                 1     5           1             0    1      1  1   1   1
       7:                 1     6          10             0    3      3  2   1   3
       8:                 1     7           2             0    3      2  2   1   2
       9:                 1     8           5             0    2      2  2   1   2
      10:                 1     9           3             0    2      1  1   1   1


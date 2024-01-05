# enw_pp_summary summarises posterior prediction as expected

    Code
      round_numerics(summary[1:10][, c("rhat", "ess_bulk", "ess_tail") := NULL][])
    Output
          reference_date report_date .group max_confirm location age_group confirm
       1:     2021-07-13  2021-07-13      1          59       DE       00+      21
       2:     2021-07-13  2021-07-14      1          59       DE       00+      33
       3:     2021-07-13  2021-07-15      1          59       DE       00+      36
       4:     2021-07-13  2021-07-16      1          59       DE       00+      40
       5:     2021-07-13  2021-07-17      1          59       DE       00+      43
       6:     2021-07-13  2021-07-18      1          59       DE       00+      43
       7:     2021-07-13  2021-07-19      1          59       DE       00+      44
       8:     2021-07-13  2021-07-20      1          59       DE       00+      46
       9:     2021-07-13  2021-07-21      1          59       DE       00+      50
      10:     2021-07-13  2021-07-22      1          59       DE       00+      53
          cum_prop_reported delay new_confirm prop_reported mean median sd mad q50
       1:                 0     0          21             0   20     19  9   9  19
       2:                 1     1          12             0   21     19  9   9  19
       3:                 1     2           3             0    6      6  3   3   6
       4:                 1     3           4             0    4      4  3   3   4
       5:                 1     4           3             0    2      2  2   1   2
       6:                 1     5           0             0    1      1  1   1   1
       7:                 1     6           1             0    1      0  1   0   0
       8:                 1     7           2             0    2      2  2   1   2
       9:                 1     8           4             0    2      1  1   1   1
      10:                 1     9           3             0    1      1  1   1   1


# build_ord_obs() output matches snapshot with day timesteps

    Code
      result
    Output
         reference_date report_date .group max_confirm location age_group confirm
      1:     2021-08-18  2021-08-22      1         223       DE       00+     223
      2:     2021-08-19  2021-08-22      1         202       DE       00+     202
      3:     2021-08-20  2021-08-22      1         171       DE       00+     171
      4:     2021-08-21  2021-08-22      1         112       DE       00+     112
      5:     2021-08-22  2021-08-22      1          45       DE       00+      45
         cum_prop_reported delay prop_reported
      1:                 1     4    0.01793722
      2:                 1     3    0.01980198
      3:                 1     2    0.07017544
      4:                 1     1    0.38392857
      5:                 1     0    1.00000000

# build_ord_obs() output matches snapshot with week timesteps

    Code
      result
    Output
         reference_date report_date .group max_confirm confirm cum_prop_reported
      1:     2021-08-11  2021-09-08      1        1073    1073                 1
      2:     2021-08-18  2021-09-08      1        1733    1733                 1
      3:     2021-08-25  2021-09-08      1        2268    2268                 1
      4:     2021-09-01  2021-09-08      1        2388    2388                 1
      5:     2021-09-08  2021-09-08      1        1487    1487                 1
         delay
      1:     4
      2:     3
      3:     2
      4:     1
      5:     0

# build_ord_obs() output matches snapshot when sampling from posterior

    Code
      result
    Output
             .draws reference_date report_date .group max_confirm location age_group
          1:      1     2021-08-09  2021-08-22      1          58       DE       00+
          2:      2     2021-08-09  2021-08-22      1          58       DE       00+
          3:      3     2021-08-09  2021-08-22      1          58       DE       00+
          4:      4     2021-08-09  2021-08-22      1          58       DE       00+
          5:      5     2021-08-09  2021-08-22      1          58       DE       00+
         ---                                                                        
      13996:    996     2021-08-22  2021-08-22      1          45       DE       00+
      13997:    997     2021-08-22  2021-08-22      1          45       DE       00+
      13998:    998     2021-08-22  2021-08-22      1          45       DE       00+
      13999:    999     2021-08-22  2021-08-22      1          45       DE       00+
      14000:   1000     2021-08-22  2021-08-22      1          45       DE       00+
             confirm cum_prop_reported delay prop_reported
          1:      58                 1    13             0
          2:      58                 1    13             0
          3:      58                 1    13             0
          4:      58                 1    13             0
          5:      58                 1    13             0
         ---                                              
      13996:      45                 1     0             1
      13997:      45                 1     0             1
      13998:      45                 1     0             1
      13999:      45                 1     0             1
      14000:      45                 1     0             1


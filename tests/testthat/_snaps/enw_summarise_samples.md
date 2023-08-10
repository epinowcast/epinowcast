# enw_summarise_samples summarises samples as expected

    Code
      summary[1:10]
    Output
          reference_date .group report_date max_confirm location age_group confirm
       1:     2021-08-03      1  2021-08-22         149       DE       00+     149
       2:     2021-08-04      1  2021-08-22         166       DE       00+     166
       3:     2021-08-05      1  2021-08-22         133       DE       00+     133
       4:     2021-08-06      1  2021-08-22         137       DE       00+     137
       5:     2021-08-07      1  2021-08-22         139       DE       00+     139
       6:     2021-08-08      1  2021-08-22          97       DE       00+      97
       7:     2021-08-09      1  2021-08-22          58       DE       00+      58
       8:     2021-08-10      1  2021-08-22         175       DE       00+     175
       9:     2021-08-11      1  2021-08-22         233       DE       00+     233
      10:     2021-08-12      1  2021-08-22         237       DE       00+     237
          cum_prop_reported delay prop_reported    mean median       sd    mad     q5
       1:                 1    19   0.000000000 149.000    149 0.000000 0.0000 149.00
       2:                 1    18   0.000000000 167.482    167 1.354811 1.4826 166.00
       3:                 1    17   0.000000000 135.770    135 1.847299 1.4826 133.00
       4:                 1    16   0.000000000 141.177    141 2.404881 2.9652 138.00
       5:                 1    15   0.007194245 145.725    145 2.990705 2.9652 141.00
       6:                 1    14   0.000000000 103.732    103 3.133368 2.9652  99.00
       7:                 1    13   0.000000000  62.737     63 2.405331 2.9652  59.00
       8:                 1    12   0.000000000 185.234    185 3.845261 4.4478 180.00
       9:                 1    11   0.000000000 256.416    256 6.587438 5.9304 246.95
      10:                 1    10   0.004219409 268.018    268 7.549614 7.4130 256.00
          q50    q95
       1: 149 149.00
       2: 167 170.00
       3: 135 139.00
       4: 141 145.05
       5: 145 151.00
       6: 103 109.00
       7:  63  67.00
       8: 185 192.00
       9: 256 268.00
      10: 268 280.00

# enw_summarise_samples adds artificial samples when a delay smaller than specified was modelled

    Code
      summary[1:10]
    Output
          reference_date .group report_date max_confirm location age_group confirm
       1:           <NA>     NA        <NA>          NA     <NA>      <NA>      NA
       2:           <NA>     NA        <NA>          NA     <NA>      <NA>      NA
       3:           <NA>     NA        <NA>          NA     <NA>      <NA>      NA
       4:           <NA>     NA        <NA>          NA     <NA>      <NA>      NA
       5:           <NA>     NA        <NA>          NA     <NA>      <NA>      NA
       6:           <NA>     NA        <NA>          NA     <NA>      <NA>      NA
       7:           <NA>     NA        <NA>          NA     <NA>      <NA>      NA
       8:           <NA>     NA        <NA>          NA     <NA>      <NA>      NA
       9:           <NA>     NA        <NA>          NA     <NA>      <NA>      NA
      10:           <NA>     NA        <NA>          NA     <NA>      <NA>      NA
          cum_prop_reported delay prop_reported mean median sd mad q5 q50 q95
       1:                NA    NA            NA   NA     NA NA  NA NA  NA  NA
       2:                NA    NA            NA   NA     NA NA  NA NA  NA  NA
       3:                NA    NA            NA   NA     NA NA  NA NA  NA  NA
       4:                NA    NA            NA   NA     NA NA  NA NA  NA  NA
       5:                NA    NA            NA   NA     NA NA  NA NA  NA  NA
       6:                NA    NA            NA   NA     NA NA  NA NA  NA  NA
       7:                NA    NA            NA   NA     NA NA  NA NA  NA  NA
       8:                NA    NA            NA   NA     NA NA  NA NA  NA  NA
       9:                NA    NA            NA   NA     NA NA  NA NA  NA  NA
      10:                NA    NA            NA   NA     NA NA  NA NA  NA  NA


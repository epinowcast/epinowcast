``` r
  library(data.table)
  library(epinowcast)

  # Edge case: Daily reference data with weekly report data where
  # the initial reference date is not a single timestep away from the
  # initial report date
  data <- data.table(
    report_date = as.Date(c(
      "2022-10-25", "2022-11-01", "2022-11-01", "2022-11-01", "2022-11-01",
      "2022-11-01", "2022-11-01", "2022-11-01", "2022-11-01", "2022-11-08",
      "2022-11-08", "2022-11-08", "2022-11-08", "2022-11-08", "2022-11-08",
      "2022-11-08", "2022-11-08", "2022-11-08", "2022-11-08", "2022-11-08"
    )),
    reference_date = as.Date(c(
      "2022-10-22", "2022-10-22", "2022-10-23", "2022-10-24", "2022-10-25",
      "2022-10-26", "2022-10-27", "2022-10-28", "2022-10-29", "2022-10-22",
      "2022-10-23", "2022-10-24", "2022-10-25", "2022-10-26", "2022-10-27",
      "2022-10-28", "2022-10-29", "2022-10-30", "2022-10-31", "2022-11-01"
    )),
    confirm = c(
      34, 46, 47, 41, 68, 59, 62, 30, 40,
      48, 53, 46, 75, 67, 84, 47, 67, 69, 81, 88
    )
  )

  # Get a complete daily timeseries as this is the basic format the package is
  # designed for
  daily <- data |>
    enw_complete_dates(timestep = "day", missing_reference = FALSE)

  # Complete the final step and aggregate to weekly timesteps for both reference
  # and report dates
  daily |>
    enw_aggregate_cumulative(timestep = "week")
#>    report_date reference_date confirm
#> 1:  2022-10-29     2022-10-29       0
#> 2:  2022-11-05     2022-10-29     347
#> 3:  2022-11-05     2022-11-05       0

  # Expected output
  ## Option 1: Incomplete weeks are dropped and the already weekly report date
  ## timestep is used
  weekly_data_by_report_date <- data.table(
    report_date = as.Date(
      c(
        "2022-10-25", "2022-11-01", "2022-11-08", "2022-11-01", "2022-11-08",
        "2022-11-08"
      )
    ),
    reference_date = as.Date(
      c(
        "2022-10-25", "2022-10-25", "2022-10-25", "2022-11-01", "2022-11-01",
        "2022-11-08"
      )
    ),
    confirm = c(34, 202, 222, 191, 503, 0)
  )
# Keep the first week of partially reported data
weekly_data_by_report_date[]
#>    report_date reference_date confirm
#> 1:  2022-10-25     2022-10-25      34
#> 2:  2022-11-01     2022-10-25     202
#> 3:  2022-11-08     2022-10-25     222
#> 4:  2022-11-01     2022-11-01     191
#> 5:  2022-11-08     2022-11-01     503
#> 6:  2022-11-08     2022-11-08       0

# Removing the first week of data that is partially reported
weekly_data_by_report_date[
  report_date != as.Date("2022-10-25")][reference_date != as.Date("2022-10-25")
]
#>    report_date reference_date confirm
#> 1:  2022-11-01     2022-11-01     191
#> 2:  2022-11-08     2022-11-01     503
#> 3:  2022-11-08     2022-11-08       0

## Option 2: A timestep based on the reference data is used and so there are no
## incomplete weeks
weekly_data_by_reference_date <- data.table(
  report_date = as.Date(c(
    "2022-10-28", "2022-11-04", "2022-11-04"
  )),
  reference_date = as.Date(c(
    "2022-10-28", "2022-10-28", "2022-11-04"

  )),
  confirm = c(34, 353, 40)
)
# Keep the first week of partially reported data
weekly_data_by_reference_date[]
#>    report_date reference_date confirm
#> 1:  2022-10-28     2022-10-28      34
#> 2:  2022-11-04     2022-10-28     353
#> 3:  2022-11-04     2022-11-04      40

# Don't keep the first week of partially reported data
weekly_data_by_reference_date[report_date != as.Date("2022-10-28")]
#>    report_date reference_date confirm
#> 1:  2022-11-04     2022-10-28     353
#> 2:  2022-11-04     2022-11-04      40
```

<sup>Created on 2023-10-18 with [reprex v2.0.2](https://reprex.tidyverse.org)</sup>

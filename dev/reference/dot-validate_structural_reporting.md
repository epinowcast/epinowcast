# Validate structural reporting data.table

Checks that a structural reporting data.table has the required columns
and correct structure for conversion to matrices.

## Usage

``` r
.validate_structural_reporting(structural)
```

## Arguments

- structural:

  A `data.table` or `data.frame` with columns `.group`, `date`,
  `report_date`, and `report`.

## Value

The validated and coerced `data.table` (invisible). Aborts with error if
validation fails.

## Details

The structural reporting matrix ensures reports can only aggregate from
the current or earlier delays. For example, a report on delay 5 can
aggregate delays 1 through 5, but not delay 6 or later. This function
validates that `report_date >= date` to ensure valid delays.

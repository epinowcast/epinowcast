# Format delay with appropriate units

Internal helper to format delays with units based on timestep. For
weekly/custom timesteps, shows both timestep units and days.

## Usage

``` r
.format_delay_with_units(max_delay, timestep, daily_max_delay = NULL)
```

## Arguments

- max_delay:

  Integer delay value in timestep units

- timestep:

  Timestep specification (character or numeric)

- daily_max_delay:

  Pre-computed delay in days (optional)

## Value

Character string with formatted delay

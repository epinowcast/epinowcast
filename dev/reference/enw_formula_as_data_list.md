# Format formula data for use with stan

Format formula data for use with stan

## Usage

``` r
enw_formula_as_data_list(formula, prefix, drop_intercept = FALSE)
```

## Arguments

- formula:

  The output of
  [`enw_formula()`](https://package.epinowcast.org/dev/reference/enw_formula.md).

- prefix:

  A character string indicating variable label to use as a prefix.

- drop_intercept:

  Logical, defaults to `FALSE`. Should the intercept be included as a
  fixed effect or excluded. This is used internally in model modules
  where an intercept must be present/absent.

## Value

A list defining the model formula. This includes:

- `prefix_fintercept:` Is an intercept present for the fixed effects
  design matrix.

- `prefix_fdesign`: The fixed effects design matrix

- `prefix_fnrow`: The number of rows of the fixed design matrix

- `prefix_findex`: The index linking design matrix rows to observations

- `prefix_fnindex`: The length of the index

- `prefix_fncol`: The number of columns (i.e effects) in the fixed
  effect design matrix (minus 1 if an intercept is present).

- `prefix_rdesign`: The random effects design matrix

- `prefix_rncol`: The number of columns (i.e random effects) in the
  random effect design matrix (minus 1 as the intercept is dropped).

## See also

Functions used to help convert models into the format required for stan
[`enw_get_cache()`](https://package.epinowcast.org/dev/reference/enw_get_cache.md),
[`enw_model()`](https://package.epinowcast.org/dev/reference/enw_model.md),
[`enw_pathfinder()`](https://package.epinowcast.org/dev/reference/enw_pathfinder.md),
[`enw_priors_as_data_list()`](https://package.epinowcast.org/dev/reference/enw_priors_as_data_list.md),
[`enw_replace_priors()`](https://package.epinowcast.org/dev/reference/enw_replace_priors.md),
[`enw_sample()`](https://package.epinowcast.org/dev/reference/enw_sample.md),
[`enw_set_cache()`](https://package.epinowcast.org/dev/reference/enw_set_cache.md),
[`enw_stan_to_r()`](https://package.epinowcast.org/dev/reference/enw_stan_to_r.md),
[`enw_unset_cache()`](https://package.epinowcast.org/dev/reference/enw_unset_cache.md),
[`remove_profiling()`](https://package.epinowcast.org/dev/reference/remove_profiling.md),
[`write_stan_files_no_profile()`](https://package.epinowcast.org/dev/reference/write_stan_files_no_profile.md)

## Examples

``` r
f <- enw_formula(~ 1 + (1 | cyl), mtcars)
enw_formula_as_data_list(f, "mtcars")
#> $mtcars_fintercept
#> [1] 1
#> 
#> $mtcars_fnrow
#> [1] 3
#> 
#> $mtcars_findex
#>  [1] 1 1 2 1 3 1 3 2 2 1 1 3 3 3 3 3 3 2 2 2 2 3 3 3 3 2 2 2 3 1 3 2
#> 
#> $mtcars_fnindex
#> [1] 32
#> 
#> $mtcars_fncol
#> [1] 3
#> 
#> $mtcars_rncol
#> [1] 1
#> 
#> $mtcars_fdesign
#>   cyl4 cyl6 cyl8
#> 1    0    1    0
#> 3    1    0    0
#> 5    0    0    1
#> 
#> $mtcars_rdesign
#>   fixed cyl
#> 1     0   1
#> 2     0   1
#> 3     0   1
#> attr(,"assign")
#> [1] 1 2
#> 

# A missing formula produces the default list
enw_formula_as_data_list(prefix = "missing")
#> $missing_fintercept
#> [1] 0
#> 
#> $missing_fnrow
#> [1] 0
#> 
#> $missing_findex
#> numeric(0)
#> 
#> $missing_fnindex
#> [1] 0
#> 
#> $missing_fncol
#> [1] 0
#> 
#> $missing_rncol
#> [1] 0
#> 
#> $missing_fdesign
#> numeric(0)
#> 
#> $missing_rdesign
#> numeric(0)
#> 
```

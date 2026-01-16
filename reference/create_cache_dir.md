# Create Stan cache directory

This function creates a cache directory for Stan models if it does not
already exist. This is useful for users who want to set a persistent
cache location but do not want to create the directory manually.

## Usage

``` r
create_cache_dir(path)
```

## Arguments

- path:

  A valid filepath representing the desired cache location. If the
  directory does not exist it will be created.

## Value

`NULL`

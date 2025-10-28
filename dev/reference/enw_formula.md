# Define a model using a formula interface

This function allows models to be defined using a flexible formula
interface that supports fixed effects, random effects (using
[lme4](https://rdrr.io/pkg/lme4/man/lme4-package.html) syntax), and
random walks. The formula syntax builds on standard R formula notation
and extends it with
[lme4](https://rdrr.io/pkg/lme4/man/lme4-package.html) style random
effects and custom random walk terms. Users familiar with mixed models
in lme4 or brms will recognise the syntax. Note that the returned fixed
effects design matrix is sparse and so the index supplied is required to
link observations to the appropriate design matrix row.

## Usage

``` r
enw_formula(formula, data, sparse = TRUE)
```

## Arguments

- formula:

  A model formula that may use standard fixed effects, random effects
  using [lme4](https://rdrr.io/pkg/lme4/man/lme4-package.html) syntax
  (see [`re()`](https://package.epinowcast.org/dev/reference/re.md)),
  and random walks defined using the
  [`rw()`](https://package.epinowcast.org/dev/reference/rw.md) helper
  function. See the Details section below for a comprehensive
  explanation of the supported syntax.

- data:

  A `data.frame` of observations. It must include all variables used in
  the supplied formula.

- sparse:

  Logical, defaults to `TRUE`. Should the fixed effects design matrix be
  sparely defined.

## Value

A list containing the following:

- `formula`: The user supplied formula

- `parsed_formula`: The formula as parsed by
  [`parse_formula()`](https://package.epinowcast.org/dev/reference/parse_formula.md)

- `expanded_formula`: The flattened version of the formula with both
  user supplied terms and terms added for the user supplied complex
  model components.

- `fixed`: A list containing the fixed effect formula, sparse design
  matrix, and the index linking the design matrix with observations.

- `random`: A list containing the random effect formula, sparse design
  matrix, and the index linking the design matrix with random effects.

## Details

### Formula syntax overview

The formula interface supports three types of model components:

**Fixed effects**: Standard R formula syntax as used in
[`stats::lm()`](https://rdrr.io/r/stats/lm.html) and similar functions.
For example:

- `~ 1`: intercept only

- `~ age_group`: intercept plus categorical predictor

- `~ age_group + location`: multiple predictors

- `~ 0 + age_group`: no intercept (contrasts)

**Random effects**: Uses
[lme4](https://rdrr.io/pkg/lme4/man/lme4-package.html) syntax with
vertical bar notation. Random effects allow parameters to vary by group
whilst sharing information across groups through partial pooling. Note
that `epinowcast` assumes independent standard deviations for random
effects rather than correlated random effects as supported by
[lme4](https://rdrr.io/pkg/lme4/man/lme4-package.html). For example:

- `~ 1 + (1 | location)`: random intercepts by location

- `~ 1 + age_group + (1 | location)`: fixed age effect with random
  location intercepts

- `~ (age_group | location)`: random slopes for age within each location

- `~ (1 + week | location:month)`: random intercepts and week effects
  for each location-month combination (using interaction to create
  independent random effects per strata)

Interactions (e.g., `location:month`) can be used on the right-hand side
of the vertical bar to specify independent random effects for each
combination of the interacting variables.

See the [lme4](https://rdrr.io/pkg/lme4/man/lme4-package.html) package
documentation for more details on random effects syntax.

**Random walks**: Uses the
[`rw()`](https://package.epinowcast.org/dev/reference/rw.md) helper
function to specify time-varying effects that evolve smoothly over time.
For example:

- `~ rw(week)`: a random walk over weeks

- `~ rw(week, location)`: independent random walks for each location

- `~ rw(week, location, type = "dependent")`: random walks with shared
  variance across locations

These three types of effects can be combined in a single formula, for
example: `~ 1 + age_group + (1 | location) + rw(week, location)`
specifies fixed age effects, random location intercepts, and
location-specific random walks over time.

### Turning off model components

In `epinowcast` model specification functions (such as
[`enw_reference()`](https://package.epinowcast.org/dev/reference/enw_reference.md),
[`enw_report()`](https://package.epinowcast.org/dev/reference/enw_report.md),
[`enw_expectation()`](https://package.epinowcast.org/dev/reference/enw_expectation.md)),
formula arguments can be set to `~0` to disable that model component
entirely. This is a package-specific convention. Note that when a
formula is specified as `~0`, it is typically converted internally to
`~1` (intercept only) to ensure valid model structure, but the component
is flagged as inactive.

### How formulas map to the model

The formula you specify controls which covariates and effects enter the
linear predictor of the model. For instance, in the reference date model
([`enw_reference()`](https://package.epinowcast.org/dev/reference/enw_reference.md)),
the formula determines how reporting delay parameters vary by covariates
and groups. The formula is converted to design matrices: a fixed effects
matrix (which may be sparse for computational efficiency) and a random
effects matrix that defines the hierarchical structure.

## References

For users new to formula syntax in R:

- **Fixed effects**: See
  [`?formula`](https://rdrr.io/r/stats/formula.html) and the
  "Statistical Models in R" chapter of "An Introduction to R":
  <https://cran.r-project.org/doc/manuals/r-release/R-intro.html#Statistical-models-in-R>

- **Random effects**: See the
  [lme4](https://rdrr.io/pkg/lme4/man/lme4-package.html) package
  documentation and vignettes.

- **Mixed models**: Bates et al. (2015) "Fitting Linear Mixed-Effects
  Models Using lme4". Journal of Statistical Software, 67(1), 1-48.
  doi:10.18637/jss.v067.i01

## See also

Functions used to help convert formulas into model designs
[`as_string_formula()`](https://package.epinowcast.org/dev/reference/as_string_formula.md),
[`construct_re()`](https://package.epinowcast.org/dev/reference/construct_re.md),
[`construct_rw()`](https://package.epinowcast.org/dev/reference/construct_rw.md),
[`enw_manual_formula()`](https://package.epinowcast.org/dev/reference/enw_manual_formula.md),
[`parse_formula()`](https://package.epinowcast.org/dev/reference/parse_formula.md),
[`re()`](https://package.epinowcast.org/dev/reference/re.md),
[`remove_rw_terms()`](https://package.epinowcast.org/dev/reference/remove_rw_terms.md),
[`rw()`](https://package.epinowcast.org/dev/reference/rw.md),
[`rw_terms()`](https://package.epinowcast.org/dev/reference/rw_terms.md),
[`split_formula_to_terms()`](https://package.epinowcast.org/dev/reference/split_formula_to_terms.md)

## Examples

``` r
# Use meta data for references dates from the Germany COVID-19
# hospitalisation data.
obs <- enw_filter_report_dates(
  germany_covid19_hosp[location == "DE"],
  remove_days = 40
)
obs <- enw_filter_reference_dates(obs, include_days = 40)
pobs <- enw_preprocess_data(
  obs, by = c("age_group", "location"), max_delay = 20
  )
data <- pobs$metareference[[1]]

# Intercept only
enw_formula(~ 1, data)
#> $formula
#> [1] "~1"
#> 
#> $parsed_formula
#> $parsed_formula$fixed
#> [1] "1"
#> 
#> $parsed_formula$random
#> NULL
#> 
#> $parsed_formula$rw
#> character(0)
#> 
#> 
#> $expanded_formula
#> [1] "~1"
#> 
#> $fixed
#> $fixed$formula
#> [1] "~1"
#> 
#> $fixed$design
#>   (Intercept)
#> 1           1
#> 
#> $fixed$index
#>   [1] 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
#>  [38] 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
#>  [75] 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
#> [112] 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
#> [149] 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
#> [186] 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
#> [223] 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
#> [260] 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
#> 
#> 
#> $random
#> $random$formula
#> [1] "~1"
#> 
#> $random$design
#>      (Intercept)
#> attr(,"assign")
#> [1] 0
#> 
#> $random$index
#> integer(0)
#> 
#> 
#> attr(,"class")
#> [1] "enw_formula" "list"       

# Fixed effect
enw_formula(~ 1 + age_group, data)
#> $formula
#> [1] "~1 + age_group"
#> 
#> $parsed_formula
#> $parsed_formula$fixed
#> [1] "1"         "age_group"
#> 
#> $parsed_formula$random
#> NULL
#> 
#> $parsed_formula$rw
#> character(0)
#> 
#> 
#> $expanded_formula
#> [1] "~1 + age_group"
#> 
#> $fixed
#> $fixed$formula
#> [1] "~1 + age_group"
#> 
#> $fixed$design
#>     (Intercept) age_group00+ age_group05-14 age_group15-34 age_group35-59
#> 1             1            1              0              0              0
#> 41            1            0              0              0              0
#> 81            1            0              1              0              0
#> 121           1            0              0              1              0
#> 161           1            0              0              0              1
#> 201           1            0              0              0              0
#> 241           1            0              0              0              0
#>     age_group60-79 age_group80+
#> 1                0            0
#> 41               0            0
#> 81               0            0
#> 121              0            0
#> 161              0            0
#> 201              1            0
#> 241              0            1
#> 
#> $fixed$index
#>   [1] 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
#>  [38] 1 1 1 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2
#>  [75] 2 2 2 2 2 2 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3
#> [112] 3 3 3 3 3 3 3 3 3 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4
#> [149] 4 4 4 4 4 4 4 4 4 4 4 4 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5
#> [186] 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6
#> [223] 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7
#> [260] 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7
#> 
#> 
#> $random
#> $random$formula
#> [1] "~1"
#> 
#> $random$design
#>   (Intercept)
#> 1           1
#> 2           1
#> 3           1
#> 4           1
#> 5           1
#> 6           1
#> attr(,"assign")
#> [1] 0
#> 
#> $random$index
#> [1] 1 2 3 4 5 6
#> 
#> 
#> attr(,"class")
#> [1] "enw_formula" "list"       

# Random intercepts
enw_formula(~ 1 + (1 | age_group), data)
#> $formula
#> [1] "~1 + (1 | age_group)"
#> 
#> $parsed_formula
#> $parsed_formula$fixed
#> [1] "1"
#> 
#> $parsed_formula$random
#> $parsed_formula$random[[1]]
#> 1 | age_group
#> 
#> 
#> $parsed_formula$rw
#> character(0)
#> 
#> 
#> $expanded_formula
#> [1] "~1 + age_group"
#> 
#> $fixed
#> $fixed$formula
#> [1] "~1 + age_group"
#> 
#> $fixed$design
#>     (Intercept) age_group00-04 age_group00+ age_group05-14 age_group15-34
#> 1             1              0            1              0              0
#> 41            1              1            0              0              0
#> 81            1              0            0              1              0
#> 121           1              0            0              0              1
#> 161           1              0            0              0              0
#> 201           1              0            0              0              0
#> 241           1              0            0              0              0
#>     age_group35-59 age_group60-79 age_group80+
#> 1                0              0            0
#> 41               0              0            0
#> 81               0              0            0
#> 121              0              0            0
#> 161              1              0            0
#> 201              0              1            0
#> 241              0              0            1
#> 
#> $fixed$index
#>   [1] 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
#>  [38] 1 1 1 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2
#>  [75] 2 2 2 2 2 2 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3
#> [112] 3 3 3 3 3 3 3 3 3 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4
#> [149] 4 4 4 4 4 4 4 4 4 4 4 4 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5
#> [186] 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6
#> [223] 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7
#> [260] 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7
#> 
#> 
#> $random
#> $random$formula
#> [1] "~0 + fixed + age_group"
#> 
#> $random$design
#>   fixed age_group
#> 1     0         1
#> 2     0         1
#> 3     0         1
#> 4     0         1
#> 5     0         1
#> 6     0         1
#> 7     0         1
#> attr(,"assign")
#> [1] 1 2
#> 
#> $random$index
#> [1] 1 2 3 4 5 6 7
#> 
#> 
#> attr(,"class")
#> [1] "enw_formula" "list"       

# Random walk
enw_formula(~ 1 + rw(week), data)
#> $formula
#> [1] "~1 + rw(week)"
#> 
#> $parsed_formula
#> $parsed_formula$fixed
#> [1] "1"
#> 
#> $parsed_formula$random
#> NULL
#> 
#> $parsed_formula$rw
#> [1] "rw(week)"
#> 
#> 
#> $expanded_formula
#> [1] "~1 + cweek1 + cweek2 + cweek3 + cweek4 + cweek5"
#> 
#> $fixed
#> $fixed$formula
#> [1] "~1 + cweek1 + cweek2 + cweek3 + cweek4 + cweek5"
#> 
#> $fixed$design
#>    (Intercept) cweek1 cweek2 cweek3 cweek4 cweek5
#> 1            1      0      0      0      0      0
#> 8            1      1      0      0      0      0
#> 15           1      1      1      0      0      0
#> 22           1      1      1      1      0      0
#> 29           1      1      1      1      1      0
#> 36           1      1      1      1      1      1
#> 
#> $fixed$index
#>   [1] 1 1 1 1 1 1 1 2 2 2 2 2 2 2 3 3 3 3 3 3 3 4 4 4 4 4 4 4 5 5 5 5 5 5 5 6 6
#>  [38] 6 6 6 1 1 1 1 1 1 1 2 2 2 2 2 2 2 3 3 3 3 3 3 3 4 4 4 4 4 4 4 5 5 5 5 5 5
#>  [75] 5 6 6 6 6 6 1 1 1 1 1 1 1 2 2 2 2 2 2 2 3 3 3 3 3 3 3 4 4 4 4 4 4 4 5 5 5
#> [112] 5 5 5 5 6 6 6 6 6 1 1 1 1 1 1 1 2 2 2 2 2 2 2 3 3 3 3 3 3 3 4 4 4 4 4 4 4
#> [149] 5 5 5 5 5 5 5 6 6 6 6 6 1 1 1 1 1 1 1 2 2 2 2 2 2 2 3 3 3 3 3 3 3 4 4 4 4
#> [186] 4 4 4 5 5 5 5 5 5 5 6 6 6 6 6 1 1 1 1 1 1 1 2 2 2 2 2 2 2 3 3 3 3 3 3 3 4
#> [223] 4 4 4 4 4 4 5 5 5 5 5 5 5 6 6 6 6 6 1 1 1 1 1 1 1 2 2 2 2 2 2 2 3 3 3 3 3
#> [260] 3 3 4 4 4 4 4 4 4 5 5 5 5 5 5 5 6 6 6 6 6
#> 
#> 
#> $random
#> $random$formula
#> [1] "~0 + fixed + rw__week"
#> 
#> $random$design
#>   fixed rw__week
#> 1     0        1
#> 2     0        1
#> 3     0        1
#> 4     0        1
#> 5     0        1
#> attr(,"assign")
#> [1] 1 2
#> 
#> $random$index
#> [1] 1 2 3 4 5
#> 
#> 
#> attr(,"class")
#> [1] "enw_formula" "list"       

# Model with a random effect for age group and a random walk
enw_formula(~ 1 + (1 | age_group) + rw(week), data)
#> $formula
#> [1] "~1 + (1 | age_group) + rw(week)"
#> 
#> $parsed_formula
#> $parsed_formula$fixed
#> [1] "1"
#> 
#> $parsed_formula$random
#> $parsed_formula$random[[1]]
#> 1 | age_group
#> 
#> 
#> $parsed_formula$rw
#> [1] "rw(week)"
#> 
#> 
#> $expanded_formula
#> [1] "~1 + age_group + cweek1 + cweek2 + cweek3 + cweek4 + cweek5"
#> 
#> $fixed
#> $fixed$formula
#> [1] "~1 + age_group + cweek1 + cweek2 + cweek3 + cweek4 + cweek5"
#> 
#> $fixed$design
#>     (Intercept) age_group00-04 age_group00+ age_group05-14 age_group15-34
#> 1             1              0            1              0              0
#> 8             1              0            1              0              0
#> 15            1              0            1              0              0
#> 22            1              0            1              0              0
#> 29            1              0            1              0              0
#> 36            1              0            1              0              0
#> 41            1              1            0              0              0
#> 48            1              1            0              0              0
#> 55            1              1            0              0              0
#> 62            1              1            0              0              0
#> 69            1              1            0              0              0
#> 76            1              1            0              0              0
#> 81            1              0            0              1              0
#> 88            1              0            0              1              0
#> 95            1              0            0              1              0
#> 102           1              0            0              1              0
#> 109           1              0            0              1              0
#> 116           1              0            0              1              0
#> 121           1              0            0              0              1
#> 128           1              0            0              0              1
#> 135           1              0            0              0              1
#> 142           1              0            0              0              1
#> 149           1              0            0              0              1
#> 156           1              0            0              0              1
#> 161           1              0            0              0              0
#> 168           1              0            0              0              0
#> 175           1              0            0              0              0
#> 182           1              0            0              0              0
#> 189           1              0            0              0              0
#> 196           1              0            0              0              0
#> 201           1              0            0              0              0
#> 208           1              0            0              0              0
#> 215           1              0            0              0              0
#> 222           1              0            0              0              0
#> 229           1              0            0              0              0
#> 236           1              0            0              0              0
#> 241           1              0            0              0              0
#> 248           1              0            0              0              0
#> 255           1              0            0              0              0
#> 262           1              0            0              0              0
#> 269           1              0            0              0              0
#> 276           1              0            0              0              0
#>     age_group35-59 age_group60-79 age_group80+ cweek1 cweek2 cweek3 cweek4
#> 1                0              0            0      0      0      0      0
#> 8                0              0            0      1      0      0      0
#> 15               0              0            0      1      1      0      0
#> 22               0              0            0      1      1      1      0
#> 29               0              0            0      1      1      1      1
#> 36               0              0            0      1      1      1      1
#> 41               0              0            0      0      0      0      0
#> 48               0              0            0      1      0      0      0
#> 55               0              0            0      1      1      0      0
#> 62               0              0            0      1      1      1      0
#> 69               0              0            0      1      1      1      1
#> 76               0              0            0      1      1      1      1
#> 81               0              0            0      0      0      0      0
#> 88               0              0            0      1      0      0      0
#> 95               0              0            0      1      1      0      0
#> 102              0              0            0      1      1      1      0
#> 109              0              0            0      1      1      1      1
#> 116              0              0            0      1      1      1      1
#> 121              0              0            0      0      0      0      0
#> 128              0              0            0      1      0      0      0
#> 135              0              0            0      1      1      0      0
#> 142              0              0            0      1      1      1      0
#> 149              0              0            0      1      1      1      1
#> 156              0              0            0      1      1      1      1
#> 161              1              0            0      0      0      0      0
#> 168              1              0            0      1      0      0      0
#> 175              1              0            0      1      1      0      0
#> 182              1              0            0      1      1      1      0
#> 189              1              0            0      1      1      1      1
#> 196              1              0            0      1      1      1      1
#> 201              0              1            0      0      0      0      0
#> 208              0              1            0      1      0      0      0
#> 215              0              1            0      1      1      0      0
#> 222              0              1            0      1      1      1      0
#> 229              0              1            0      1      1      1      1
#> 236              0              1            0      1      1      1      1
#> 241              0              0            1      0      0      0      0
#> 248              0              0            1      1      0      0      0
#> 255              0              0            1      1      1      0      0
#> 262              0              0            1      1      1      1      0
#> 269              0              0            1      1      1      1      1
#> 276              0              0            1      1      1      1      1
#>     cweek5
#> 1        0
#> 8        0
#> 15       0
#> 22       0
#> 29       0
#> 36       1
#> 41       0
#> 48       0
#> 55       0
#> 62       0
#> 69       0
#> 76       1
#> 81       0
#> 88       0
#> 95       0
#> 102      0
#> 109      0
#> 116      1
#> 121      0
#> 128      0
#> 135      0
#> 142      0
#> 149      0
#> 156      1
#> 161      0
#> 168      0
#> 175      0
#> 182      0
#> 189      0
#> 196      1
#> 201      0
#> 208      0
#> 215      0
#> 222      0
#> 229      0
#> 236      1
#> 241      0
#> 248      0
#> 255      0
#> 262      0
#> 269      0
#> 276      1
#> 
#> $fixed$index
#>   [1]  1  1  1  1  1  1  1  2  2  2  2  2  2  2  3  3  3  3  3  3  3  4  4  4  4
#>  [26]  4  4  4  5  5  5  5  5  5  5  6  6  6  6  6  7  7  7  7  7  7  7  8  8  8
#>  [51]  8  8  8  8  9  9  9  9  9  9  9 10 10 10 10 10 10 10 11 11 11 11 11 11 11
#>  [76] 12 12 12 12 12 13 13 13 13 13 13 13 14 14 14 14 14 14 14 15 15 15 15 15 15
#> [101] 15 16 16 16 16 16 16 16 17 17 17 17 17 17 17 18 18 18 18 18 19 19 19 19 19
#> [126] 19 19 20 20 20 20 20 20 20 21 21 21 21 21 21 21 22 22 22 22 22 22 22 23 23
#> [151] 23 23 23 23 23 24 24 24 24 24 25 25 25 25 25 25 25 26 26 26 26 26 26 26 27
#> [176] 27 27 27 27 27 27 28 28 28 28 28 28 28 29 29 29 29 29 29 29 30 30 30 30 30
#> [201] 31 31 31 31 31 31 31 32 32 32 32 32 32 32 33 33 33 33 33 33 33 34 34 34 34
#> [226] 34 34 34 35 35 35 35 35 35 35 36 36 36 36 36 37 37 37 37 37 37 37 38 38 38
#> [251] 38 38 38 38 39 39 39 39 39 39 39 40 40 40 40 40 40 40 41 41 41 41 41 41 41
#> [276] 42 42 42 42 42
#> 
#> 
#> $random
#> $random$formula
#> [1] "~0 + fixed + age_group + rw__week"
#> 
#> $random$design
#>    fixed age_group rw__week
#> 1      0         1        0
#> 2      0         1        0
#> 3      0         1        0
#> 4      0         1        0
#> 5      0         1        0
#> 6      0         1        0
#> 7      0         1        0
#> 8      0         0        1
#> 9      0         0        1
#> 10     0         0        1
#> 11     0         0        1
#> 12     0         0        1
#> attr(,"assign")
#> [1] 1 2 3
#> 
#> $random$index
#>  [1]  1  2  3  4  5  6  7  8  9 10 11 12
#> 
#> 
#> attr(,"class")
#> [1] "enw_formula" "list"       

# Model defined without a sparse fixed effects design matrix
enw_formula(~1, data[1:20, ], sparse = FALSE)
#> $formula
#> [1] "~1"
#> 
#> $parsed_formula
#> $parsed_formula$fixed
#> [1] "1"
#> 
#> $parsed_formula$random
#> NULL
#> 
#> $parsed_formula$rw
#> character(0)
#> 
#> 
#> $expanded_formula
#> [1] "~1"
#> 
#> $fixed
#> $fixed$formula
#> [1] "~1"
#> 
#> $fixed$design
#>    (Intercept)
#> 1            1
#> 2            1
#> 3            1
#> 4            1
#> 5            1
#> 6            1
#> 7            1
#> 8            1
#> 9            1
#> 10           1
#> 11           1
#> 12           1
#> 13           1
#> 14           1
#> 15           1
#> 16           1
#> 17           1
#> 18           1
#> 19           1
#> 20           1
#> attr(,"assign")
#> [1] 0
#> 
#> $fixed$index
#>  [1]  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20
#> 
#> 
#> $random
#> $random$formula
#> [1] "~1"
#> 
#> $random$design
#>      (Intercept)
#> attr(,"assign")
#> [1] 0
#> 
#> $random$index
#> integer(0)
#> 
#> 
#> attr(,"class")
#> [1] "enw_formula" "list"       

# Model using an interaction in the right hand side of a random effect
# to specify an independent random effect per strata.
enw_formula(~ (1 + day | week:month), data = data)
#> $formula
#> [1] "~(1 + day | week:month)"
#> 
#> $parsed_formula
#> $parsed_formula$fixed
#> [1] "1"
#> 
#> $parsed_formula$random
#> $parsed_formula$random[[1]]
#> 1 + day | week:month
#> 
#> 
#> $parsed_formula$rw
#> character(0)
#> 
#> 
#> $expanded_formula
#> [1] "~1 + week:month + day:week:month"
#> 
#> $fixed
#> $fixed$formula
#> [1] "~1 + week:month + day:week:month"
#> 
#> $fixed$design
#>    (Intercept) week0:month0 week1:month0 week2:month0 week3:month0 week4:month0
#> 1            1            1            0            0            0            0
#> 2            1            1            0            0            0            0
#> 3            1            1            0            0            0            0
#> 4            1            1            0            0            0            0
#> 5            1            1            0            0            0            0
#> 6            1            1            0            0            0            0
#> 7            1            1            0            0            0            0
#> 8            1            0            1            0            0            0
#> 9            1            0            1            0            0            0
#> 10           1            0            1            0            0            0
#> 11           1            0            1            0            0            0
#> 12           1            0            1            0            0            0
#> 13           1            0            1            0            0            0
#> 14           1            0            1            0            0            0
#> 15           1            0            0            1            0            0
#> 16           1            0            0            1            0            0
#> 17           1            0            0            1            0            0
#> 18           1            0            0            1            0            0
#> 19           1            0            0            1            0            0
#> 20           1            0            0            1            0            0
#> 21           1            0            0            1            0            0
#> 22           1            0            0            0            1            0
#> 23           1            0            0            0            1            0
#> 24           1            0            0            0            1            0
#> 25           1            0            0            0            1            0
#> 26           1            0            0            0            1            0
#> 27           1            0            0            0            1            0
#> 28           1            0            0            0            1            0
#> 29           1            0            0            0            0            1
#> 30           1            0            0            0            0            1
#> 31           1            0            0            0            0            0
#> 32           1            0            0            0            0            0
#> 33           1            0            0            0            0            0
#> 34           1            0            0            0            0            0
#> 35           1            0            0            0            0            0
#> 36           1            0            0            0            0            0
#> 37           1            0            0            0            0            0
#> 38           1            0            0            0            0            0
#> 39           1            0            0            0            0            0
#> 40           1            0            0            0            0            0
#>    week5:month0 week0:month1 week1:month1 week2:month1 week3:month1
#> 1             0            0            0            0            0
#> 2             0            0            0            0            0
#> 3             0            0            0            0            0
#> 4             0            0            0            0            0
#> 5             0            0            0            0            0
#> 6             0            0            0            0            0
#> 7             0            0            0            0            0
#> 8             0            0            0            0            0
#> 9             0            0            0            0            0
#> 10            0            0            0            0            0
#> 11            0            0            0            0            0
#> 12            0            0            0            0            0
#> 13            0            0            0            0            0
#> 14            0            0            0            0            0
#> 15            0            0            0            0            0
#> 16            0            0            0            0            0
#> 17            0            0            0            0            0
#> 18            0            0            0            0            0
#> 19            0            0            0            0            0
#> 20            0            0            0            0            0
#> 21            0            0            0            0            0
#> 22            0            0            0            0            0
#> 23            0            0            0            0            0
#> 24            0            0            0            0            0
#> 25            0            0            0            0            0
#> 26            0            0            0            0            0
#> 27            0            0            0            0            0
#> 28            0            0            0            0            0
#> 29            0            0            0            0            0
#> 30            0            0            0            0            0
#> 31            0            0            0            0            0
#> 32            0            0            0            0            0
#> 33            0            0            0            0            0
#> 34            0            0            0            0            0
#> 35            0            0            0            0            0
#> 36            0            0            0            0            0
#> 37            0            0            0            0            0
#> 38            0            0            0            0            0
#> 39            0            0            0            0            0
#> 40            0            0            0            0            0
#>    week4:month1 week5:month1 week0:month0:day week1:month0:day week2:month0:day
#> 1             0            0                0                0                0
#> 2             0            0                1                0                0
#> 3             0            0                2                0                0
#> 4             0            0                3                0                0
#> 5             0            0                4                0                0
#> 6             0            0                5                0                0
#> 7             0            0                6                0                0
#> 8             0            0                0                7                0
#> 9             0            0                0                8                0
#> 10            0            0                0                9                0
#> 11            0            0                0               10                0
#> 12            0            0                0               11                0
#> 13            0            0                0               12                0
#> 14            0            0                0               13                0
#> 15            0            0                0                0               14
#> 16            0            0                0                0               15
#> 17            0            0                0                0               16
#> 18            0            0                0                0               17
#> 19            0            0                0                0               18
#> 20            0            0                0                0               19
#> 21            0            0                0                0               20
#> 22            0            0                0                0                0
#> 23            0            0                0                0                0
#> 24            0            0                0                0                0
#> 25            0            0                0                0                0
#> 26            0            0                0                0                0
#> 27            0            0                0                0                0
#> 28            0            0                0                0                0
#> 29            0            0                0                0                0
#> 30            0            0                0                0                0
#> 31            1            0                0                0                0
#> 32            1            0                0                0                0
#> 33            1            0                0                0                0
#> 34            1            0                0                0                0
#> 35            1            0                0                0                0
#> 36            0            1                0                0                0
#> 37            0            1                0                0                0
#> 38            0            1                0                0                0
#> 39            0            1                0                0                0
#> 40            0            1                0                0                0
#>    week3:month0:day week4:month0:day week5:month0:day week0:month1:day
#> 1                 0                0                0                0
#> 2                 0                0                0                0
#> 3                 0                0                0                0
#> 4                 0                0                0                0
#> 5                 0                0                0                0
#> 6                 0                0                0                0
#> 7                 0                0                0                0
#> 8                 0                0                0                0
#> 9                 0                0                0                0
#> 10                0                0                0                0
#> 11                0                0                0                0
#> 12                0                0                0                0
#> 13                0                0                0                0
#> 14                0                0                0                0
#> 15                0                0                0                0
#> 16                0                0                0                0
#> 17                0                0                0                0
#> 18                0                0                0                0
#> 19                0                0                0                0
#> 20                0                0                0                0
#> 21                0                0                0                0
#> 22               21                0                0                0
#> 23               22                0                0                0
#> 24               23                0                0                0
#> 25               24                0                0                0
#> 26               25                0                0                0
#> 27               26                0                0                0
#> 28               27                0                0                0
#> 29                0               28                0                0
#> 30                0               29                0                0
#> 31                0                0                0                0
#> 32                0                0                0                0
#> 33                0                0                0                0
#> 34                0                0                0                0
#> 35                0                0                0                0
#> 36                0                0                0                0
#> 37                0                0                0                0
#> 38                0                0                0                0
#> 39                0                0                0                0
#> 40                0                0                0                0
#>    week1:month1:day week2:month1:day week3:month1:day week4:month1:day
#> 1                 0                0                0                0
#> 2                 0                0                0                0
#> 3                 0                0                0                0
#> 4                 0                0                0                0
#> 5                 0                0                0                0
#> 6                 0                0                0                0
#> 7                 0                0                0                0
#> 8                 0                0                0                0
#> 9                 0                0                0                0
#> 10                0                0                0                0
#> 11                0                0                0                0
#> 12                0                0                0                0
#> 13                0                0                0                0
#> 14                0                0                0                0
#> 15                0                0                0                0
#> 16                0                0                0                0
#> 17                0                0                0                0
#> 18                0                0                0                0
#> 19                0                0                0                0
#> 20                0                0                0                0
#> 21                0                0                0                0
#> 22                0                0                0                0
#> 23                0                0                0                0
#> 24                0                0                0                0
#> 25                0                0                0                0
#> 26                0                0                0                0
#> 27                0                0                0                0
#> 28                0                0                0                0
#> 29                0                0                0                0
#> 30                0                0                0                0
#> 31                0                0                0               30
#> 32                0                0                0               31
#> 33                0                0                0               32
#> 34                0                0                0               33
#> 35                0                0                0               34
#> 36                0                0                0                0
#> 37                0                0                0                0
#> 38                0                0                0                0
#> 39                0                0                0                0
#> 40                0                0                0                0
#>    week5:month1:day
#> 1                 0
#> 2                 0
#> 3                 0
#> 4                 0
#> 5                 0
#> 6                 0
#> 7                 0
#> 8                 0
#> 9                 0
#> 10                0
#> 11                0
#> 12                0
#> 13                0
#> 14                0
#> 15                0
#> 16                0
#> 17                0
#> 18                0
#> 19                0
#> 20                0
#> 21                0
#> 22                0
#> 23                0
#> 24                0
#> 25                0
#> 26                0
#> 27                0
#> 28                0
#> 29                0
#> 30                0
#> 31                0
#> 32                0
#> 33                0
#> 34                0
#> 35                0
#> 36               35
#> 37               36
#> 38               37
#> 39               38
#> 40               39
#> 
#> $fixed$index
#>   [1]  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25
#>  [26] 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40  1  2  3  4  5  6  7  8  9 10
#>  [51] 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35
#>  [76] 36 37 38 39 40  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20
#> [101] 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40  1  2  3  4  5
#> [126]  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30
#> [151] 31 32 33 34 35 36 37 38 39 40  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15
#> [176] 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40
#> [201]  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25
#> [226] 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40  1  2  3  4  5  6  7  8  9 10
#> [251] 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35
#> [276] 36 37 38 39 40
#> 
#> 
#> $random
#> $random$formula
#> [1] "~0 + fixed + week__month0 + week__month1 + day__week__month0 + day__week__month1"
#> 
#> $random$design
#>    fixed week__month0 week__month1 day__week__month0 day__week__month1
#> 1      0            1            0                 0                 0
#> 2      0            1            0                 0                 0
#> 3      0            1            0                 0                 0
#> 4      0            1            0                 0                 0
#> 5      0            1            0                 0                 0
#> 6      0            1            0                 0                 0
#> 7      0            0            1                 0                 0
#> 8      0            0            1                 0                 0
#> 9      0            0            1                 0                 0
#> 10     0            0            1                 0                 0
#> 11     0            0            1                 0                 0
#> 12     0            0            1                 0                 0
#> 13     0            0            0                 1                 0
#> 14     0            0            0                 1                 0
#> 15     0            0            0                 1                 0
#> 16     0            0            0                 1                 0
#> 17     0            0            0                 1                 0
#> 18     0            0            0                 1                 0
#> 19     0            0            0                 0                 1
#> 20     0            0            0                 0                 1
#> 21     0            0            0                 0                 1
#> 22     0            0            0                 0                 1
#> 23     0            0            0                 0                 1
#> 24     0            0            0                 0                 1
#> attr(,"assign")
#> [1] 1 2 3 4 5
#> 
#> $random$index
#>  [1]  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
#> 
#> 
#> attr(,"class")
#> [1] "enw_formula" "list"       
```

# Map property names onto soil function groups

Assigns a set of property names to the functions in
[`soil_function_groups`](https://ccarbajal16.github.io/soilquality/reference/soil_function_groups.md),
producing a list suitable for the `groups` argument of
[`pca_select_mds`](https://ccarbajal16.github.io/soilquality/reference/pca_select_mds.md)
and
[`na_select_mds`](https://ccarbajal16.github.io/soilquality/reference/na_select_mds.md).

## Usage

``` r
assign_function_groups(
  properties,
  groups = soil_function_groups,
  drop_empty = TRUE
)
```

## Arguments

- properties:

  Character vector of property names.

- groups:

  A named list of character vectors defining the functions. Defaults to
  [`soil_function_groups`](https://ccarbajal16.github.io/soilquality/reference/soil_function_groups.md).

- drop_empty:

  If `TRUE` (the default), functions with no matching property are
  omitted from the result.

## Value

A named list of character vectors, one per function, plus an
`"unassigned"` element when some properties matched nothing.

## Details

Matching is case-insensitive and exact on the property name. Properties
that match nothing are reported in the `"unassigned"` element rather
than being silently dropped, so that a typo or an indicator outside the
known vocabulary is visible. Empty groups are removed unless
`drop_empty = FALSE`.

An unassigned indicator is **excluded from grouped selection**: the
selection functions only look inside the groups they are given. If an
indicator matters, put it in a group explicitly.

## See also

[`soil_function_groups`](https://ccarbajal16.github.io/soilquality/reference/soil_function_groups.md)

## Examples

``` r
assign_function_groups(c("pH", "OM", "SOC", "BD", "N"))
#> $carbon_cycling
#> [1] "OM"  "SOC"
#> 
#> $nutrient_cycling
#> [1] "N"
#> 
#> $physical_structure
#> [1] "BD"
#> 
#> $buffering_filtration
#> [1] "pH"
#> 

# Unknown names are surfaced, not swallowed
assign_function_groups(c("OM", "Zn", "typo"))
#> $carbon_cycling
#> [1] "OM"
#> 
#> $unassigned
#> [1] "Zn"   "typo"
#> 
```

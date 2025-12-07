# Generate standard scoring rules for soil properties

Automatically assigns appropriate scoring rules to soil properties based
on pattern matching of property names. This function provides sensible
defaults for common soil properties, reducing the need to manually
specify scoring rules for each property.

## Usage

``` r
standard_scoring_rules(properties)
```

## Arguments

- properties:

  Character vector of property names, or a single string naming a
  pre-defined property set from
  [`soil_property_sets`](https://ccarbajal16.github.io/soilquality/reference/soil_property_sets.md).
  If a property set name is provided (e.g., "basic", "standard"), the
  corresponding properties from `soil_property_sets` will be used.

## Value

A named list of `scoring_rule` objects, one for each property. The names
of the list correspond to the property names.

## Details

The function applies the following pattern matching rules
(case-insensitive):

- Properties containing "ph":
  [`optimum_range`](https://ccarbajal16.github.io/soilquality/reference/optimum_range.md)(7,
  1)

- Properties containing "ec" or "electrical":
  [`lower_better`](https://ccarbajal16.github.io/soilquality/reference/lower_better.md)()

- Properties containing "bd" or "bulk":
  [`lower_better`](https://ccarbajal16.github.io/soilquality/reference/lower_better.md)()

- Properties containing "om", "soc", or "organic":
  [`higher_better`](https://ccarbajal16.github.io/soilquality/reference/higher_better.md)()

- Properties containing "n", "nitrogen", "p", "phosph", "k", or
  "potass":
  [`higher_better`](https://ccarbajal16.github.io/soilquality/reference/higher_better.md)()

- Properties containing "cec", "ca", or "mg":
  [`higher_better`](https://ccarbajal16.github.io/soilquality/reference/higher_better.md)()

- All other properties:
  [`higher_better`](https://ccarbajal16.github.io/soilquality/reference/higher_better.md)()
  (default)

## See also

[`soil_property_sets`](https://ccarbajal16.github.io/soilquality/reference/soil_property_sets.md),
[`higher_better`](https://ccarbajal16.github.io/soilquality/reference/higher_better.md),
[`lower_better`](https://ccarbajal16.github.io/soilquality/reference/lower_better.md),
[`optimum_range`](https://ccarbajal16.github.io/soilquality/reference/optimum_range.md)

## Examples

``` r
# Generate rules for basic property set
rules <- standard_scoring_rules("basic")
names(rules)
#> [1] "pH" "OM" "P"  "K" 

# Generate rules for custom properties
custom_props <- c("pH", "BD", "OM", "Sand")
rules <- standard_scoring_rules(custom_props)

# View a specific rule
rules$pH
#> Scoring Rule: optimum_range 
#>   Type: Optimum range
#>   Optimal value: 7 
#>   Tolerance: 1 
#>   Penalty: linear 

# Use with standard property sets
rules <- standard_scoring_rules(soil_property_sets$standard)
```

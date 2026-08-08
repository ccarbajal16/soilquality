# Generate standard scoring rules for soil properties

Automatically assigns appropriate scoring rules to soil properties based
on pattern matching of property names. This function provides sensible
defaults for common soil properties, reducing the need to manually
specify scoring rules for each property.

## Usage

``` r
standard_scoring_rules(properties, scoring = c("linear", "sigmoid"), b = 2.5)
```

## Arguments

- properties:

  Character vector of property names, or a single string naming a
  pre-defined property set from
  [`soil_property_sets`](https://ccarbajal16.github.io/soilquality/reference/soil_property_sets.md).
  If a property set name is provided (e.g., "basic", "standard"), the
  corresponding properties from `soil_property_sets` will be used.

- scoring:

  Either `"linear"` (the default, and the historical behaviour) or
  `"sigmoid"`. With `"sigmoid"`, every monotonic rule is emitted as a
  [`sigmoid_scoring`](https://ccarbajal16.github.io/soilquality/reference/sigmoid_scoring.md)
  rule instead of
  [`higher_better`](https://ccarbajal16.github.io/soilquality/reference/higher_better.md)
  /
  [`lower_better`](https://ccarbajal16.github.io/soilquality/reference/lower_better.md).
  Non-monotonic rules are unaffected – see Details.

- b:

  Shape parameter passed to
  [`sigmoid_scoring`](https://ccarbajal16.github.io/soilquality/reference/sigmoid_scoring.md)
  when `scoring = "sigmoid"`. Ignored otherwise. Defaults to 2.5.

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

With `scoring = "sigmoid"` the same pattern matching runs, and then
every `higher_better`/`lower_better` rule is replaced by the
corresponding
[`sigmoid_scoring`](https://ccarbajal16.github.io/soilquality/reference/sigmoid_scoring.md)
rule. **pH is left as an optimum-range rule**: the sigmoidal curve is
monotonic and has no optimum form, so there is nothing to convert it to.
The same applies to any threshold rule. This means a "sigmoid" rule set
is in practice a mixed set, which is what the published recipes actually
do.

The reference value `x0` is left `NULL`, so each indicator is scored
against its own mean when the rule is applied. Override it per indicator
with
[`sigmoid_scoring`](https://ccarbajal16.github.io/soilquality/reference/sigmoid_scoring.md)
where an external reference is available.

Because the literature disagrees on whether linear or non-linear scoring
is preferable (see
[`score_sigmoid`](https://ccarbajal16.github.io/soilquality/reference/score_sigmoid.md)),
the intended use of this argument is to build both rule sets from the
same property list and check whether your conclusions survive the
change.

## See also

[`soil_property_sets`](https://ccarbajal16.github.io/soilquality/reference/soil_property_sets.md),
[`higher_better`](https://ccarbajal16.github.io/soilquality/reference/higher_better.md),
[`lower_better`](https://ccarbajal16.github.io/soilquality/reference/lower_better.md),
[`optimum_range`](https://ccarbajal16.github.io/soilquality/reference/optimum_range.md),
[`sigmoid_scoring`](https://ccarbajal16.github.io/soilquality/reference/sigmoid_scoring.md)

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

# Non-linear scoring for the same property set
nl_rules <- standard_scoring_rules("basic", scoring = "sigmoid")
nl_rules$OM
#> Scoring Rule: sigmoid_scoring 
#>   Type: Non-linear (sigmoidal) scoring
#>   Direction: Higher values are better 
#>   Reference (x0): mean of the indicator 
#>   Shape (b): 2.5 

# pH stays an optimum rule -- the sigmoid has no optimum form
nl_rules$pH
#> Scoring Rule: optimum_range 
#>   Type: Optimum range
#>   Optimal value: 7 
#>   Tolerance: 1 
#>   Penalty: linear 
```

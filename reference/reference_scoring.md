# Create a reference-soil scoring rule

Creates a scoring rule that standardises an indicator against a
non-degraded reference soil rather than against the sample's own
extremes. See
[`standardize_to_reference`](https://ccarbajal16.github.io/soilquality/reference/standardize_to_reference.md)
for what that buys and what it costs.

## Usage

``` r
reference_scoring(
  reference,
  direction = c("higher", "lower", "optimum"),
  tolerance = NULL,
  clamp = TRUE
)
```

## Arguments

- reference:

  Single numeric value: the indicator measured in the reference soil, or
  the optimal value when `direction = "optimum"`.

- direction:

  One of `"higher"` (the default), `"lower"` or `"optimum"`.

- tolerance:

  Required for `direction = "optimum"`.

- clamp:

  Passed to
  [`standardize_to_reference`](https://ccarbajal16.github.io/soilquality/reference/standardize_to_reference.md).

## Value

A scoring_rule object of class c("scoring_rule", "reference_scoring")

## See also

[`standardize_to_reference`](https://ccarbajal16.github.io/soilquality/reference/standardize_to_reference.md),
[`higher_better`](https://ccarbajal16.github.io/soilquality/reference/higher_better.md)
for the sample-relative equivalent

## Examples

``` r
rules <- list(
  OM = reference_scoring(reference = 4.2),
  BD = reference_scoring(reference = 1.2, direction = "lower"),
  pH = reference_scoring(reference = 6.5, direction = "optimum",
                         tolerance = 1.5)
)

result <- compute_sqi_properties(
  soil_structured, properties = names(rules), id_column = "SampleID",
  scoring_rules = rules
)
#> Warning: 20 of 120 samples scored above the reference and were capped at 1. That usually means the reference soil is not the least disturbed one available. Pass clamp = FALSE to see the raw ratios.
```

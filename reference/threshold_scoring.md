# Create a threshold-based scoring rule

Creates a scoring rule object for indicators with custom piecewise
linear scoring based on threshold-score pairs. Values are scored using
linear interpolation between the specified thresholds.

## Usage

``` r
threshold_scoring(thresholds, scores)
```

## Arguments

- thresholds:

  Numeric vector of threshold values (should be sorted in ascending
  order)

- scores:

  Numeric vector of scores corresponding to each threshold. Must have
  the same length as thresholds.

## Value

A scoring_rule object of class c("scoring_rule", "threshold_scoring")

## See also

[`higher_better`](https://ccarbajal16.github.io/soilquality/reference/higher_better.md),
[`lower_better`](https://ccarbajal16.github.io/soilquality/reference/lower_better.md),
[`optimum_range`](https://ccarbajal16.github.io/soilquality/reference/optimum_range.md)

## Examples

``` r
# Create a rule for phosphorus with custom thresholds
p_rule <- threshold_scoring(
  thresholds = c(0, 10, 20, 30),
  scores = c(0, 0.5, 1.0, 1.0)
)

# Create a rule with non-linear scoring pattern
custom_rule <- threshold_scoring(
  thresholds = c(0, 5, 15, 25, 40),
  scores = c(0, 0.3, 0.8, 1.0, 0.9)
)
```

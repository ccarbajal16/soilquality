# Create a lower-is-better scoring rule

Creates a scoring rule object for indicators where lower values indicate
better soil quality. The rule will normalize values using inverted
min-max normalization: (max - x) / (max - min).

## Usage

``` r
lower_better(min_value = NULL, max_value = NULL)
```

## Arguments

- min_value:

  Optional minimum value for normalization. If NULL, the minimum will be
  calculated from the data.

- max_value:

  Optional maximum value for normalization. If NULL, the maximum will be
  calculated from the data.

## Value

A scoring_rule object of class c("scoring_rule", "lower_better")

## See also

[`higher_better`](https://ccarbajal16.github.io/soilquality/reference/higher_better.md),
[`optimum_range`](https://ccarbajal16.github.io/soilquality/reference/optimum_range.md),
[`threshold_scoring`](https://ccarbajal16.github.io/soilquality/reference/threshold_scoring.md)

## Examples

``` r
# Create a rule for bulk density (lower is better)
bd_rule <- lower_better()

# With custom min/max values
bd_rule <- lower_better(min_value = 1.0, max_value = 1.8)
```

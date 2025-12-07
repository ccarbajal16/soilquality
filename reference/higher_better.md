# Create a higher-is-better scoring rule

Creates a scoring rule object for indicators where higher values
indicate better soil quality. The rule will normalize values using
min-max normalization: (x - min) / (max - min).

## Usage

``` r
higher_better(min_value = NULL, max_value = NULL)
```

## Arguments

- min_value:

  Optional minimum value for normalization. If NULL, the minimum will be
  calculated from the data.

- max_value:

  Optional maximum value for normalization. If NULL, the maximum will be
  calculated from the data.

## Value

A scoring_rule object of class c("scoring_rule", "higher_better")

## See also

[`lower_better`](https://ccarbajal16.github.io/soilquality/reference/lower_better.md),
[`optimum_range`](https://ccarbajal16.github.io/soilquality/reference/optimum_range.md),
[`threshold_scoring`](https://ccarbajal16.github.io/soilquality/reference/threshold_scoring.md)

## Examples

``` r
# Create a rule for organic matter (higher is better)
om_rule <- higher_better()

# With custom min/max values
om_rule <- higher_better(min_value = 0, max_value = 5)
```

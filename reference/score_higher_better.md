# Score indicator with higher-is-better normalization

Normalizes values to \[0,1\] range where higher values indicate better
quality. Uses min-max normalization: (x - min) / (max - min).

## Usage

``` r
score_higher_better(x, min_val = NULL, max_val = NULL)
```

## Arguments

- x:

  Numeric vector of indicator values

- min_val:

  Minimum value for normalization. If NULL, uses min(x, na.rm = TRUE)

- max_val:

  Maximum value for normalization. If NULL, uses max(x, na.rm = TRUE)

## Value

Numeric vector of scores in \[0,1\] range

## Examples

``` r
# Higher organic matter is better
om_values <- c(1.5, 2.0, 2.5, 3.0, 3.5)
score_higher_better(om_values)
#> [1] 0.00 0.25 0.50 0.75 1.00

# With custom min/max
score_higher_better(om_values, min_val = 1, max_val = 4)
#> [1] 0.1666667 0.3333333 0.5000000 0.6666667 0.8333333
```

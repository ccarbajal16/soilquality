# Score indicator with lower-is-better normalization

Normalizes values to \[0,1\] range where lower values indicate better
quality. Uses inverted min-max normalization: (max - x) / (max - min).

## Usage

``` r
score_lower_better(x, min_val = NULL, max_val = NULL)
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
# Lower bulk density is better
bd_values <- c(1.2, 1.3, 1.4, 1.5, 1.6)
score_lower_better(bd_values)
#> [1] 1.00 0.75 0.50 0.25 0.00

# With custom min/max
score_lower_better(bd_values, min_val = 1.0, max_val = 1.8)
#> [1] 0.750 0.625 0.500 0.375 0.250
```

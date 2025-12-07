# Score indicator with threshold-based piecewise interpolation

Normalizes values to \[0,1\] range using piecewise linear interpolation
between specified threshold-score pairs.

## Usage

``` r
score_threshold(x, thresholds, scores)
```

## Arguments

- x:

  Numeric vector of indicator values

- thresholds:

  Numeric vector of threshold values (must be sorted)

- scores:

  Numeric vector of scores corresponding to thresholds

## Value

Numeric vector of scores in \[0,1\] range

## Examples

``` r
# Custom threshold scoring for phosphorus
p_values <- c(5, 10, 15, 20, 25, 30, 35)
thresholds <- c(0, 10, 20, 30)
scores <- c(0, 0.5, 1.0, 1.0)
score_threshold(p_values, thresholds, scores)
#> [1] 0.25 0.50 0.75 1.00 1.00 1.00 1.00
```

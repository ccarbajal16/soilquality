# Score indicator with optimum range

Normalizes values to \[0,1\] range where values near an optimum are
best. Uses linear or quadratic penalty based on distance from optimum.

## Usage

``` r
score_optimum(x, optimum, tol, penalty = "linear")
```

## Arguments

- x:

  Numeric vector of indicator values

- optimum:

  Optimal value for the indicator

- tol:

  Tolerance around optimum (distance where score reaches 0)

- penalty:

  Type of penalty function: "linear" or "quadratic"

## Value

Numeric vector of scores in \[0,1\] range

## Examples

``` r
# pH optimum around 7
ph_values <- c(5.5, 6.0, 6.5, 7.0, 7.5, 8.0, 8.5)
score_optimum(ph_values, optimum = 7, tol = 1.5)
#> [1] 0.0000000 0.3333333 0.6666667 1.0000000 0.6666667 0.3333333 0.0000000

# With quadratic penalty
score_optimum(ph_values, optimum = 7, tol = 1.5, penalty = "quadratic")
#> [1] 0.0000000 0.5555556 0.8888889 1.0000000 0.8888889 0.5555556 0.0000000
```

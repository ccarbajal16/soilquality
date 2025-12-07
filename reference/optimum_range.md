# Create an optimum range scoring rule

Creates a scoring rule object for indicators where values near an
optimum are best. The rule will normalize values based on distance from
the optimum, with scores decreasing linearly or quadratically as values
move away from the optimum.

## Usage

``` r
optimum_range(optimal, tolerance = 1, penalty = "linear")
```

## Arguments

- optimal:

  The optimal value for the indicator

- tolerance:

  The distance from optimal where score reaches 0. Must be a positive
  number.

- penalty:

  Type of penalty function: "linear" (default) or "quadratic". Linear
  penalty decreases score proportionally to distance, while quadratic
  penalty is more forgiving near the optimum.

## Value

A scoring_rule object of class c("scoring_rule", "optimum_range")

## See also

[`higher_better`](https://ccarbajal16.github.io/soilquality/reference/higher_better.md),
[`lower_better`](https://ccarbajal16.github.io/soilquality/reference/lower_better.md),
[`threshold_scoring`](https://ccarbajal16.github.io/soilquality/reference/threshold_scoring.md)

## Examples

``` r
# Create a rule for pH (optimum around 7)
ph_rule <- optimum_range(optimal = 7, tolerance = 1.5)

# With quadratic penalty for more gradual decrease
ph_rule <- optimum_range(optimal = 7, tolerance = 1.5,
                         penalty = "quadratic")
```

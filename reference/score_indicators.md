# Score multiple indicators using specified scoring functions

Applies appropriate scoring functions to each MDS indicator variable
based on the directions specification.

## Usage

``` r
score_indicators(data, mds, directions)
```

## Arguments

- data:

  Data frame containing indicator values

- mds:

  Character vector of MDS indicator names to score

- directions:

  Named list specifying scoring function for each indicator. Each
  element should be a list with 'type' and parameters: - type =
  "higher": uses score_higher_better() - type = "lower": uses
  score_lower_better() - type = "optimum": uses score_optimum()
  (requires optimum, tol, penalty) - type = "threshold": uses
  score_threshold() (requires thresholds, scores)

## Value

Data frame with original columns plus scored columns (suffixed with
"\_scored")

## Examples

``` r
if (FALSE) { # \dontrun{
data <- data.frame(
  ID = 1:5,
  OM = c(1.5, 2.0, 2.5, 3.0, 3.5),
  pH = c(5.5, 6.0, 6.5, 7.0, 7.5),
  BD = c(1.2, 1.3, 1.4, 1.5, 1.6)
)

directions <- list(
  OM = list(type = "higher"),
  pH = list(type = "optimum", optimum = 7, tol = 1.5, penalty = "linear"),
  BD = list(type = "lower")
)

scored_data <- score_indicators(data, c("OM", "pH", "BD"), directions)
} # }
```

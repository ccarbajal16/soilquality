# Create AHP pairwise comparison matrix interactively

This function creates an AHP pairwise comparison matrix through
interactive prompts or from a provided matrix. In interactive mode, it
guides the user through pairwise comparisons of all indicators,
validates inputs, calculates weights, and returns a structured
ahp_matrix object.

## Usage

``` r
create_ahp_matrix(indicators, mode = "interactive", pairwise = NULL)
```

## Arguments

- indicators:

  Character vector of indicator names to be compared.

- mode:

  Character string specifying the mode: "interactive" for guided prompts
  (default) or "matrix" to provide a pre-built matrix.

- pairwise:

  Optional pre-built pairwise comparison matrix (only used when mode =
  "matrix"). Must be a square matrix with dimensions matching the number
  of indicators.

## Value

An object of class "ahp_matrix" containing:

- indicators:

  Character vector of indicator names

- matrix:

  Numeric matrix of pairwise comparisons

- weights:

  Named numeric vector of normalized weights

- CR:

  Consistency Ratio

- lambda_max:

  Maximum eigenvalue

## Details

In interactive mode, the function displays the Saaty scale and prompts
for pairwise comparisons between all indicator pairs. The Saaty scale
is:

- 1 = Equal importance

- 3 = Moderate importance of first over second

- 5 = Strong importance of first over second

- 7 = Very strong importance of first over second

- 9 = Extreme importance of first over second

- 2, 4, 6, 8 = Intermediate values

- 1/3, 1/5, 1/7, 1/9 = Reciprocal values (second more important)

Users can enter values as decimals (e.g., 0.333) or fractions (e.g.,
"1/3"). The function validates that all inputs are within the valid
range (1/9 to 9).

After collecting all comparisons, the function calculates weights using
eigenvalue decomposition and computes the Consistency Ratio (CR). If CR
\> 0.1, a warning is displayed indicating inconsistent judgments.

## See also

[`ahp_weights`](https://ccarbajal16.github.io/soilquality/reference/ahp_weights.md),
[`ratio_to_saaty`](https://ccarbajal16.github.io/soilquality/reference/ratio_to_saaty.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Interactive mode - prompts user for comparisons
ahp_result <- create_ahp_matrix(c("pH", "OM", "P"))
print(ahp_result)
} # }

# Matrix mode - provide pre-built matrix
pairwise <- matrix(c(
  1,   3,   5,
  1/3, 1,   2,
  1/5, 1/2, 1
), nrow = 3, byrow = TRUE)
ahp_result <- create_ahp_matrix(
  indicators = c("pH", "OM", "P"),
  mode = "matrix",
  pairwise = pairwise
)
print(ahp_result)
#> 
#> === AHP Pairwise Comparison Matrix ===
#> 
#> Pairwise Comparison Matrix:
#>       pH  OM P
#> pH 1.000 3.0 5
#> OM 0.333 1.0 2
#> P  0.200 0.5 1
#> 
#> Indicator Weights:
#>   pH             : 0.6483
#>   OM             : 0.2297
#>   P              : 0.1220
#> 
#> Consistency Information:
#>   Lambda Max: 3.0037
#>   Consistency Ratio (CR): 0.0032 [✓ Acceptable]
#> 
```

# Calculate AHP weights from pairwise comparison matrix

This function calculates indicator weights using the Analytic Hierarchy
Process (AHP) method based on a pairwise comparison matrix. It computes
weights using eigenvalue decomposition and calculates the Consistency
Ratio (CR) to assess the logical consistency of the judgments.

## Usage

``` r
ahp_weights(pairwise, indicators = NULL)
```

## Arguments

- pairwise:

  A square numeric matrix of pairwise comparisons where element \[i,j\]
  represents the relative importance of indicator i compared to
  indicator j. The matrix must be reciprocal (A\[i,j\] = 1/A\[j,i\])
  with diagonal values equal to 1.

- indicators:

  Optional character vector of indicator names. If NULL, uses row names
  from the pairwise matrix or generates default names.

## Value

A list with the following components:

- weights:

  Named numeric vector of normalized weights summing to 1

- CR:

  Consistency Ratio, a measure of logical consistency (should be \< 0.1)

- lambda_max:

  Maximum eigenvalue of the pairwise matrix

## Details

The AHP method uses eigenvalue decomposition to derive weights from
pairwise comparisons. The Consistency Ratio (CR) is calculated as:
\$\$CR = CI / RI\$\$ where CI (Consistency Index) = (lambda_max - n) /
(n - 1) and RI is the Random Consistency Index that depends on matrix
size.

A CR value less than 0.1 indicates acceptable consistency. Values
exceeding 0.1 suggest that the pairwise judgments may be inconsistent
and should be revised.

## Examples

``` r
# Create a 3x3 pairwise comparison matrix
pairwise <- matrix(c(
  1,   3,   5,
  1/3, 1,   2,
  1/5, 1/2, 1
), nrow = 3, byrow = TRUE)

# Calculate weights
result <- ahp_weights(pairwise, indicators = c("pH", "OM", "P"))
print(result$weights)
#>        pH        OM         P 
#> 0.6483290 0.2296508 0.1220202 
print(result$CR)
#> [1] 0.003184998
```

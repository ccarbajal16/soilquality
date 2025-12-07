# Convert importance ratios to Saaty pairwise comparison matrix

This helper function converts a vector of importance ratios into a
pairwise comparison matrix following the Saaty scale (1-9). The ratios
represent the relative importance of each indicator compared to a
baseline.

## Usage

``` r
ratio_to_saaty(ratios)
```

## Arguments

- ratios:

  Numeric vector of importance ratios. Each value represents how many
  times more important an indicator is compared to a baseline. Values
  should be positive numbers.

## Value

A square numeric matrix of pairwise comparisons where element \[i,j\]
represents the relative importance of indicator i compared to indicator
j. The matrix is reciprocal with diagonal values equal to 1.

## Details

The function constructs a pairwise comparison matrix from importance
ratios by calculating the ratio between each pair of indicators. For
indicators with ratios r_i and r_j, the pairwise comparison is r_i /
r_j.

The Saaty scale typically uses values from 1/9 to 9, where:

- 1 = Equal importance

- 3 = Moderate importance

- 5 = Strong importance

- 7 = Very strong importance

- 9 = Extreme importance

- 2, 4, 6, 8 = Intermediate values

## Examples

``` r
# Three indicators with importance ratios 5:3:1
ratios <- c(5, 3, 1)
pairwise <- ratio_to_saaty(ratios)
print(pairwise)
#>      [,1]      [,2] [,3]
#> [1,]  1.0 1.6666667    5
#> [2,]  0.6 1.0000000    3
#> [3,]  0.2 0.3333333    1

# Calculate weights from the matrix
result <- ahp_weights(pairwise, indicators = c("pH", "OM", "P"))
```

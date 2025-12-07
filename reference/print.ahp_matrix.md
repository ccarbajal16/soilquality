# Print method for ahp_matrix objects

Displays a formatted summary of an AHP pairwise comparison matrix
including the matrix itself, calculated weights, and consistency
information.

## Usage

``` r
# S3 method for class 'ahp_matrix'
print(x, ...)
```

## Arguments

- x:

  An object of class "ahp_matrix" created by
  [`create_ahp_matrix`](https://ccarbajal16.github.io/soilquality/reference/create_ahp_matrix.md).

- ...:

  Additional arguments passed to print methods (currently unused).

## Value

Invisibly returns the input object.

## Details

The print method displays:

- The pairwise comparison matrix with indicator names

- Normalized weights for each indicator

- Consistency Ratio (CR) with a status indicator

- Maximum eigenvalue (lambda_max)

The consistency status shows a checkmark (✓) if CR \<= 0.1 (acceptable
consistency) or an X (✗) if CR \> 0.1 (inconsistent judgments).

## See also

[`create_ahp_matrix`](https://ccarbajal16.github.io/soilquality/reference/create_ahp_matrix.md),
[`ahp_weights`](https://ccarbajal16.github.io/soilquality/reference/ahp_weights.md)

## Examples

``` r
# Create an AHP matrix
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

# Print the result
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

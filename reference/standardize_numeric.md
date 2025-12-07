# Standardize Numeric Columns

Applies z-score standardization to numeric columns in a data frame.
Non-numeric columns are preserved unchanged. This function is useful for
preparing soil property data for multivariate analysis such as PCA.

## Usage

``` r
standardize_numeric(df, exclude = NULL)
```

## Arguments

- df:

  A data frame containing soil property data.

- exclude:

  Optional character vector of column names to exclude from
  standardization. These columns will be preserved in their original
  form. Default is NULL (no exclusions).

## Value

A data frame with the same structure as the input, where numeric columns
(except those excluded) have been standardized to have mean = 0 and
standard deviation = 1. Non-numeric columns and excluded columns are
returned unchanged.

## Details

Z-score standardization is calculated as: (x - mean(x)) / sd(x)

Columns with zero variance (sd = 0) are left unchanged to avoid division
by zero. NA values are preserved in their positions.

## Examples

``` r
# Create example soil data
soil_data <- data.frame(
  SampleID = c("S1", "S2", "S3", "S4"),
  pH = c(6.5, 7.0, 6.8, 7.2),
  OM = c(3.2, 2.8, 3.5, 3.0),
  Sand = c(45, 50, 42, 48)
)

# Standardize all numeric columns, preserve SampleID
standardized <- standardize_numeric(soil_data, exclude = "SampleID")

# Verify standardization
colMeans(standardized[, c("pH", "OM", "Sand")], na.rm = TRUE)
#>            pH            OM          Sand 
#> -1.387779e-17  1.387779e-17  1.387779e-17 
apply(standardized[, c("pH", "OM", "Sand")], 2, sd, na.rm = TRUE)
#>   pH   OM Sand 
#>    1    1    1 
```

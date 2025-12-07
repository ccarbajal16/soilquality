# Compute Soil Quality Index from data frame

This is the in-memory workflow function that orchestrates the complete
SQI calculation pipeline using data frames. It performs standardization,
PCA-based MDS selection, AHP weighting, indicator scoring, and
calculates the final Soil Quality Index.

## Usage

``` r
compute_sqi_df(
  df,
  id_column = NULL,
  pairwise_df = NULL,
  directions = NULL,
  var_threshold = 0.05,
  loading_threshold = 0.5,
  ...
)
```

## Arguments

- df:

  Data frame containing soil property data with samples in rows and
  properties in columns.

- id_column:

  Optional character string specifying the name of the ID column to
  preserve in the output. If NULL, no ID column is preserved.

- pairwise_df:

  Optional pairwise comparison matrix (as matrix or data frame). If
  NULL, equal weights are used for all indicators.

- directions:

  Optional named list specifying scoring functions for each indicator.
  If NULL, all indicators use higher-is-better scoring.

- var_threshold:

  Numeric value for PCA variance threshold (default 0.05).

- loading_threshold:

  Numeric value for PCA loading threshold (default 0.5).

- ...:

  Additional arguments (currently unused).

## Value

An object of class "sqi_result" containing:

- mds:

  Character vector of selected MDS indicators

- weights:

  Named numeric vector of AHP weights

- CR:

  Consistency Ratio from AHP

- results:

  Data frame with original data, scored indicators, and SQI

- pca:

  PCA object from stats::prcomp

- loadings:

  Matrix of variable loadings

- var_exp:

  Numeric vector of variance explained by each PC

## Details

The function performs the following steps:

1.  Preserve ID column if specified

2.  Standardize numeric columns (z-score)

3.  Perform PCA and select MDS indicators

4.  Calculate AHP weights (from pairwise matrix or equal weights)

5.  Score each MDS indicator

6.  Calculate weighted SQI as sum of (weight \* score)

## See also

[`compute_sqi`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi.md),
[`compute_sqi_properties`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_properties.md)

## Examples

``` r
# Create example data
soil_data <- data.frame(
  SampleID = paste0("S", 1:20),
  Sand = rnorm(20, 45, 10),
  Silt = rnorm(20, 30, 5),
  Clay = rnorm(20, 25, 5),
  pH = rnorm(20, 6.5, 0.5),
  OM = rnorm(20, 3, 0.5)
)

# Compute SQI
result <- compute_sqi_df(soil_data, id_column = "SampleID")

# View results
head(result$results)
#>   SampleID     Sand     Silt     Clay       pH       OM OM_scored Sand_scored
#> 1       S1 44.94429 33.68888 23.74258 6.377052 3.278112 0.7394162  0.47286736
#> 2       S2 51.21553 39.44252 27.22399 5.911218 2.725871 0.4816739  0.63252067
#> 3       S3 56.48412 29.51277 38.77709 6.012075 3.555267 0.8687703  0.76664847
#> 4       S4 26.78182 25.32076 25.23266 7.032529 1.693833 0.0000000  0.01048713
#> 5       S5 42.52675 29.92025 27.88855 6.565835 2.922153 0.5732827  0.41132159
#> 6       S6 42.55800 25.86606 25.59097 6.744314 3.216945 0.7108681  0.41211733
#>   pH_scored Silt_scored       SQI
#> 1 0.4011139   0.6970645 0.5776155
#> 2 0.1440168   1.0000000 0.5645528
#> 3 0.1996802   0.4771879 0.5780717
#> 4 0.7628767   0.2564740 0.2574594
#> 5 0.5053050   0.4986419 0.4971378
#> 6 0.6038090   0.2851842 0.5029947
print(result$mds)
#> [1] "OM"   "Sand" "pH"   "Silt"
print(result$weights)
#>   OM Sand   pH Silt 
#> 0.25 0.25 0.25 0.25 
```

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
  method = c("weighted", "area"),
  reference = NULL,
  select = c("pca", "none"),
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

- method:

  Aggregation method. `"weighted"` (the default, and the historical
  behaviour) computes the weighted sum of scored indicators. `"area"`
  computes the area of the radar diagram they trace, which ignores
  weights entirely – see
  [`sqi_area`](https://ccarbajal16.github.io/soilquality/reference/sqi_area.md).

- reference:

  Optional named numeric vector of reference scores for the MDS
  indicators, used only when `method = "area"`. When supplied, the SQI
  is reported as a ratio against this non-degraded reference soil, which
  is what makes area-based values comparable across studies. Names must
  cover every selected MDS indicator.

- select:

  Indicator selection strategy. `"pca"` (the default, and the historical
  behaviour) selects a Minimum Data Set via
  [`pca_select_mds`](https://ccarbajal16.github.io/soilquality/reference/pca_select_mds.md).
  `"none"` skips selection and uses **every** numeric indicator – the
  "total data set" (TDS) index that
  [`sqi_validate`](https://ccarbajal16.github.io/soilquality/reference/sqi_validate.md)
  measures fidelity against. PCA is still run and reported in either
  case.

- ...:

  Additional arguments (currently unused).

## Value

An object of class "sqi_result" containing:

- mds:

  Character vector of selected MDS indicators

- weights:

  Named numeric vector of AHP weights. Still reported when
  `method = "area"`, but not used in the aggregation.

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

- method:

  The aggregation method used

## Details

The function performs the following steps:

1.  Preserve ID column if specified

2.  Standardize numeric columns (z-score)

3.  Perform PCA and select MDS indicators

4.  Calculate AHP weights (from pairwise matrix or equal weights)

5.  Score each MDS indicator

6.  Aggregate: weighted sum of (weight \* score), or radar-diagram area

**On `method = "area"`.** The area route is weight-free, which sidesteps
the most contested step in the pipeline. But an absolute area
(`reference = NULL`) is standardised against nothing but your own sample
and is not comparable to any other study; the comparability people cite
comes from taking the *ratio* against a reference soil, not from the
formula. Weights are still computed and returned so that the two methods
can be compared on the same object, but they do not enter the area
calculation.

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
#>   SampleID     Sand     Silt     Clay       pH       OM Silt_scored OM_scored
#> 1       S1 30.99956 32.34077 25.35017 7.037173 3.962172   0.6260850 1.0000000
#> 2       S2 47.55317 31.81476 21.80438 6.167456 3.649196   0.5983897 0.8620245
#> 3       S3 20.62736 23.47728 24.75018 7.056976 3.374396   0.1594127 0.7408782
#> 4       S4 44.94429 33.68888 23.74258 6.377052 3.278112   0.6970645 0.6984315
#> 5       S5 51.21553 39.44252 27.22399 5.911218 2.725871   1.0000000 0.4549755
#> 6       S6 56.48412 29.51277 38.77709 6.012075 3.555267   0.4771879 0.8206158
#>   Sand_scored       SQI
#> 1   0.2303762 0.6188204
#> 2   0.5980471 0.6861538
#> 3   0.0000000 0.3000970
#> 4   0.5401014 0.6451991
#> 5   0.6793915 0.7114556
#> 6   0.7964117 0.6980718
print(result$mds)
#> [1] "Silt" "OM"   "Sand"
print(result$weights)
#>      Silt        OM      Sand 
#> 0.3333333 0.3333333 0.3333333 
```

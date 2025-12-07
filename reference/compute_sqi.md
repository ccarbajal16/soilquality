# Compute Soil Quality Index from CSV file

This is the main file-based workflow function that orchestrates the
complete SQI calculation pipeline. It reads soil data from a CSV file,
performs standardization, PCA-based MDS selection, AHP weighting,
indicator scoring, and calculates the final Soil Quality Index.

## Usage

``` r
compute_sqi(
  input_csv,
  id_column = NULL,
  pairwise_csv = NULL,
  output_csv = NULL,
  directions = NULL,
  var_threshold = 0.05,
  loading_threshold = 0.5,
  ...
)
```

## Arguments

- input_csv:

  Character string specifying the path to the input CSV file containing
  soil property data. The file should have samples in rows and
  properties in columns.

- id_column:

  Optional character string specifying the name of the ID column to
  preserve in the output. If NULL, no ID column is preserved.

- pairwise_csv:

  Optional character string specifying the path to a CSV file containing
  the AHP pairwise comparison matrix. If NULL, equal weights are used
  for all indicators.

- output_csv:

  Optional character string specifying the path where the results should
  be saved as a CSV file. If NULL, results are not saved.

- directions:

  Optional named list specifying scoring functions for each indicator.
  If NULL, all indicators use higher-is-better scoring.

- var_threshold:

  Numeric value for PCA variance threshold (default 0.05).

- loading_threshold:

  Numeric value for PCA loading threshold (default 0.5).

- ...:

  Additional arguments passed to other functions.

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

1.  Read soil data from CSV file

2.  Standardize numeric columns (z-score)

3.  Perform PCA and select MDS indicators

4.  Calculate AHP weights (from pairwise matrix or equal weights)

5.  Score each MDS indicator

6.  Calculate weighted SQI as sum of (weight \* score)

7.  Optionally save results to CSV

## See also

[`compute_sqi_df`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_df.md),
[`compute_sqi_properties`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_properties.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic usage with CSV file
result <- compute_sqi(
  input_csv = "soil_data.csv",
  id_column = "SampleID"
)

# With AHP pairwise matrix
result <- compute_sqi(
  input_csv = "soil_data.csv",
  id_column = "SampleID",
  pairwise_csv = "pairwise_matrix.csv"
)

# With custom scoring directions
directions <- list(
  pH = list(type = "optimum", optimum = 7, tol = 1.5, penalty = "linear"),
  OM = list(type = "higher"),
  BD = list(type = "lower")
)
result <- compute_sqi(
  input_csv = "soil_data.csv",
  id_column = "SampleID",
  directions = directions,
  output_csv = "sqi_results.csv"
)
} # }
```

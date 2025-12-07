# Compute Soil Quality Index with property selection

This enhanced workflow function allows explicit property selection and
integrates with scoring constructor functions. It validates property
selection, subsets the data, and orchestrates the complete SQI
calculation pipeline.

## Usage

``` r
compute_sqi_properties(
  data,
  properties = NULL,
  id_column = NULL,
  pairwise_matrix = NULL,
  scoring_rules = NULL,
  var_threshold = 0.05,
  loading_threshold = 0.5,
  ...
)
```

## Arguments

- data:

  Data frame containing soil property data with samples in rows and
  properties in columns.

- properties:

  Optional character vector of property names to include in the
  analysis. If NULL, all numeric columns are used automatically.

- id_column:

  Optional character string specifying the name of the ID column to
  preserve in the output. If NULL, no ID column is preserved.

- pairwise_matrix:

  Optional pairwise comparison matrix (as matrix or data frame). If
  NULL, equal weights are used for all indicators.

- scoring_rules:

  Optional named list of scoring_rule objects created with constructor
  functions (higher_better, lower_better, optimum_range,
  threshold_scoring). If NULL, all indicators use higher-is-better
  scoring.

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

1.  Validate that all specified properties exist in data

2.  Subset data to selected properties plus ID column

3.  Convert scoring_rule objects to directions list

4.  Call compute_sqi_df() to perform the analysis

If properties is NULL, the function automatically detects and uses all
numeric columns in the data.

## See also

[`compute_sqi`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi.md),
[`compute_sqi_df`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_df.md),
[`higher_better`](https://ccarbajal16.github.io/soilquality/reference/higher_better.md),
[`lower_better`](https://ccarbajal16.github.io/soilquality/reference/lower_better.md),
[`optimum_range`](https://ccarbajal16.github.io/soilquality/reference/optimum_range.md),
[`threshold_scoring`](https://ccarbajal16.github.io/soilquality/reference/threshold_scoring.md),
[`standard_scoring_rules`](https://ccarbajal16.github.io/soilquality/reference/standard_scoring_rules.md)

## Examples

``` r
# Create example data
soil_data <- data.frame(
  SampleID = paste0("S", 1:20),
  Sand = rnorm(20, 45, 10),
  Silt = rnorm(20, 30, 5),
  Clay = rnorm(20, 25, 5),
  pH = rnorm(20, 6.5, 0.5),
  OM = rnorm(20, 3, 0.5),
  BD = rnorm(20, 1.4, 0.1)
)

# Select specific properties
result <- compute_sqi_properties(
  data = soil_data,
  properties = c("pH", "OM", "BD"),
  id_column = "SampleID"
)

# With custom scoring rules
rules <- list(
  pH = optimum_range(optimal = 7, tolerance = 1.5),
  OM = higher_better(),
  BD = lower_better()
)
result <- compute_sqi_properties(
  data = soil_data,
  properties = c("pH", "OM", "BD"),
  id_column = "SampleID",
  scoring_rules = rules
)

# Use standard scoring rules for available properties
result <- compute_sqi_properties(
  data = soil_data,
  properties = c("pH", "OM"),
  id_column = "SampleID",
  scoring_rules = standard_scoring_rules(c("pH", "OM"))
)
```

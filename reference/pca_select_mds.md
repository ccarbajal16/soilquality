# Select Minimum Data Set (MDS) Using PCA

Performs Principal Component Analysis (PCA) on soil property data and
selects a minimum data set (MDS) of indicators based on variance and
loading thresholds. This function implements the PCA-based MDS selection
methodology commonly used in soil quality assessment.

## Usage

``` r
pca_select_mds(data, var_threshold = 0.05, loading_threshold = 0.5)
```

## Arguments

- data:

  A data frame containing standardized soil property measurements. All
  columns should be numeric. It is recommended to standardize the data
  using
  [`standardize_numeric`](https://ccarbajal16.github.io/soilquality/reference/standardize_numeric.md)
  before applying PCA.

- var_threshold:

  Numeric value specifying the minimum proportion of variance a
  principal component must explain to be retained. Components with
  variance below this threshold are excluded from MDS selection. Default
  is 0.05 (5%).

- loading_threshold:

  Numeric value specifying the minimum absolute loading value for a
  variable to be considered for selection within a principal component.
  Variables with absolute loadings below this threshold are not
  selected. Default is 0.5.

## Value

A list with the following components:

- mds:

  Character vector of selected variable names representing the minimum
  data set.

- pca:

  The PCA object returned by
  [`stats::prcomp`](https://rdrr.io/r/stats/prcomp.html), containing the
  full PCA results including rotation matrix, scores, and other
  components.

- loadings:

  Numeric matrix of variable loadings (rotation matrix) for all
  principal components.

- var_exp:

  Numeric vector containing the proportion of variance explained by each
  principal component.

## Details

The MDS selection algorithm follows these steps:

1.  Perform PCA using
    [`stats::prcomp`](https://rdrr.io/r/stats/prcomp.html) with scaling
    disabled (data should be pre-standardized).

2.  Calculate the proportion of variance explained by each PC.

3.  Identify PCs that explain variance greater than `var_threshold`.

4.  For each retained PC, identify the variable with the maximum
    absolute loading that exceeds `loading_threshold`.

5.  Return the unique set of selected variables as the MDS.

If no variables meet the selection criteria, an empty character vector
is returned for the MDS component.

## See also

[`standardize_numeric`](https://ccarbajal16.github.io/soilquality/reference/standardize_numeric.md)
for data standardization

## Examples

``` r
# Create example soil data
soil_data <- data.frame(
  Sand = c(45, 50, 42, 48, 52, 38, 44, 49),
  Silt = c(30, 28, 35, 32, 25, 40, 33, 29),
  Clay = c(25, 22, 23, 20, 23, 22, 23, 22),
  pH = c(6.5, 7.0, 6.8, 7.2, 6.9, 6.7, 7.1, 6.6),
  OM = c(3.2, 2.8, 3.5, 3.0, 2.9, 3.3, 3.1, 3.4)
)

# Standardize the data first
soil_std <- standardize_numeric(soil_data)

# Select MDS using PCA
result <- pca_select_mds(soil_std)

# View selected indicators
print(result$mds)
#> [1] "Sand" "Clay"

# View variance explained
print(result$var_exp)
#> [1] 5.364949e-01 3.191878e-01 1.052890e-01 3.902825e-02 2.001949e-33

# Use custom thresholds
result2 <- pca_select_mds(soil_std,
                          var_threshold = 0.10,
                          loading_threshold = 0.6)
```

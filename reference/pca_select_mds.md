# Select Minimum Data Set (MDS) Using PCA

Performs Principal Component Analysis (PCA) on soil property data and
selects a minimum data set (MDS) of indicators based on variance and
loading thresholds. This function implements the PCA-based MDS selection
methodology commonly used in soil quality assessment.

## Usage

``` r
pca_select_mds(
  data,
  var_threshold = 0.05,
  loading_threshold = 0.5,
  within = NULL,
  groups = NULL,
  selector = c("loading", "norm")
)
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

  Numeric value specifying the minimum **absolute** loading a variable
  must reach to be considered. This is a floor on the loading itself,
  not the relative "within 10 percent" rule of the literature – see
  `within`. Default is 0.5.

- within:

  Relative tolerance below the maximum absolute loading on a retained
  component, within which **every** variable is selected. `NULL` (the
  default) keeps the historical behaviour of taking only the single
  highest-loading variable per component. Set `0.10` for the published
  rule. See Details – this changes the size of the MDS.

- groups:

  Optional named list of character vectors assigning indicators to
  functional groups, as produced by
  [`assign_function_groups`](https://ccarbajal16.github.io/soilquality/reference/assign_function_groups.md).
  When supplied, selection runs **within each group** rather than across
  the whole pool, which is the expanded minimum data set (EMDS) of the
  literature. Empty groups are skipped. Defaults to `NULL` (no
  grouping).

- selector:

  How to choose within a component or group. `"loading"` (the default)
  uses absolute loadings per retained component. `"norm"` uses the norm
  value of Yuan and Shi (2026) eq. (2), which aggregates an indicator's
  loadings across components rather than judging it one component at a
  time; it is designed for the grouped route and returns the
  highest-norm indicator per group.

## Value

A list with the following components:

- mds:

  Character vector of selected variable names representing the minimum
  data set.

- pca:

  The PCA object returned by
  [`stats::prcomp`](https://rdrr.io/r/stats/prcomp.html), computed over
  the whole pool regardless of grouping, containing the full PCA results
  including rotation matrix, scores, and other components.

- loadings:

  Numeric matrix of variable loadings (rotation matrix) for all
  principal components.

- var_exp:

  Numeric vector containing the proportion of variance explained by each
  principal component.

- groups:

  The validated grouping, or `NULL`.

- group_results:

  Per-group selection detail, including the norm values when
  `selector = "norm"`, or `NULL`.

- selector, within:

  The settings used.

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

## The two loading rules, and why the default is the narrow one

Step 4 above takes **one** indicator per retained component, the one
with the largest absolute loading. The rule stated in the soil quality
literature is broader: keep **every** indicator whose absolute loading
is within 10 percent of that maximum, i.e.
`abs(loading) >= 0.9 * max(abs(loading))`. That generally yields a
*larger* minimum data set.

Both are available. `within = NULL` keeps the narrow rule, which is what
this function has always done and what the package's regression baseline
pins; `within = 0.10` implements the published rule. The default does
not move, because widening the MDS changes every downstream weight and
every SQI value.

Note that `loading_threshold` and `within` are different mechanisms and
can be combined: the first is an **absolute** floor on the loading, the
second a **relative** band below the maximum.

**A warning for anyone implementing from Yuan and Shi (2026).** Its
section 2.3.1 states this rule *inverted* – as retaining loadings
"within 10 percent" in the sense of being *less than* 10 percent of the
highest, which would select the least informative variables. The paper's
own section 2.3.2, and every other source, state it correctly. Read it
as `>= 0.9 * max`.

## Grouped (EMDS) selection

With `groups`, the selection runs separately inside each functional
group and the results are combined. This is the expanded minimum data
set: every function contributes an indicator, instead of the whole pool
competing on a single criterion where one dominant function can crowd
the others out.

That failure mode is not hypothetical in this package. On
[`soil_structured`](https://ccarbajal16.github.io/soilquality/reference/soil_structured.md),
with all fifteen indicators offered:

|                    |                    |                       |
|--------------------|--------------------|-----------------------|
| **Route**          | **Selected**       | **Functions covered** |
| network, ungrouped | OM, CEC            | 2 of 4                |
| network, grouped   | OM, P, N, Clay, EC | **4 of 4**            |
| PCA, ungrouped     | pH, Silt           | 2 of 4                |
| PCA, grouped       | SOC, P, Sand, EC   | **4 of 4**            |

Ungrouped, both routes leave **entire functions with no representative**
– nutrient cycling and physical structure vanish from the network
selection, and the base-status indicators `pH`, `Ca`, `Mg` and `EC` are
dropped wholesale because their module is peripheral to the network.
Grouping is the fix, and it is why fidelity improves with grouping
detail in Yuan's measurements.

See
[`soil_function_groups`](https://ccarbajal16.github.io/soilquality/reference/soil_function_groups.md)
for why the grouping should be functional rather than the familiar
physical/chemical split.

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

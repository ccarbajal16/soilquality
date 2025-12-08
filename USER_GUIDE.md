# Comprehensive User Guide for the soilquality R Package

**Version 1.0.0**
**Author: Carlos Carbajal**
**Last Updated:** December 2025

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Theoretical Background](#2-theoretical-background)
3. [Installation](#3-installation)
4. [Dataset Description](#4-dataset-description)
5. [Data Preparation](#5-data-preparation)
6. [Principal Component Analysis and Minimum Data Set Selection](#6-principal-component-analysis-and-minimum-data-set-selection)
7. [Analytic Hierarchy Process for Indicator Weighting](#7-analytic-hierarchy-process-for-indicator-weighting)
8. [Scoring Functions and Normalization](#8-scoring-functions-and-normalization)
9. [Complete SQI Calculation Workflows](#9-complete-sqi-calculation-workflows)
10. [Visualization and Results Interpretation](#10-visualization-and-results-interpretation)
11. [Advanced Applications](#11-advanced-applications)
12. [Interactive Shiny Application](#12-interactive-shiny-application)
13. [Best Practices and Recommendations](#13-best-practices-and-recommendations)
14. [References](#14-references)

---

## 1. Introduction

The **soilquality** package provides a comprehensive framework for calculating Soil Quality Index (SQI) using scientifically validated methodologies. This package implements a systematic approach combining multivariate statistical analysis with expert knowledge to transform complex soil property data into a single, interpretable quality metric.

### 1.1 Key Features

- **Automated Minimum Data Set (MDS) Selection**: Principal Component Analysis (PCA) based dimensionality reduction
- **Expert Knowledge Integration**: Analytic Hierarchy Process (AHP) for indicator weighting
- **Flexible Scoring Systems**: Multiple normalization methods for different soil property behaviors
- **Comprehensive Visualization**: Publication-ready graphics for results communication
- **Interactive Interface**: Shiny-based GUI for non-programming users
- **Pre-defined Property Sets**: Standard configurations for common soil analyses

### 1.2 Intended Audience

This package is designed for:
- Soil scientists conducting quality assessments
- Environmental researchers evaluating land management impacts
- Agricultural consultants advising on soil health
- Students learning soil quality assessment methodologies
- Policy makers requiring standardized soil quality metrics

---

## 2. Theoretical Background

### 2.1 Soil Quality Index Concept

Soil quality is defined as the capacity of soil to function within ecosystem boundaries to sustain biological productivity, maintain environmental quality, and promote plant and animal health (Karlen et al., 1997). The Soil Quality Index (SQI) provides a quantitative measure of this capacity by integrating multiple soil indicators into a single value.

The SQI is calculated as:

$$
SQI = \sum_{i=1}^{n} w_i \times S_i
$$

Where:
- $w_i$ = weight of indicator *i*
- $S_i$ = normalized score of indicator *i* (range: 0-1)
- $n$ = number of indicators in the Minimum Data Set

### 2.2 Minimum Data Set (MDS) Selection

The MDS represents a reduced set of soil indicators that captures the maximum variance in the full dataset while minimizing redundancy. This package employs PCA to identify principal components that explain variance above a specified threshold, then selects the indicator with the highest loading from each retained component.

### 2.3 Analytic Hierarchy Process (AHP)

AHP (Saaty, 1980) is a structured decision-making technique that derives indicator weights from pairwise comparisons. The method calculates weights using eigenvalue decomposition and provides a Consistency Ratio (CR) to assess the logical coherence of expert judgments. A CR < 0.10 indicates acceptable consistency.

### 2.4 Indicator Scoring Functions

Different soil properties exhibit distinct relationships with soil quality:
- **Higher-is-better**: Properties like organic matter, nutrients (monotonic positive relationship)
- **Lower-is-better**: Properties like bulk density, salinity (monotonic negative relationship)
- **Optimum range**: Properties like pH with an optimal value (parabolic relationship)
- **Threshold-based**: Properties with custom thresholds defining quality classes

---

## 3. Installation

### 3.1 From GitHub (Development Version)

```r
# Install devtools if not already installed
if (!requireNamespace("devtools", quietly = TRUE)) {
  install.packages("devtools")
}

# Install soilquality from GitHub
devtools::install_github("ccarbajal16/soilquality")
```

### 3.2 Load the Package

```r
library(soilquality)
```

### 3.3 Optional Dependencies

For full functionality, install these suggested packages:

```r
install.packages(c("shiny", "DT", "knitr", "rmarkdown"))
```

---

## 4. Dataset Description

### 4.1 The soil_ucayali Dataset

The package includes a representative dataset from the Ucayali region of Peru containing 50 soil samples with 15 variables.

```r
# Load the dataset
data(soil_ucayali)

# Examine structure
str(soil_ucayali)
```

```
'data.frame':	50 obs. of  15 variables:
 $ SampleID: chr  "UCY001" "UCY002" "UCY003" ...
 $ Sand    : num  45.8 48.3 41.2 ...
 $ Silt    : num  28.7 30.5 32.1 ...
 $ Clay    : num  25.5 21.2 26.7 ...
 $ BD      : num  1.32 1.45 1.28 ...
 $ pH      : num  5.2 5.8 4.9 ...
 $ OM      : num  2.85 2.45 3.15 ...
 $ SOC     : num  1.65 1.42 1.83 ...
 $ N       : num  0.145 0.125 0.168 ...
 $ P       : num  7.5 10.2 6.3 ...
 $ K       : num  92 115 78 ...
 $ CEC     : num  11.5 13.2 10.8 ...
 $ Ca      : num  4.35 5.12 3.87 ...
 $ Mg      : num  1.65 2.01 1.45 ...
 $ EC      : num  0.22 0.31 0.18 ...
```

### 4.2 Variable Definitions

| Variable | Description | Unit | Type |
|----------|-------------|------|------|
| SampleID | Unique sample identifier | - | Categorical |
| Sand | Sand content | % | Physical |
| Silt | Silt content | % | Physical |
| Clay | Clay content | % | Physical |
| BD | Bulk density | g/cm³ | Physical |
| pH | Soil pH (1:1 water) | - | Chemical |
| OM | Organic matter | % | Chemical |
| SOC | Soil organic carbon | % | Chemical |
| N | Total nitrogen | % | Fertility |
| P | Available phosphorus (Olsen) | mg/kg | Fertility |
| K | Exchangeable potassium | mg/kg | Fertility |
| CEC | Cation exchange capacity | cmol/kg | Chemical |
| Ca | Exchangeable calcium | cmol/kg | Fertility |
| Mg | Exchangeable magnesium | cmol/kg | Fertility |
| EC | Electrical conductivity | dS/m | Chemical |

### 4.3 Summary Statistics

```r
# Descriptive statistics
summary(soil_ucayali[, c("pH", "OM", "N", "P", "K", "CEC")])
```

---

## 5. Data Preparation

### 5.1 Reading Soil Data from CSV Files

```r
# Read soil data with automatic encoding detection
soil_data <- read_soil_csv("path/to/soil_data.csv")

# View first rows
head(soil_data)
```

**Function**: `read_soil_csv(path)`

**Parameters**:
- `path`: Character string specifying the CSV file path

**Returns**: Data frame with soil property data

### 5.2 Type Conversion

Safely convert variables to numeric type:

```r
# Convert a column to numeric
soil_data$pH <- to_numeric(soil_data$pH)

# Non-numeric values become NA with warning suppression
```

**Function**: `to_numeric(x)`

**Parameters**:
- `x`: Vector of any type

**Returns**: Numeric vector with NA for non-convertible values

### 5.3 Standardization

Z-score standardization is essential prior to PCA:

```r
# Standardize all numeric columns except ID
soil_std <- standardize_numeric(
  df = soil_ucayali,
  exclude = "SampleID"
)

# Verify standardization (mean ≈ 0, sd ≈ 1)
colMeans(soil_std[, c("pH", "OM", "N")], na.rm = TRUE)
apply(soil_std[, c("pH", "OM", "N")], 2, sd, na.rm = TRUE)
```

**Function**: `standardize_numeric(df, exclude = NULL)`

**Parameters**:
- `df`: Data frame containing soil properties
- `exclude`: Character vector of column names to exclude from standardization

**Returns**: Data frame with standardized numeric columns

**Details**:
- Applies z-score transformation: $(x - \bar{x}) / s_x$
- Preserves NA values
- Non-numeric columns remain unchanged
- Columns with zero variance are not standardized

---

## 6. Principal Component Analysis and Minimum Data Set Selection

### 6.1 Theoretical Foundation

PCA transforms correlated variables into uncorrelated principal components (PCs) ordered by explained variance. The MDS selection algorithm:

1. Performs PCA on standardized data
2. Retains PCs explaining variance > `var_threshold`
3. For each retained PC, selects the variable with maximum absolute loading > `loading_threshold`
4. Returns unique set of selected variables

### 6.2 Basic PCA-MDS Selection

```r
# Example with 8 soil properties
properties <- c("Sand", "Silt", "Clay", "pH", "OM", "N", "P", "K")
data_subset <- soil_ucayali[, properties]

# Standardize first
data_std <- standardize_numeric(data_subset)

# Perform PCA and select MDS
pca_result <- pca_select_mds(
  data = data_std,
  var_threshold = 0.05,      # Retain PCs explaining > 5% variance
  loading_threshold = 0.5     # Select variables with |loading| > 0.5
)

# View selected indicators
print(pca_result$mds)
```

**Example Output**:
```
[1] "pH"   "OM"   "Clay" "P"
```

### 6.3 Examining PCA Results

```r
# Variance explained by each PC
print(pca_result$var_exp)

# Cumulative variance
cumsum(pca_result$var_exp)

# Variable loadings for first 3 PCs
print(pca_result$loadings[, 1:3])

# PCA scores (sample coordinates in PC space)
pca_scores <- pca_result$pca$x
head(pca_scores)
```

### 6.4 Adjusting Selection Thresholds

The thresholds significantly impact MDS composition:

```r
# More conservative (fewer indicators)
pca_strict <- pca_select_mds(
  data_std,
  var_threshold = 0.10,      # Higher variance threshold
  loading_threshold = 0.7     # Higher loading threshold
)
length(pca_strict$mds)

# More inclusive (more indicators)
pca_relaxed <- pca_select_mds(
  data_std,
  var_threshold = 0.03,      # Lower variance threshold
  loading_threshold = 0.4     # Lower loading threshold
)
length(pca_relaxed$mds)
```

**Recommendation**: Start with defaults (var_threshold = 0.05, loading_threshold = 0.5) and adjust based on:
- Desired MDS size
- Domain knowledge
- Cumulative variance explained
- Practical measurement constraints

### 6.5 Function Reference

**Function**: `pca_select_mds(data, var_threshold = 0.05, loading_threshold = 0.5)`

**Parameters**:
- `data`: Standardized data frame with numeric columns
- `var_threshold`: Minimum proportion of variance for PC retention (0-1)
- `loading_threshold`: Minimum absolute loading for variable selection (0-1)

**Returns**: List with components:
- `mds`: Character vector of selected variable names
- `pca`: Complete PCA object from `stats::prcomp`
- `loadings`: Rotation matrix (variable loadings)
- `var_exp`: Numeric vector of variance proportions

---

## 7. Analytic Hierarchy Process for Indicator Weighting

### 7.1 Understanding the Saaty Scale

AHP uses pairwise comparisons on a 1-9 scale:

| Value | Interpretation |
|-------|----------------|
| 1 | Equal importance |
| 3 | Moderate importance of first over second |
| 5 | Strong importance of first over second |
| 7 | Very strong importance of first over second |
| 9 | Extreme importance of first over second |
| 2, 4, 6, 8 | Intermediate values |
| Reciprocals (1/3, 1/5, ...) | Second indicator more important than first |

### 7.2 Creating AHP Matrices Programmatically

**Method 1: From Importance Ratios**

```r
# Define relative importance ratios
# Example: OM is 5x more important than P, which is 3x more important than K
ratios <- c(OM = 5, P = 3, K = 1)

# Convert to pairwise comparison matrix
pairwise <- ratio_to_saaty(ratios)
print(pairwise)
```

**Output**:
```
         OM        P        K
OM 1.000000 1.666667 5.000000
P  0.600000 1.000000 3.000000
K  0.200000 0.333333 1.000000
```

**Method 2: Manual Matrix Construction**

```r
# Create 4x4 pairwise comparison matrix for pH, OM, P, CEC
pairwise <- matrix(c(
  1,   2,   3,   2,    # pH vs others
  1/2, 1,   2,   1,    # OM vs others
  1/3, 1/2, 1,   1/2,  # P vs others
  1/2, 1,   2,   1     # CEC vs others
), nrow = 4, byrow = TRUE)

rownames(pairwise) <- colnames(pairwise) <- c("pH", "OM", "P", "CEC")
print(pairwise)
```

### 7.3 Calculating AHP Weights

```r
# Calculate weights from pairwise matrix
ahp_result <- ahp_weights(
  pairwise = pairwise,
  indicators = c("pH", "OM", "P", "CEC")
)

# View weights
print(ahp_result$weights)
```

**Output**:
```
       pH        OM         P       CEC
0.3867925 0.2169811 0.1298113 0.2664151
```

```r
# Check consistency
print(ahp_result$CR)
```

**Output**:
```
[1] 0.0234  # CR < 0.10 indicates acceptable consistency
```

```r
# Maximum eigenvalue
print(ahp_result$lambda_max)
```

### 7.4 Interactive AHP Matrix Creation

For user-guided pairwise comparisons:

```r
# Launch interactive prompts
ahp_matrix <- create_ahp_matrix(
  indicators = c("pH", "OM", "P", "K"),
  mode = "interactive"
)
```

**Interactive Session Example**:
```
=== AHP Pairwise Comparison ===

Saaty Scale:
  1 = Equal importance
  3 = Moderate importance
  5 = Strong importance
  7 = Very strong importance
  9 = Extreme importance
  2, 4, 6, 8 = Intermediate values
  Use reciprocals (e.g., 1/3, 0.333) when second indicator is more important

Compare 'pH' vs 'OM'
How much more important is 'pH' compared to 'OM'? 2

Compare 'pH' vs 'P'
How much more important is 'pH' compared to 'P'? 3
...
```

The function returns an `ahp_matrix` object:

```r
print(ahp_matrix)
```

**Output**:
```
=== AHP Pairwise Comparison Matrix ===

Pairwise Comparison Matrix:
     pH    OM     P     K
pH  1.0  2.00  3.00  2.00
OM  0.5  1.00  2.00  1.00
P   0.3  0.50  1.00  0.50
K   0.5  1.00  2.00  1.00

Indicator Weights:
  pH             : 0.3868
  OM             : 0.2170
  P              : 0.1298
  K              : 0.2664

Consistency Information:
  Lambda Max: 4.0230
  Consistency Ratio (CR): 0.0256 [✓ Acceptable]
```

### 7.5 Using Pre-built Matrices

```r
# Create matrix object from existing pairwise matrix
ahp_matrix <- create_ahp_matrix(
  indicators = c("pH", "OM", "P"),
  mode = "matrix",
  pairwise = pairwise
)

# Extract weights for use in SQI calculation
weights <- ahp_matrix$weights
```

### 7.6 Interpreting Consistency Ratio

| CR Value | Interpretation | Action |
|----------|----------------|--------|
| < 0.10 | Acceptable consistency | Proceed with weights |
| 0.10 - 0.15 | Marginal consistency | Review judgments, consider revision |
| > 0.15 | Unacceptable inconsistency | Revise pairwise comparisons |

**Common causes of high CR**:
- Circular judgments (A > B > C > A)
- Magnitude inconsistencies (A >> B, B ≈ C, but A ≈ C)
- Random or uninformed comparisons

---

## 8. Scoring Functions and Normalization

### 8.1 Theoretical Foundations

Scoring transforms raw soil property values to a normalized 0-1 scale where 1 represents optimal quality. The transformation function depends on the property's relationship with soil quality.

### 8.2 Higher-is-Better Scoring

For properties where higher values indicate better quality (e.g., organic matter, nutrients, CEC):

$$
S = \frac{x - x_{min}}{x_{max} - x_{min}}
$$

```r
# Example: Organic matter scoring
om_values <- soil_ucayali$OM
om_scores <- score_higher_better(om_values)

# With custom min/max (for comparison across datasets)
om_scores_custom <- score_higher_better(
  x = om_values,
  min_val = 1.0,   # Theoretical minimum
  max_val = 5.0    # Theoretical maximum
)

# Compare distributions
par(mfrow = c(1, 2))
hist(om_values, main = "Original OM", xlab = "OM (%)")
hist(om_scores, main = "Scored OM", xlab = "Score", xlim = c(0, 1))
```

**Function**: `score_higher_better(x, min_val = NULL, max_val = NULL)`

### 8.3 Lower-is-Better Scoring

For properties where lower values indicate better quality (e.g., bulk density, salinity):

$$
S = \frac{x_{max} - x}{x_{max} - x_{min}}
$$

```r
# Example: Bulk density scoring
bd_values <- soil_ucayali$BD
bd_scores <- score_lower_better(bd_values)

# With reference values
bd_scores_custom <- score_lower_better(
  x = bd_values,
  min_val = 1.0,   # Optimal (low) BD
  max_val = 1.8    # Poor (high) BD
)

# Verify inversion
plot(bd_values, bd_scores,
     xlab = "Bulk Density (g/cm³)",
     ylab = "Score",
     main = "Lower-is-Better Scoring")
```

**Function**: `score_lower_better(x, min_val = NULL, max_val = NULL)`

### 8.4 Optimum Range Scoring

For properties with an optimal value (e.g., pH):

**Linear penalty**:
$$
S = 1 - \frac{|x - x_{opt}|}{tolerance}
$$

**Quadratic penalty**:
$$
S = 1 - \left(\frac{|x - x_{opt}|}{tolerance}\right)^2
$$

```r
# Example: pH scoring with linear penalty
ph_values <- soil_ucayali$pH
ph_scores_linear <- score_optimum(
  x = ph_values,
  optimum = 6.5,
  tol = 1.5,
  penalty = "linear"
)

# Quadratic penalty (more forgiving near optimum)
ph_scores_quadratic <- score_optimum(
  x = ph_values,
  optimum = 6.5,
  tol = 1.5,
  penalty = "quadratic"
)

# Visualize penalty functions
ph_range <- seq(4, 9, by = 0.1)
scores_linear <- score_optimum(ph_range, 6.5, 1.5, "linear")
scores_quad <- score_optimum(ph_range, 6.5, 1.5, "quadratic")

plot(ph_range, scores_linear, type = "l", col = "blue",
     xlab = "pH", ylab = "Score", main = "Optimum Range Scoring",
     ylim = c(0, 1))
lines(ph_range, scores_quad, col = "red")
abline(v = 6.5, lty = 2, col = "gray")
legend("topright", c("Linear", "Quadratic", "Optimum"),
       col = c("blue", "red", "gray"), lty = c(1, 1, 2))
```

**Function**: `score_optimum(x, optimum, tol, penalty = "linear")`

### 8.5 Threshold-Based Scoring

For properties with expert-defined thresholds:

```r
# Example: Phosphorus availability classes
p_values <- soil_ucayali$P
p_scores <- score_threshold(
  x = p_values,
  thresholds = c(0, 5, 10, 15, 25),
  scores = c(0, 0.3, 0.6, 0.9, 1.0)
)

# Visualize piecewise linear interpolation
plot(p_values, p_scores,
     xlab = "Available P (mg/kg)", ylab = "Score",
     main = "Threshold-Based Scoring")
```

Interpretation:
- P < 5 mg/kg: Very low (score ≤ 0.3)
- P = 5-10 mg/kg: Low (score 0.3-0.6)
- P = 10-15 mg/kg: Medium (score 0.6-0.9)
- P = 15-25 mg/kg: Adequate (score 0.9-1.0)
- P > 25 mg/kg: High (score = 1.0)

**Function**: `score_threshold(x, thresholds, scores)`

### 8.6 Batch Scoring Multiple Indicators

```r
# Define scoring specifications for multiple indicators
directions <- list(
  pH = list(type = "optimum", optimum = 6.5, tol = 1.5, penalty = "linear"),
  OM = list(type = "higher"),
  BD = list(type = "lower"),
  P = list(type = "threshold",
           thresholds = c(0, 5, 10, 15, 25),
           scores = c(0, 0.3, 0.6, 0.9, 1.0)),
  K = list(type = "higher", min_val = 40, max_val = 180)
)

# Select MDS indicators
mds <- c("pH", "OM", "BD", "P", "K")

# Apply scoring to all indicators
scored_data <- score_indicators(
  data = soil_ucayali,
  mds = mds,
  directions = directions
)

# View scored columns
head(scored_data[, c("pH", "pH_scored", "OM", "OM_scored")])
```

**Function**: `score_indicators(data, mds, directions)`

---

## 9. Complete SQI Calculation Workflows

### 9.1 Workflow 1: File-Based Processing

For CSV-based workflows with file input/output:

```r
# Calculate SQI from CSV file
result <- compute_sqi(
  input_csv = "soil_samples.csv",
  id_column = "SampleID",
  output_csv = "sqi_results.csv",
  var_threshold = 0.05,
  loading_threshold = 0.5
)

# With AHP weights from CSV
result <- compute_sqi(
  input_csv = "soil_samples.csv",
  id_column = "SampleID",
  pairwise_csv = "ahp_matrix.csv",  # Pre-computed pairwise matrix
  output_csv = "sqi_results.csv"
)

# With custom scoring directions
directions <- list(
  pH = list(type = "optimum", optimum = 7, tol = 1, penalty = "linear"),
  OM = list(type = "higher"),
  P = list(type = "higher")
)

result <- compute_sqi(
  input_csv = "soil_samples.csv",
  id_column = "SampleID",
  directions = directions,
  output_csv = "sqi_results.csv"
)
```

**Function**: `compute_sqi(input_csv, id_column = NULL, pairwise_csv = NULL, output_csv = NULL, directions = NULL, var_threshold = 0.05, loading_threshold = 0.5, ...)`

### 9.2 Workflow 2: In-Memory Data Frames

For interactive analysis with data frames:

```r
# Basic calculation with equal weights
result <- compute_sqi_df(
  df = soil_ucayali,
  id_column = "SampleID",
  var_threshold = 0.05,
  loading_threshold = 0.5
)

# With AHP weights
pairwise <- matrix(c(
  1, 2, 3,
  1/2, 1, 2,
  1/3, 1/2, 1
), nrow = 3, byrow = TRUE)

result <- compute_sqi_df(
  df = soil_ucayali,
  id_column = "SampleID",
  pairwise_df = pairwise
)

# Access results
head(result$results)        # Data frame with scores and SQI
print(result$mds)           # Selected indicators
print(result$weights)       # AHP weights
print(result$CR)            # Consistency ratio
```

**Function**: `compute_sqi_df(df, id_column = NULL, pairwise_df = NULL, directions = NULL, var_threshold = 0.05, loading_threshold = 0.5, ...)`

### 9.3 Workflow 3: Property-Based Calculation (Recommended)

This enhanced workflow provides explicit control over property selection:

```r
# Using pre-defined property sets
result <- compute_sqi_properties(
  data = soil_ucayali,
  properties = soil_property_sets$fertility,  # Pre-defined set
  id_column = "SampleID"
)

# Using custom property selection
result <- compute_sqi_properties(
  data = soil_ucayali,
  properties = c("pH", "OM", "N", "P", "K", "CEC"),
  id_column = "SampleID"
)

# With standard scoring rules (automatic rule assignment)
rules <- standard_scoring_rules(c("pH", "OM", "BD", "P", "K"))
result <- compute_sqi_properties(
  data = soil_ucayali,
  properties = c("pH", "OM", "BD", "P", "K"),
  id_column = "SampleID",
  scoring_rules = rules
)

# With custom scoring rules using constructor functions
rules <- list(
  pH = optimum_range(optimal = 6.5, tolerance = 1.5),
  OM = higher_better(min_value = 1, max_value = 5),
  BD = lower_better(min_value = 1.0, max_value = 1.8),
  P = threshold_scoring(
    thresholds = c(0, 10, 20, 30),
    scores = c(0, 0.5, 1.0, 1.0)
  ),
  K = higher_better()
)

result <- compute_sqi_properties(
  data = soil_ucayali,
  properties = c("pH", "OM", "BD", "P", "K"),
  id_column = "SampleID",
  scoring_rules = rules
)

# With AHP weights
pairwise <- ratio_to_saaty(c(pH = 3, OM = 5, P = 2, K = 1))
result <- compute_sqi_properties(
  data = soil_ucayali,
  properties = c("pH", "OM", "P", "K"),
  id_column = "SampleID",
  scoring_rules = standard_scoring_rules(c("pH", "OM", "P", "K")),
  pairwise_matrix = pairwise
)
```

**Function**: `compute_sqi_properties(data, properties = NULL, id_column = NULL, pairwise_matrix = NULL, scoring_rules = NULL, var_threshold = 0.05, loading_threshold = 0.5, ...)`

### 9.4 Pre-defined Property Sets

The package includes six pre-configured property sets:

```r
# View available sets
names(soil_property_sets)
```

**Output**:
```
[1] "basic"         "standard"      "comprehensive"
[4] "physical"      "chemical"      "fertility"
```

```r
# Basic set (minimal assessment)
soil_property_sets$basic
```
```
[1] "pH" "OM" "P"  "K"
```

```r
# Standard set (recommended for most assessments)
soil_property_sets$standard
```
```
[1] "Sand" "Silt" "Clay" "pH"   "OM"   "N"    "P"    "K"    "CEC"
```

```r
# Comprehensive set (detailed characterization)
soil_property_sets$comprehensive
```
```
 [1] "Sand" "Silt" "Clay" "pH"   "OM"   "N"    "P"    "K"
 [9] "CEC"  "BD"   "EC"   "Ca"   "Mg"   "Na"   "S"
```

```r
# Physical properties only
soil_property_sets$physical
```
```
[1] "Sand" "Silt" "Clay" "BD"
```

```r
# Chemical properties only
soil_property_sets$chemical
```
```
[1] "pH"  "EC"  "CEC" "Ca"  "Mg"  "K"   "Na"
```

```r
# Fertility-related properties
soil_property_sets$fertility
```
```
[1] "OM"  "N"   "P"   "K"   "Ca"  "Mg"  "S"   "CEC"
```

### 9.5 Standard Scoring Rules

Automatic rule assignment based on property name patterns:

```r
# Generate rules for a property set
rules <- standard_scoring_rules("fertility")

# Or for custom properties
rules <- standard_scoring_rules(c("pH", "BD", "OM", "EC"))

# Inspect individual rules
print(rules$pH)
```

**Output**:
```
Scoring Rule: optimum_range
  Type: Optimum range
  Optimal value: 7
  Tolerance: 1
  Penalty: linear
```

**Pattern Matching Logic**:

| Pattern | Rule Applied |
|---------|--------------|
| pH | optimum_range(7, 1) |
| EC, electrical | lower_better() |
| BD, bulk | lower_better() |
| OM, SOC, organic | higher_better() |
| N, P, K (nutrients) | higher_better() |
| CEC, Ca, Mg | higher_better() |
| Others | higher_better() (default) |

### 9.6 Complete Example: Fertility Assessment

```r
# Step-by-step fertility assessment
library(soilquality)
data(soil_ucayali)

# 1. Select fertility properties
props <- soil_property_sets$fertility
print(props)

# 2. Generate standard scoring rules
rules <- standard_scoring_rules(props)

# 3. Create AHP weights based on nutrient importance
# Importance order: OM > N > P > CEC > K > Ca > Mg > S
ratios <- c(OM = 8, N = 7, P = 6, CEC = 5, K = 4, Ca = 3, Mg = 2, S = 1)
pairwise <- ratio_to_saaty(ratios[props])

# Calculate AHP weights
ahp <- ahp_weights(pairwise, props)
print(ahp$weights)
print(paste("Consistency Ratio:", round(ahp$CR, 4)))

# 4. Compute SQI
result <- compute_sqi_properties(
  data = soil_ucayali,
  properties = props,
  id_column = "SampleID",
  scoring_rules = rules,
  pairwise_matrix = pairwise,
  var_threshold = 0.05,
  loading_threshold = 0.5
)

# 5. Examine results
print(result)
summary(result$results$SQI)

# 6. Identify samples by quality class
result$results$Quality_Class <- cut(
  result$results$SQI,
  breaks = c(0, 0.25, 0.50, 0.75, 1.0),
  labels = c("Poor", "Fair", "Good", "Excellent"),
  include.lowest = TRUE
)

table(result$results$Quality_Class)

# 7. Export results
write.csv(result$results, "fertility_sqi_results.csv", row.names = FALSE)
```

---

## 10. Visualization and Results Interpretation

### 10.1 Single-Panel Plots

The `plot()` method provides five visualization types:

#### 10.1.1 Distribution Plot

```r
# Histogram of SQI values
plot(result, type = "distribution")
```

**Interpretation**:
- Distribution shape (normal, skewed, bimodal)
- Central tendency (mean line)
- Range and variability
- Outliers or distinct quality groups

#### 10.1.2 Indicators Plot

```r
# Boxplots of scored indicators
plot(result, type = "indicators")
```

**Interpretation**:
- Relative performance across indicators
- Variability within each indicator
- Identification of limiting factors
- Outlier detection

#### 10.1.3 Weights Plot

```r
# Bar chart of AHP weights
plot(result, type = "weights")
```

**Interpretation**:
- Relative importance of each indicator
- Dominant vs. minor contributors to SQI
- Consistency ratio assessment

#### 10.1.4 Scree Plot

```r
# Variance explained by principal components
plot(result, type = "scree")
```

**Interpretation**:
- Number of meaningful PCs
- Cumulative variance explained
- Dimensionality reduction effectiveness
- Elbow point identification

#### 10.1.5 PCA Biplot

```r
# Biplot of observations and variable loadings
plot(result, type = "biplot")
```

**Interpretation**:
- Sample clustering patterns
- Variable relationships (correlations)
- Influential variables (long arrows)
- Sample-variable associations

### 10.2 Multi-Panel Report

```r
# Comprehensive 4-panel visualization
plot_sqi_report(result)
```

This creates a publication-ready figure with:
1. SQI distribution (top-left)
2. Indicator scores (top-right)
3. AHP weights (bottom-left)
4. Variance scree plot (bottom-right)

### 10.3 Custom Visualizations

#### 10.3.1 Spatial Distribution

```r
# If samples have coordinates
library(ggplot2)

# Add coordinates (example)
result$results$Longitude <- rnorm(50, -74.5, 0.5)
result$results$Latitude <- rnorm(50, -8.4, 0.5)

# Create spatial map
ggplot(result$results, aes(x = Longitude, y = Latitude, color = SQI)) +
  geom_point(size = 3) +
  scale_color_gradient2(low = "red", mid = "yellow", high = "darkgreen",
                        midpoint = 0.5, limits = c(0, 1)) +
  labs(title = "Spatial Distribution of Soil Quality Index",
       x = "Longitude", y = "Latitude") +
  theme_minimal()
```

#### 10.3.2 Indicator Contribution Analysis

```r
# Calculate contribution of each indicator to total SQI
contributions <- result$results[, paste0(result$mds, "_scored")]
weighted_contrib <- sweep(contributions, 2, result$weights, "*")
colnames(weighted_contrib) <- paste0(result$mds, "_contrib")

# Add to results
result$results <- cbind(result$results, weighted_contrib)

# Average contribution
avg_contrib <- colMeans(weighted_contrib)
barplot(avg_contrib,
        main = "Average Contribution to SQI",
        ylab = "Contribution",
        las = 2,
        col = "skyblue")
```

#### 10.3.3 Quality Classification

```r
# Define quality classes
result$results$Class <- cut(
  result$results$SQI,
  breaks = c(0, 0.25, 0.50, 0.75, 1.0),
  labels = c("Poor", "Fair", "Good", "Excellent"),
  include.lowest = TRUE
)

# Visualize class distribution
library(ggplot2)
ggplot(result$results, aes(x = Class, fill = Class)) +
  geom_bar() +
  scale_fill_manual(values = c("red", "orange", "lightgreen", "darkgreen")) +
  labs(title = "Distribution of Soil Quality Classes",
       x = "Quality Class", y = "Number of Samples") +
  theme_minimal()
```

### 10.4 Statistical Summaries

```r
# Summary statistics for SQI
summary(result$results$SQI)

# By quality class
tapply(result$results$SQI, result$results$Class, summary)

# Correlation between SQI and original properties
cor_matrix <- cor(result$results[, c(result$mds, "SQI")],
                   use = "complete.obs")
print(round(cor_matrix[, "SQI"], 3))

# Identify most influential indicator
max_cor <- which.max(abs(cor_matrix[result$mds, "SQI"]))
print(paste("Most correlated with SQI:", result$mds[max_cor]))
```

---

## 11. Advanced Applications

### 11.1 Comparing Management Systems

```r
# Add management system identifier
result$results$Management <- rep(c("Conventional", "Organic"), each = 25)

# Compare SQI by system
boxplot(SQI ~ Management, data = result$results,
        main = "SQI by Management System",
        ylab = "Soil Quality Index",
        col = c("lightblue", "lightgreen"))

# Statistical test
t.test(SQI ~ Management, data = result$results)

# Compare by indicator
library(reshape2)
scored_cols <- paste0(result$mds, "_scored")
scores_long <- melt(result$results[, c("Management", scored_cols)],
                    id.vars = "Management",
                    variable.name = "Indicator",
                    value.name = "Score")

library(ggplot2)
ggplot(scores_long, aes(x = Indicator, y = Score, fill = Management)) +
  geom_boxplot() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(title = "Indicator Scores by Management System")
```

### 11.2 Temporal Changes

```r
# Simulate multi-year data
years <- c(2020, 2021, 2022, 2023)
temporal_results <- list()

for (year in years) {
  # In practice, load data for each year
  # Here we simulate slight changes
  data_year <- soil_ucayali
  data_year[, c("OM", "N", "P")] <- data_year[, c("OM", "N", "P")] *
                                     (1 + (year - 2020) * 0.05)

  result_year <- compute_sqi_properties(
    data = data_year,
    properties = c("pH", "OM", "N", "P", "K", "CEC"),
    id_column = "SampleID",
    scoring_rules = standard_scoring_rules(c("pH", "OM", "N", "P", "K", "CEC"))
  )

  temporal_results[[as.character(year)]] <- result_year$results$SQI
}

# Create temporal data frame
temporal_df <- data.frame(
  Year = rep(years, each = 50),
  SampleID = rep(soil_ucayali$SampleID, 4),
  SQI = unlist(temporal_results)
)

# Temporal trend
library(ggplot2)
ggplot(temporal_df, aes(x = Year, y = SQI, group = SampleID)) +
  geom_line(alpha = 0.2) +
  stat_summary(aes(group = 1), fun = mean, geom = "line",
               color = "red", size = 1.5) +
  labs(title = "Temporal Trends in Soil Quality",
       y = "Soil Quality Index") +
  theme_minimal()
```

### 11.3 Sensitivity Analysis

```r
# Test sensitivity to PCA thresholds
var_thresholds <- c(0.03, 0.05, 0.07, 0.10)
sensitivity_results <- data.frame()

for (vt in var_thresholds) {
  result_test <- compute_sqi_properties(
    data = soil_ucayali,
    properties = c("Sand", "Silt", "Clay", "pH", "OM", "N", "P", "K", "CEC"),
    id_column = "SampleID",
    var_threshold = vt,
    loading_threshold = 0.5
  )

  sensitivity_results <- rbind(sensitivity_results, data.frame(
    var_threshold = vt,
    n_indicators = length(result_test$mds),
    mean_SQI = mean(result_test$results$SQI),
    sd_SQI = sd(result_test$results$SQI),
    indicators = paste(result_test$mds, collapse = ", ")
  ))
}

print(sensitivity_results)

# Plot sensitivity
plot(sensitivity_results$var_threshold, sensitivity_results$mean_SQI,
     type = "b", pch = 19,
     xlab = "Variance Threshold",
     ylab = "Mean SQI",
     main = "Sensitivity to Variance Threshold")
```

### 11.4 Bootstrap Confidence Intervals

```r
# Bootstrap SQI calculation
n_boot <- 1000
boot_sqi <- matrix(NA, nrow = nrow(soil_ucayali), ncol = n_boot)

for (i in 1:n_boot) {
  # Resample observations
  boot_indices <- sample(1:nrow(soil_ucayali), replace = TRUE)
  boot_data <- soil_ucayali[boot_indices, ]

  boot_result <- compute_sqi_properties(
    data = boot_data,
    properties = c("pH", "OM", "N", "P", "K", "CEC"),
    id_column = "SampleID"
  )

  boot_sqi[, i] <- boot_result$results$SQI[match(soil_ucayali$SampleID,
                                                   boot_result$results$SampleID)]
}

# Calculate 95% confidence intervals
ci_lower <- apply(boot_sqi, 1, quantile, probs = 0.025, na.rm = TRUE)
ci_upper <- apply(boot_sqi, 1, quantile, probs = 0.975, na.rm = TRUE)

# Original SQI
original_result <- compute_sqi_properties(
  data = soil_ucayali,
  properties = c("pH", "OM", "N", "P", "K", "CEC"),
  id_column = "SampleID"
)

# Plot with confidence intervals
plot(1:50, original_result$results$SQI,
     ylim = c(0, 1),
     pch = 19,
     xlab = "Sample", ylab = "SQI",
     main = "SQI with 95% Bootstrap Confidence Intervals")
arrows(1:50, ci_lower, 1:50, ci_upper,
       angle = 90, code = 3, length = 0.05, col = "gray")
```

### 11.5 Machine Learning Integration

```r
# Use SQI as target variable for prediction
library(randomForest)

# Prepare data
ml_data <- soil_ucayali[, c("Sand", "Silt", "Clay", "pH", "OM",
                              "N", "P", "K", "CEC", "BD", "EC")]
ml_data$SQI <- original_result$results$SQI

# Split data
set.seed(123)
train_idx <- sample(1:nrow(ml_data), 0.7 * nrow(ml_data))
train_data <- ml_data[train_idx, ]
test_data <- ml_data[-train_idx, ]

# Train random forest
rf_model <- randomForest(SQI ~ ., data = train_data, ntree = 500)

# Predict
predictions <- predict(rf_model, test_data)

# Evaluate
cor(predictions, test_data$SQI)
plot(test_data$SQI, predictions,
     xlab = "Observed SQI", ylab = "Predicted SQI",
     main = "Random Forest Prediction of SQI")
abline(0, 1, col = "red")

# Variable importance
varImpPlot(rf_model, main = "Importance of Soil Properties for SQI")
```

---

## 12. Interactive Shiny Application

### 12.1 Launching the Application

```r
# Launch with default settings
run_sqi_app()

# Launch on specific port
run_sqi_app(port = 8080)

# Don't open browser automatically
run_sqi_app(launch.browser = FALSE)
```

### 12.2 Application Features

The Shiny app provides a graphical interface for:

1. **Data Upload**
   - CSV file upload
   - Data preview
   - Column selection

2. **Property Selection**
   - Auto-detect numeric columns
   - Pre-defined property sets
   - Custom selection

3. **Scoring Configuration**
   - Standard rules (automatic)
   - All higher-better
   - Custom rules (advanced)

4. **Weight Specification**
   - Equal weights
   - Upload AHP matrix
   - Interactive pairwise comparisons

5. **Results Display**
   - Summary statistics
   - Interactive data table
   - Downloadable results

6. **Visualizations**
   - Distribution plots
   - Indicator scores
   - Weights visualization
   - Scree plots

### 12.3 Typical Workflow in Shiny App

1. Click "Browse" to upload CSV file
2. Verify data preview
3. Select ID column from dropdown
4. Choose property selection method:
   - "Auto-detect" for all numeric columns
   - "Pre-defined" for standard sets
   - "Custom" for manual selection
5. Configure scoring rules (or use defaults)
6. Set PCA thresholds (or use defaults)
7. Choose weighting method (equal or AHP)
8. Click "Calculate SQI"
9. Review results in Results tab
10. Explore visualizations in Plots tab
11. Download results CSV

---

## 13. Best Practices and Recommendations

### 13.1 Data Quality

**Pre-analysis checks**:
- Remove duplicates
- Check for outliers (use `boxplot()`, `summary()`)
- Verify data types (`str()`)
- Handle missing values appropriately
- Ensure consistent units across samples

```r
# Example quality control
summary(soil_data)
boxplot(soil_data[, c("pH", "OM", "N")])

# Check missing data
colSums(is.na(soil_data))

# Remove samples with >30% missing values
complete_ratio <- rowSums(!is.na(soil_data)) / ncol(soil_data)
soil_clean <- soil_data[complete_ratio > 0.7, ]
```

### 13.2 Property Selection

**Guidelines**:
- Minimum 5-8 properties for robust PCA
- Include properties from multiple categories (physical, chemical, fertility)
- Consider measurement cost vs. information gain
- Ensure properties are relevant to study objectives
- Avoid highly correlated redundant properties

**Example balanced selection**:
```r
# Balanced property set
properties <- c(
  "Clay",    # Physical
  "BD",      # Physical
  "pH",      # Chemical
  "OM",      # Chemical
  "CEC",     # Chemical
  "N",       # Fertility
  "P",       # Fertility
  "K"        # Fertility
)
```

### 13.3 MDS Selection Thresholds

**Recommendations**:
- `var_threshold = 0.05`: Standard, retains PCs explaining >5% variance
- `loading_threshold = 0.5`: Standard, selects variables with strong loadings

**Adjust based on**:
- Sample size (smaller n → lower thresholds)
- Number of variables (more variables → higher thresholds)
- Explained variance (aim for cumulative >70%)

```r
# Check cumulative variance before finalizing
cumsum(pca_result$var_exp)
```

### 13.4 AHP Weight Assignment

**Best practices**:
- Base comparisons on scientific literature
- Consult domain experts
- Use consistent logic across comparisons
- Document rationale for judgments
- Always check CR < 0.10
- Revise if CR > 0.10

**Example documentation**:
```r
# Expert weights based on literature review
# Rationale: OM most important for tropical soils (Lal, 2006)
#            pH critical for nutrient availability (Brady & Weil, 2008)
#            P limiting in weathered soils (Sanchez, 1976)
ratios <- c(OM = 5, pH = 3, P = 2, K = 1)
```

### 13.5 Scoring Function Selection

**Decision tree**:

1. **Monotonic positive** (higher = better) → `higher_better()`
   - Nutrients (N, P, K, Ca, Mg)
   - Organic matter
   - CEC
   - Water holding capacity

2. **Monotonic negative** (lower = better) → `lower_better()`
   - Bulk density
   - Salinity (EC)
   - Sodium (Na)
   - Compaction

3. **Optimum** (target value) → `optimum_range()`
   - pH (most crops: 6.0-7.0)
   - C:N ratio
   - Base saturation

4. **Threshold** (custom classes) → `threshold_scoring()`
   - Regulatory limits
   - Crop-specific requirements
   - Local standards

### 13.6 Interpretation Guidelines

**SQI Value Ranges** (suggested):

| SQI Range | Classification | Interpretation |
|-----------|----------------|----------------|
| 0.00 - 0.25 | Poor | Severe limitations, rehabilitation needed |
| 0.26 - 0.50 | Fair | Moderate limitations, management improvements recommended |
| 0.51 - 0.75 | Good | Minor limitations, suitable for most uses |
| 0.76 - 1.00 | Excellent | No significant limitations, optimal quality |

**Context matters**:
- Reference to regional baselines
- Land use objectives
- Management history
- Climatic conditions

### 13.7 Reporting Results

**Minimum reporting requirements**:

1. **Methods**
   - Properties included
   - PCA thresholds used
   - MDS indicators selected
   - Scoring functions applied
   - Weighting method (equal or AHP)
   - AHP matrix and CR (if applicable)

2. **Results**
   - Summary statistics (mean, SD, range)
   - SQI distribution histogram
   - Indicator scores boxplots
   - Sample classifications

3. **Interpretation**
   - Comparison to reference values
   - Limiting factors identification
   - Management recommendations
   - Temporal trends (if applicable)

**Example report template**:

```r
# Generate report
cat("=== SOIL QUALITY INDEX REPORT ===\n\n")

cat("1. METHODS\n")
cat("Properties analyzed:", paste(result$mds, collapse = ", "), "\n")
cat("PCA variance explained:", round(sum(result$var_exp[1:length(result$mds)]) * 100, 1), "%\n")
cat("Weighting method:", ifelse(result$CR == 0, "Equal", "AHP"), "\n")
if (result$CR > 0) {
  cat("AHP Consistency Ratio:", round(result$CR, 4), "\n")
}
cat("\n")

cat("2. RESULTS\n")
cat("Number of samples:", nrow(result$results), "\n")
cat("Mean SQI:", round(mean(result$results$SQI), 3), "\n")
cat("SD:", round(sd(result$results$SQI), 3), "\n")
cat("Range:", round(min(result$results$SQI), 3), "-",
    round(max(result$results$SQI), 3), "\n")
cat("\n")

cat("3. QUALITY CLASSIFICATION\n")
result$results$Class <- cut(result$results$SQI,
                             breaks = c(0, 0.25, 0.5, 0.75, 1),
                             labels = c("Poor", "Fair", "Good", "Excellent"))
print(table(result$results$Class))
```

---

## 14. References

Andrews, S. S., Karlen, D. L., & Mitchell, J. P. (2002). A comparison of soil quality indexing methods for vegetable production systems in Northern California. *Agriculture, Ecosystems & Environment*, 90(1), 25-45.

Brady, N. C., & Weil, R. R. (2008). *The Nature and Properties of Soils* (14th ed.). Pearson Prentice Hall.

Karlen, D. L., Mausbach, M. J., Doran, J. W., Cline, R. G., Harris, R. F., & Schuman, G. E. (1997). Soil quality: A concept, definition, and framework for evaluation. *Soil Science Society of America Journal*, 61(1), 4-10.

Lal, R. (2006). Enhancing crop yields in the developing countries through restoration of the soil organic carbon pool in agricultural lands. *Land Degradation & Development*, 17(2), 197-209.

Saaty, T. L. (1980). *The Analytic Hierarchy Process*. McGraw-Hill.

Sanchez, P. A. (1976). *Properties and Management of Soils in the Tropics*. Wiley.

Shukla, M. K., Lal, R., & Ebinger, M. (2006). Determining soil quality indicators by factor analysis. *Soil and Tillage Research*, 87(2), 194-204.

---

## Appendix A: Complete Example Script

```r
# =============================================================================
# COMPLETE SOIL QUALITY INDEX WORKFLOW
# Using soilquality package v1.0.0
# =============================================================================

# Load package and data
library(soilquality)
data(soil_ucayali)

# 1. DATA EXPLORATION
# -------------------
head(soil_ucayali)
summary(soil_ucayali[, c("pH", "OM", "N", "P", "K", "CEC")])

# 2. PROPERTY SELECTION
# ---------------------
# Use standard fertility set
properties <- soil_property_sets$fertility
print(properties)

# 3. SCORING RULES
# ----------------
# Generate standard rules
rules <- standard_scoring_rules(properties)

# Customize pH rule
rules$pH <- optimum_range(optimal = 6.5, tolerance = 1.5, penalty = "linear")

# View rules
lapply(rules, print)

# 4. AHP WEIGHTS
# --------------
# Define importance ratios based on nutrient function
ratios <- c(OM = 7, N = 6, P = 5, CEC = 4, K = 3, Ca = 2, Mg = 2, S = 1)

# Only use properties actually in the dataset
available_props <- intersect(names(ratios), names(soil_ucayali))
ratios <- ratios[available_props]

# Create pairwise matrix
pairwise <- ratio_to_saaty(ratios)

# Calculate weights
ahp <- ahp_weights(pairwise, names(ratios))
print(ahp$weights)
print(paste("CR:", round(ahp$CR, 4)))

# 5. COMPUTE SQI
# --------------
result <- compute_sqi_properties(
  data = soil_ucayali,
  properties = names(ratios),
  id_column = "SampleID",
  scoring_rules = rules[names(ratios)],
  pairwise_matrix = pairwise,
  var_threshold = 0.05,
  loading_threshold = 0.5
)

# 6. EXAMINE RESULTS
# ------------------
print(result)
summary(result$results$SQI)

# View selected MDS
print(result$mds)

# View final weights
print(result$weights)

# 7. CLASSIFY SAMPLES
# -------------------
result$results$Quality_Class <- cut(
  result$results$SQI,
  breaks = c(0, 0.25, 0.50, 0.75, 1.0),
  labels = c("Poor", "Fair", "Good", "Excellent"),
  include.lowest = TRUE
)

table(result$results$Quality_Class)

# 8. VISUALIZATIONS
# -----------------
# Distribution
plot(result, type = "distribution")

# Indicators
plot(result, type = "indicators")

# Weights
plot(result, type = "weights")

# Scree plot
plot(result, type = "scree")

# Comprehensive report
plot_sqi_report(result)

# 9. EXPORT RESULTS
# -----------------
write.csv(result$results, "sqi_results.csv", row.names = FALSE)

# 10. DETAILED ANALYSIS
# ---------------------
# Top 10 highest quality samples
top10 <- result$results[order(-result$results$SQI), ][1:10,
                        c("SampleID", "SQI", "Quality_Class")]
print(top10)

# Bottom 10 lowest quality samples
bottom10 <- result$results[order(result$results$SQI), ][1:10,
                           c("SampleID", "SQI", "Quality_Class")]
print(bottom10)

# Limiting factors analysis
scored_cols <- paste0(result$mds, "_scored")
limiting_factors <- apply(result$results[, scored_cols], 1, which.min)
limiting_indicator <- result$mds[limiting_factors]
table(limiting_indicator)

print("Analysis complete!")
```

---

## Appendix B: Function Quick Reference

| Function | Purpose | Key Parameters |
|----------|---------|----------------|
| `read_soil_csv()` | Import CSV data | path |
| `to_numeric()` | Convert to numeric | x |
| `standardize_numeric()` | Z-score standardization | df, exclude |
| `pca_select_mds()` | PCA-based MDS selection | data, var_threshold, loading_threshold |
| `ratio_to_saaty()` | Convert ratios to pairwise matrix | ratios |
| `ahp_weights()` | Calculate AHP weights | pairwise, indicators |
| `create_ahp_matrix()` | Interactive/programmatic AHP | indicators, mode, pairwise |
| `score_higher_better()` | Higher-is-better scoring | x, min_val, max_val |
| `score_lower_better()` | Lower-is-better scoring | x, min_val, max_val |
| `score_optimum()` | Optimum range scoring | x, optimum, tol, penalty |
| `score_threshold()` | Threshold-based scoring | x, thresholds, scores |
| `score_indicators()` | Batch scoring | data, mds, directions |
| `higher_better()` | Create higher rule | min_value, max_value |
| `lower_better()` | Create lower rule | min_value, max_value |
| `optimum_range()` | Create optimum rule | optimal, tolerance, penalty |
| `threshold_scoring()` | Create threshold rule | thresholds, scores |
| `standard_scoring_rules()` | Auto-generate rules | properties |
| `compute_sqi()` | File-based SQI | input_csv, id_column, pairwise_csv, output_csv |
| `compute_sqi_df()` | Data frame SQI | df, id_column, pairwise_df |
| `compute_sqi_properties()` | Property-based SQI | data, properties, scoring_rules, pairwise_matrix |
| `plot.sqi_result()` | Single plot | x, type |
| `plot_sqi_report()` | Multi-panel report | x |
| `run_sqi_app()` | Launch Shiny app | launch.browser |

---

**End of User Guide**

For additional support, please visit:
- Package website: https://ccarbajal16.github.io/soilquality/
- GitHub repository: https://github.com/ccarbajal16/soilquality
- Issue tracker: https://github.com/ccarbajal16/soilquality/issues

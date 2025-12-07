# soilquality

## Overview

The `soilquality` R package provides comprehensive tools for calculating
Soil Quality Index (SQI) using scientifically validated methods. The
package implements Principal Component Analysis (PCA) for Minimum Data
Set (MDS) selection and Analytic Hierarchy Process (AHP) for
expert-based weighting, transforming complex soil property data into
standardized quality metrics.

## Key Features

- **Automated MDS Selection**: PCA-based dimensionality reduction to
  identify key soil indicators
- **Expert Weighting System**: AHP methodology with consistency ratio
  validation
- **Flexible Scoring Functions**: Multiple normalization methods for
  different soil properties
  - Higher-is-better (e.g., organic matter, nutrients)
  - Lower-is-better (e.g., bulk density, electrical conductivity)
  - Optimal range (e.g., pH)
  - Custom threshold-based scoring
- **Pre-defined Property Sets**: Standard collections for common soil
  analyses (basic, standard, comprehensive, physical, chemical,
  fertility)
- **Standard Scoring Rules**: Automatic rule assignment based on
  property patterns
- **Comprehensive Visualization**: Multiple plot types for results
  interpretation
- **Interactive Shiny Application**: GUI for non-programmers
- **Complete Documentation**: Vignettes, examples, and function
  references

## Installation

### From GitHub (Development Version)

``` r
# Install devtools if needed
if (!requireNamespace("devtools", quietly = TRUE)) {
  install.packages("devtools")
}

# Install soilquality
devtools::install_github("ccarbajal16/soilquality")
```

### From CRAN (Stable Release)

``` r
# Coming soon
install.packages("soilquality")
```

## Quick Start

### Basic Workflow

``` r
library(soilquality)

# Load example data
data(soil_ucayali)

# Compute SQI with automatic property detection
result <- compute_sqi_properties(
  data = soil_ucayali,
  properties = c("Sand", "Silt", "Clay", "pH", "OM", "P", "K")
)

# View results summary
print(result)

# Visualize SQI distribution
plot(result, type = "distribution")

# Create comprehensive report
plot_sqi_report(result)
```

### Using Pre-defined Property Sets

``` r
# Use standard property set
result <- compute_sqi_properties(
  data = soil_ucayali,
  properties = soil_property_sets$standard
)
```

### Custom Scoring Rules

``` r
# Define custom scoring for specific properties
custom_rules <- list(
  pH = optimum_range(optimal = 6.5, tolerance = 1),
  OM = higher_better(),
  BD = lower_better(),
  P = threshold_scoring(
    thresholds = c(0, 10, 20, 50),
    scores = c(0, 0.5, 0.8, 1.0)
  )
)

result <- compute_sqi_properties(
  data = soil_ucayali,
  properties = c("pH", "OM", "BD", "P"),
  scoring_rules = custom_rules
)
```

### Interactive AHP Matrix Creation

``` r
# Create AHP matrix interactively
indicators <- c("pH", "OM", "P", "K")
ahp_matrix <- create_ahp_matrix(indicators, mode = "interactive")

# Use computed AHP weights in SQI calculation
result <- compute_sqi_properties(
  data = soil_ucayali,
  properties = ahp_matrix$indicators,
  pairwise_matrix = ahp_matrix$weights
)
```

### Launch Interactive Application

``` r
# Start Shiny app for GUI-based analysis
run_sqi_app()
```

## Main Functions

### Data Handling

- [`read_soil_csv()`](https://ccarbajal16.github.io/soilquality/reference/read_soil_csv.md) -
  Import soil data from CSV files
- [`standardize_numeric()`](https://ccarbajal16.github.io/soilquality/reference/standardize_numeric.md) -
  Z-score standardization of numeric columns
- [`to_numeric()`](https://ccarbajal16.github.io/soilquality/reference/to_numeric.md) -
  Safe type conversion

### PCA and MDS Selection

- [`pca_select_mds()`](https://ccarbajal16.github.io/soilquality/reference/pca_select_mds.md) -
  PCA-based minimum data set selection

### AHP Weighting

- [`ahp_weights()`](https://ccarbajal16.github.io/soilquality/reference/ahp_weights.md) -
  Calculate weights from pairwise comparison matrix
- [`create_ahp_matrix()`](https://ccarbajal16.github.io/soilquality/reference/create_ahp_matrix.md) -
  Interactive or programmatic matrix creation
- [`ratio_to_saaty()`](https://ccarbajal16.github.io/soilquality/reference/ratio_to_saaty.md) -
  Convert importance ratios to Saaty scale

### Scoring Functions

- [`score_higher_better()`](https://ccarbajal16.github.io/soilquality/reference/score_higher_better.md) -
  Normalize properties where higher is better
- [`score_lower_better()`](https://ccarbajal16.github.io/soilquality/reference/score_lower_better.md) -
  Normalize properties where lower is better
- [`score_optimum()`](https://ccarbajal16.github.io/soilquality/reference/score_optimum.md) -
  Normalize properties with optimal range
- [`score_threshold()`](https://ccarbajal16.github.io/soilquality/reference/score_threshold.md) -
  Custom piecewise scoring
- [`score_indicators()`](https://ccarbajal16.github.io/soilquality/reference/score_indicators.md) -
  Apply scoring to multiple indicators

### Scoring Constructors

- [`higher_better()`](https://ccarbajal16.github.io/soilquality/reference/higher_better.md) -
  Constructor for higher-is-better rules
- [`lower_better()`](https://ccarbajal16.github.io/soilquality/reference/lower_better.md) -
  Constructor for lower-is-better rules
- [`optimum_range()`](https://ccarbajal16.github.io/soilquality/reference/optimum_range.md) -
  Constructor for optimal range rules
- [`threshold_scoring()`](https://ccarbajal16.github.io/soilquality/reference/threshold_scoring.md) -
  Constructor for threshold-based rules

### Property Sets and Standard Rules

- `soil_property_sets` - Pre-defined property collections
- [`standard_scoring_rules()`](https://ccarbajal16.github.io/soilquality/reference/standard_scoring_rules.md) -
  Automatic rule assignment

### SQI Computation

- [`compute_sqi()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi.md) -
  File-based workflow
- [`compute_sqi_df()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_df.md) -
  In-memory workflow
- [`compute_sqi_properties()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_properties.md) -
  Enhanced workflow with property selection

### Visualization

- [`plot.sqi_result()`](https://ccarbajal16.github.io/soilquality/reference/plot.sqi_result.md) -
  S3 plot method with multiple types
- [`plot_sqi_report()`](https://ccarbajal16.github.io/soilquality/reference/plot_sqi_report.md) -
  Multi-panel visualization report

### Interactive Tools

- [`run_sqi_app()`](https://ccarbajal16.github.io/soilquality/reference/run_sqi_app.md) -
  Launch Shiny application

## Documentation

Comprehensive documentation is available through:

- **Vignettes**:

  - [Introduction to
    soilquality](https://ccarbajal16.github.io/soilquality/vignettes/introduction.Rmd) -
    Basic workflow and concepts
  - [Advanced
    Usage](https://ccarbajal16.github.io/soilquality/vignettes/advanced-usage.Rmd) -
    Custom scoring and property selection
  - [AHP Matrices
    Guide](https://ccarbajal16.github.io/soilquality/vignettes/ahp-matrices.Rmd) -
    Creating and interpreting pairwise comparisons

- **Function Reference**: Access help for any function with
  `?function_name`

- **Package Website**: <https://ccarbajal16.github.io/soilquality>

## Citation

If you use this package in your research, please cite it as:

``` r
citation("soilquality")
```

Or use:

> Carbajal, Carlos (2025). soilquality: Soil Quality Index Calculation
> with PCA and AHP. R package version 1.0.0.
> <https://github.com/ccarbajal16/soilquality>

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request or
open an Issue for:

- Bug reports
- Feature requests
- Documentation improvements
- Code contributions

## Issues and Support

Please report issues at:
<https://github.com/ccarbajal16/soilquality/issues>

For questions and discussions, use the GitHub Discussions page.

## License

This package is licensed under the MIT License. See the
[LICENSE](https://ccarbajal16.github.io/soilquality/LICENSE) file for
details.

## Acknowledgments

This package implements methodologies from soil quality assessment
literature, including PCA-based MDS selection and AHP weighting
approaches widely used in soil science research.

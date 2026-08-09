# soilquality <img src="man/figures/logo.png" align="right" height="139" alt="" />

<!-- badges: start -->
[![R-CMD-check](https://img.shields.io/badge/R--CMD--check-passing-brightgreen.svg)](https://github.com/ccarbajal16/soilquality)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
<!-- badges: end -->

## Overview

`soilquality` builds Soil Quality Indices — and, unusually, helps you find out whether the one you built is any good.

A soil quality index has **no ground truth**. Nothing tells you whether yours is correct. Most packages stop at producing a number; this one carries the routes the literature actually uses at every step of the pipeline, and the diagnostics that reveal when an index is not discriminating, when a model is circular, or when a comparison was never fair to begin with.

## Key Features

**Selecting indicators**

- **PCA** minimum data set selection, with the published *within 10 % of the maximum loading* rule available alongside the narrower default
- **Correlation-network** selection by centrality rather than variance — ecological hubs instead of high-variance variables
- **Functional (EMDS) grouping**: select one indicator per soil *function*, so a dominant function cannot crowd the others out
- **PCA adequacy testing** — KMO and Bartlett's sphericity, which most published work skips

**Scoring**

- Linear (higher / lower / optimum / threshold), plus the **sigmoidal** curve that dominates the SQI literature
- **Reference-soil standardisation** — score against an undisturbed soil instead of your own sample extremes, the documented escape from index incomparability
- **Inherent-property adjustment** — stop scoring a soil down for being what its parent material made it

**Weighting and aggregation**

- **AHP** with consistency-ratio validation, PCA loadings, or network centrality
- **Area aggregation** — a weight-free route that sidesteps the pipeline's most contested step entirely

**Validation — the part most work skips**

- `sqi_validate()` leads with the **distribution across decision categories**, not a correlation
- `sqi_stability()` asks whether your conclusion survives a change of recipe
- `check_circularity()` refuses to let you regress an index on the indicators that built it

**Also**

- Three example datasets, each for a different job
- Interactive Shiny application for non-programmers
- Vignettes, a full function reference, and a package website

## The pipeline, and the choice at every step

An index is five decisions, and this package offers alternatives at each of
them — plus the step most work skips.

```
select  →  group  →  score  →  weight  →  aggregate  →  VALIDATE
```

| Step | Options | Default | When to change it |
|---|---|---|---|
| **Select** | `pca_select_mds()` (variance), `na_select_mds()` (network centrality), expert list | PCA | Network when ecological hubs matter more than variance, or when normality is doubtful |
| **Group** | `groups = NULL`, `soil_function_groups` | none | Whenever more than one soil function matters — ungrouped selection can leave whole functions unrepresented |
| **Score** | linear, sigmoid, optimum, threshold, reference-soil | linear | Sigmoid to reproduce most published work; reference-soil for comparability across studies |
| **Weight** | AHP, PCA loading, network centrality, equal | equal | AHP when you have defensible expert judgement |
| **Aggregate** | `method = "weighted"`, `method = "area"` | weighted | Area to sidestep weighting entirely |
| **Validate** | `sqi_validate()`, `sqi_stability()` | — | **Always** |

### Why validation is the point

A soil quality index has **no ground truth**. Nothing tells you whether yours
is correct. What you can establish is whether it *discriminates*, and whether
your conclusion survives building it a different way.

`sqi_validate()` leads with the distribution across decision categories, not
with a correlation. Maaz et al. (2023) found two indices correlating at
**r = 0.96** while one placed **94 %** of plots in the middle band and the
other **61 %**. An index that calls almost everything "medium" cannot inform a
decision, however well it correlates with anything else.

`sqi_stability()` runs the same samples through several recipes and reports
whether the ranking survives. A high rank correlation does not rescue a
changed extreme, if the extreme is what you act on.

### One warning worth repeating

**Do not build an index from predicted soil properties.** Chaudhry et al.
(2024) found that computing an SQI from spectrally predicted properties gave
R² = 0.23, while predicting the index *directly* from the same spectra gave
R² = 0.90 — with individually acceptable property models. If you only have
predictions, model the index itself.

See `vignette("building-and-validating-an-sqi")` for the pipeline end to end.

## Installation

### From GitHub (Development Version)

#### Using pak (Recommended)

```r
# Install pak if needed
if (!requireNamespace("pak", quietly = TRUE)) {
  install.packages("pak")
}

# Install soilquality
pak::pak("ccarbajal16/soilquality")
```

#### Using devtools

```r
# Install devtools if needed
if (!requireNamespace("devtools", quietly = TRUE)) {
  install.packages("devtools")
}

# Install soilquality
devtools::install_github("ccarbajal16/soilquality")
```

### From CRAN (Stable Release)

```r
# Coming soon
install.packages("soilquality")
```

## Quick Start

### Basic Workflow

```r
library(soilquality)

# Load example data
data(soil_data)

# Compute SQI with automatic property detection
result <- compute_sqi_properties(
  data = soil_data,
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

```r
# Use standard property set
result <- compute_sqi_properties(
  data = soil_data,
  properties = soil_property_sets$standard
)
```

### Custom Scoring Rules

```r
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
  data = soil_data,
  properties = c("pH", "OM", "BD", "P"),
  scoring_rules = custom_rules
)
```

### Interactive AHP Matrix Creation

```r
# Create AHP matrix interactively
indicators <- c("pH", "OM", "P", "K")
ahp_matrix <- create_ahp_matrix(indicators, mode = "interactive")

# Use computed AHP weights in SQI calculation
result <- compute_sqi_properties(
  data = soil_data,
  properties = ahp_matrix$indicators,
  pairwise_matrix = ahp_matrix$weights
)
```

### Validating What You Built

Producing an index is the easy half. This is the other one.

```r
props <- c("pH", "OM", "N", "P", "K", "CEC", "BD")
index <- compute_sqi_properties(soil_data, properties = props,
                                id_column = "SampleID")

sqi_validate(index)
```

On this dataset that call raises a warning, and it is not a bug — it is the
diagnostic working. The default recipe puts **100 % of samples in the middle
bands**, with "very low" and "very high" both empty. An index that declines to
call any sample clearly good or clearly bad cannot inform a decision.

Then ask whether the conclusion depends on how you built it:

```r
sigmoid <- compute_sqi_properties(
  soil_data, properties = props, id_column = "SampleID",
  scoring_rules = standard_scoring_rules(props, scoring = "sigmoid")
)

sqi_stability(linear = index, sigmoid = sigmoid)
```

Here the two recipes agree at ρ = 0.80 and keep the same best field — but the
**worst one changes**. If the field you were about to intervene on depends on
which scoring function you happened to pick, you do not have a result; you
have an artefact of the recipe. A high rank correlation does not rescue that.

And before modelling what drives the index, check that the question is not
circular:

```r
check_circularity(index, ~ Sand + Clay)          # outside the index: fine
try(check_circularity(index, ~ OM))              # a component: refused
```

### Launch Interactive Application

```r
# Start Shiny app for GUI-based analysis
run_sqi_app()
```

## Main Functions

### SQI Computation

- `compute_sqi()` - File-based workflow
- `compute_sqi_df()` - In-memory workflow, and the engine the others delegate to. Carries `method`, `select`, `inherent` and `network_args`
- `compute_sqi_properties()` - Property selection and constructor-based scoring

### Data Handling

- `read_soil_csv()` - Import soil data from CSV files
- `standardize_numeric()` - Z-score standardization of numeric columns
- `to_numeric()` - Safe type conversion

### Selecting a Minimum Data Set

- `pca_select_mds()` - Selection by variance. `within` gives the published relative-loading rule, `groups` selects within soil functions, `selector = "norm"` uses Yuan's norm value
- `na_select_mds()` - Selection by centrality in a Spearman correlation network *(needs the suggested `igraph`)*
- `mds_consensus()` - The intersection of both routes, as a robustness check
- `pca_adequacy()` - KMO and Bartlett's test of sphericity

### Functional Grouping

- `soil_function_groups` - The five soil functions, for grouped selection
- `assign_function_groups()` - Map property names onto those functions

### Scoring

- `score_higher_better()`, `score_lower_better()`, `score_optimum()`, `score_threshold()` - The linear family
- `score_sigmoid()` - The non-linear curve that dominates the SQI literature
- `standardize_to_reference()` - Score against an undisturbed reference soil
- `score_indicators()` - Apply scoring across a set of indicators

### Scoring Constructors

- `higher_better()`, `lower_better()`, `optimum_range()`, `threshold_scoring()`
- `sigmoid_scoring()` - Sigmoidal rule
- `reference_scoring()` - Reference-soil rule
- `standard_scoring_rules()` - Automatic assignment by property name, in `"linear"` or `"sigmoid"` flavour
- `soil_property_sets` - Pre-defined property collections

### Weighting and Aggregation

- `ahp_weights()` - Weights from a pairwise comparison matrix, with a consistency ratio
- `create_ahp_matrix()` - Interactive or programmatic matrix creation
- `ratio_to_saaty()` - Convert importance ratios to the Saaty scale
- `sqi_area()` - Weight-free aggregation as the area of a radar diagram

### Validation

- `sqi_validate()` - Distribution across decision categories, sensitivity, fidelity to a total-data-set index, and an optional external criterion
- `sqi_stability()` - Does the ranking survive a change of recipe?
- `check_circularity()` - Refuses a model that regresses an index on its own components

### Correcting for What Cannot Be Managed

- `adjust_inherent()` - Remove the variation attributable to parent material and land-use history
- `sensitivity_resistance()` - Which indicators degrade faster than soil carbon, and which resist

### Visualization

- `plot.sqi_result()` - S3 plot method with five types
- `plot_sqi_report()` - Multi-panel report
- `plot_sqi_validation()` - The distribution across decision categories

### Interactive Tools

- `run_sqi_app()` - Launch the Shiny application

> **Note:** the Shiny app currently exposes the 1.0.0 workflow. The routes added since — sigmoid and reference scoring, area aggregation, network and grouped selection, and the whole validation layer — are available from the console only.

## Example Data

Three datasets, because they do three different jobs:

| Dataset | Rows | For |
|---|---|---|
| `soil_data` | 50 | Scoring, weighting, aggregation. Properties drawn independently, so it carries almost no covariance |
| `soil_structured` | 120 | Anything reading the structure *between* indicators. Texture sums to 100, `SOC = OM/1.724`, CEC generated by clay and organic colloids |
| `soil_inherent` | 180 | Inherent-property adjustment and nested designs. Carries `soil_type`, `land_use_history`, `management` and `PlotID`, five samples per plot |

All three are simulated, and each generating script in `data-raw/` states every relationship it used.

## Documentation

Comprehensive documentation is available through:

- **Vignettes**:
  - [**Building and validating a Soil Quality Index**](vignettes/building-and-validating-an-sqi.Rmd) — the pipeline end to end, and the one to read first
  - [Introduction to soilquality](vignettes/introduction.Rmd) - Basic workflow and concepts
  - [Advanced Usage](vignettes/advanced-usage.Rmd) - Custom scoring and property selection
  - [AHP Matrices Guide](vignettes/ahp-matrices.Rmd) - Creating and interpreting pairwise comparisons

- **Function Reference**: Access help for any function with `?function_name`

- **Package Website**: [https://ccarbajal16.github.io/soilquality](https://ccarbajal16.github.io/soilquality)

## Citation

If you use this package in your research, please cite it as:

```r
citation("soilquality")
```

Or use:

> Carbajal, Carlos (2025). soilquality: Soil Quality Index Calculation with PCA and AHP.
> R package version 1.0.0. https://github.com/ccarbajal16/soilquality

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request or open an Issue for:

- Bug reports
- Feature requests
- Documentation improvements
- Code contributions

## Issues and Support

Please report issues at: https://github.com/ccarbajal16/soilquality/issues

For questions and discussions, use the GitHub Discussions page.

## License

This package is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

This package implements methodologies from soil quality assessment literature, including PCA-based MDS selection and AHP weighting approaches widely used in soil science research.

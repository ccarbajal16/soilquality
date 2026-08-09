# soilquality

## Overview

`soilquality` builds Soil Quality Indices — and, unusually, helps you
find out whether the one you built is any good.

A soil quality index has **no ground truth**. Nothing tells you whether
yours is correct. Most packages stop at producing a number; this one
carries the routes the literature actually uses at every step of the
pipeline, and the diagnostics that reveal when an index is not
discriminating, when a model is circular, or when a comparison was never
fair to begin with.

## Key Features

**Selecting indicators**

- **PCA** minimum data set selection, with the published *within 10 % of
  the maximum loading* rule available alongside the narrower default
- **Correlation-network** selection by centrality rather than variance —
  ecological hubs instead of high-variance variables
- **Functional (EMDS) grouping**: select one indicator per soil
  *function*, so a dominant function cannot crowd the others out
- **PCA adequacy testing** — KMO and Bartlett’s sphericity, which most
  published work skips

**Scoring**

- Linear (higher / lower / optimum / threshold), plus the **sigmoidal**
  curve that dominates the SQI literature
- **Reference-soil standardisation** — score against an undisturbed soil
  instead of your own sample extremes, the documented escape from index
  incomparability
- **Inherent-property adjustment** — stop scoring a soil down for being
  what its parent material made it

**Weighting and aggregation**

- **AHP** with consistency-ratio validation, PCA loadings, or network
  centrality
- **Area aggregation** — a weight-free route that sidesteps the
  pipeline’s most contested step entirely

**Validation — the part most work skips**

- [`sqi_validate()`](https://ccarbajal16.github.io/soilquality/reference/sqi_validate.md)
  leads with the **distribution across decision categories**, not a
  correlation
- [`sqi_stability()`](https://ccarbajal16.github.io/soilquality/reference/sqi_stability.md)
  asks whether your conclusion survives a change of recipe
- [`check_circularity()`](https://ccarbajal16.github.io/soilquality/reference/check_circularity.md)
  refuses to let you regress an index on the indicators that built it

**Also**

- Three example datasets, each for a different job
- Interactive Shiny application for non-programmers
- Vignettes, a full function reference, and a package website

## The pipeline, and the choice at every step

An index is five decisions, and this package offers alternatives at each
of them — plus the step most work skips.

    select  →  group  →  score  →  weight  →  aggregate  →  VALIDATE

| Step | Options | Default | When to change it |
|----|----|----|----|
| **Select** | [`pca_select_mds()`](https://ccarbajal16.github.io/soilquality/reference/pca_select_mds.md) (variance), [`na_select_mds()`](https://ccarbajal16.github.io/soilquality/reference/na_select_mds.md) (network centrality), expert list | PCA | Network when ecological hubs matter more than variance, or when normality is doubtful |
| **Group** | `groups = NULL`, `soil_function_groups` | none | Whenever more than one soil function matters — ungrouped selection can leave whole functions unrepresented |
| **Score** | linear, sigmoid, optimum, threshold, reference-soil | linear | Sigmoid to reproduce most published work; reference-soil for comparability across studies |
| **Weight** | AHP, PCA loading, network centrality, equal | equal | AHP when you have defensible expert judgement |
| **Aggregate** | `method = "weighted"`, `method = "area"` | weighted | Area to sidestep weighting entirely |
| **Validate** | [`sqi_validate()`](https://ccarbajal16.github.io/soilquality/reference/sqi_validate.md), [`sqi_stability()`](https://ccarbajal16.github.io/soilquality/reference/sqi_stability.md) | — | **Always** |

### Why validation is the point

A soil quality index has **no ground truth**. Nothing tells you whether
yours is correct. What you can establish is whether it *discriminates*,
and whether your conclusion survives building it a different way.

[`sqi_validate()`](https://ccarbajal16.github.io/soilquality/reference/sqi_validate.md)
leads with the distribution across decision categories, not with a
correlation. Maaz et al. (2023) found two indices correlating at **r =
0.96** while one placed **94 %** of plots in the middle band and the
other **61 %**. An index that calls almost everything “medium” cannot
inform a decision, however well it correlates with anything else.

[`sqi_stability()`](https://ccarbajal16.github.io/soilquality/reference/sqi_stability.md)
runs the same samples through several recipes and reports whether the
ranking survives. A high rank correlation does not rescue a changed
extreme, if the extreme is what you act on.

### One warning worth repeating

**Do not build an index from predicted soil properties.** Chaudhry et
al. (2024) found that computing an SQI from spectrally predicted
properties gave R² = 0.23, while predicting the index *directly* from
the same spectra gave R² = 0.90 — with individually acceptable property
models. If you only have predictions, model the index itself.

See
[`vignette("building-and-validating-an-sqi")`](https://ccarbajal16.github.io/soilquality/articles/building-and-validating-an-sqi.md)
for the pipeline end to end.

## Installation

`soilquality` is **not on CRAN**. Install it from GitHub:

### Using pak (Recommended)

``` r

# Install pak if needed
if (!requireNamespace("pak", quietly = TRUE)) {
  install.packages("pak")
}

# Install soilquality
pak::pak("ccarbajal16/soilquality")
```

### Using devtools

``` r

# Install devtools if needed
if (!requireNamespace("devtools", quietly = TRUE)) {
  install.packages("devtools")
}

# Install soilquality
devtools::install_github("ccarbajal16/soilquality")
```

### Optional dependency

Correlation-network selection
([`na_select_mds()`](https://ccarbajal16.github.io/soilquality/reference/na_select_mds.md),
[`mds_consensus()`](https://ccarbajal16.github.io/soilquality/reference/mds_consensus.md))
needs **igraph**, which is suggested rather than required — this package
is MIT-licensed and igraph is GPL, so it is kept out of `Imports`
deliberately. Everything else works without it.

``` r

install.packages("igraph")
```

## Quick Start

### Basic Workflow

``` r

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

``` r

# Use standard property set
result <- compute_sqi_properties(
  data = soil_data,
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
  data = soil_data,
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
  data = soil_data,
  properties = ahp_matrix$indicators,
  pairwise_matrix = ahp_matrix$weights
)
```

### Validating What You Built

Producing an index is the easy half. This is the other one.

``` r

props <- c("pH", "OM", "N", "P", "K", "CEC", "BD")
index <- compute_sqi_properties(soil_data, properties = props,
                                id_column = "SampleID")

sqi_validate(index)
```

On this dataset that call raises a warning, and it is not a bug — it is
the diagnostic working. The default recipe puts **100 % of samples in
the middle bands**, with “very low” and “very high” both empty. An index
that declines to call any sample clearly good or clearly bad cannot
inform a decision.

Then ask whether the conclusion depends on how you built it:

``` r

sigmoid <- compute_sqi_properties(
  soil_data, properties = props, id_column = "SampleID",
  scoring_rules = standard_scoring_rules(props, scoring = "sigmoid")
)

sqi_stability(linear = index, sigmoid = sigmoid)
```

Here the two recipes agree at ρ = 0.80 and keep the same best field —
but the **worst one changes**. If the field you were about to intervene
on depends on which scoring function you happened to pick, you do not
have a result; you have an artefact of the recipe. A high rank
correlation does not rescue that.

And before modelling what drives the index, check that the question is
not circular:

``` r

check_circularity(index, ~ Sand + Clay)          # outside the index: fine
try(check_circularity(index, ~ OM))              # a component: refused
```

### Launch Interactive Application

``` r

# Start Shiny app for GUI-based analysis
run_sqi_app()
```

## Main Functions

### SQI Computation

- [`compute_sqi()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi.md) -
  File-based workflow
- [`compute_sqi_df()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_df.md) -
  In-memory workflow, and the engine the others delegate to. Carries
  `method`, `select`, `inherent` and `network_args`
- [`compute_sqi_properties()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_properties.md) -
  Property selection and constructor-based scoring

### Data Handling

- [`read_soil_csv()`](https://ccarbajal16.github.io/soilquality/reference/read_soil_csv.md) -
  Import soil data from CSV files
- [`standardize_numeric()`](https://ccarbajal16.github.io/soilquality/reference/standardize_numeric.md) -
  Z-score standardization of numeric columns
- [`to_numeric()`](https://ccarbajal16.github.io/soilquality/reference/to_numeric.md) -
  Safe type conversion

### Selecting a Minimum Data Set

- [`pca_select_mds()`](https://ccarbajal16.github.io/soilquality/reference/pca_select_mds.md) -
  Selection by variance. `within` gives the published relative-loading
  rule, `groups` selects within soil functions, `selector = "norm"` uses
  Yuan’s norm value
- [`na_select_mds()`](https://ccarbajal16.github.io/soilquality/reference/na_select_mds.md) -
  Selection by centrality in a Spearman correlation network *(needs the
  suggested `igraph`)*
- [`mds_consensus()`](https://ccarbajal16.github.io/soilquality/reference/mds_consensus.md) -
  The intersection of both routes, as a robustness check
- [`pca_adequacy()`](https://ccarbajal16.github.io/soilquality/reference/pca_adequacy.md) -
  KMO and Bartlett’s test of sphericity

### Functional Grouping

- `soil_function_groups` - The five soil functions, for grouped
  selection
- [`assign_function_groups()`](https://ccarbajal16.github.io/soilquality/reference/assign_function_groups.md) -
  Map property names onto those functions

### Scoring

- [`score_higher_better()`](https://ccarbajal16.github.io/soilquality/reference/score_higher_better.md),
  [`score_lower_better()`](https://ccarbajal16.github.io/soilquality/reference/score_lower_better.md),
  [`score_optimum()`](https://ccarbajal16.github.io/soilquality/reference/score_optimum.md),
  [`score_threshold()`](https://ccarbajal16.github.io/soilquality/reference/score_threshold.md) -
  The linear family
- [`score_sigmoid()`](https://ccarbajal16.github.io/soilquality/reference/score_sigmoid.md) -
  The non-linear curve that dominates the SQI literature
- [`standardize_to_reference()`](https://ccarbajal16.github.io/soilquality/reference/standardize_to_reference.md) -
  Score against an undisturbed reference soil
- [`score_indicators()`](https://ccarbajal16.github.io/soilquality/reference/score_indicators.md) -
  Apply scoring across a set of indicators

### Scoring Constructors

- [`higher_better()`](https://ccarbajal16.github.io/soilquality/reference/higher_better.md),
  [`lower_better()`](https://ccarbajal16.github.io/soilquality/reference/lower_better.md),
  [`optimum_range()`](https://ccarbajal16.github.io/soilquality/reference/optimum_range.md),
  [`threshold_scoring()`](https://ccarbajal16.github.io/soilquality/reference/threshold_scoring.md)
- [`sigmoid_scoring()`](https://ccarbajal16.github.io/soilquality/reference/sigmoid_scoring.md) -
  Sigmoidal rule
- [`reference_scoring()`](https://ccarbajal16.github.io/soilquality/reference/reference_scoring.md) -
  Reference-soil rule
- [`standard_scoring_rules()`](https://ccarbajal16.github.io/soilquality/reference/standard_scoring_rules.md) -
  Automatic assignment by property name, in `"linear"` or `"sigmoid"`
  flavour
- `soil_property_sets` - Pre-defined property collections

### Weighting and Aggregation

- [`ahp_weights()`](https://ccarbajal16.github.io/soilquality/reference/ahp_weights.md) -
  Weights from a pairwise comparison matrix, with a consistency ratio
- [`create_ahp_matrix()`](https://ccarbajal16.github.io/soilquality/reference/create_ahp_matrix.md) -
  Interactive or programmatic matrix creation
- [`ratio_to_saaty()`](https://ccarbajal16.github.io/soilquality/reference/ratio_to_saaty.md) -
  Convert importance ratios to the Saaty scale
- [`sqi_area()`](https://ccarbajal16.github.io/soilquality/reference/sqi_area.md) -
  Weight-free aggregation as the area of a radar diagram

### Validation

- [`sqi_validate()`](https://ccarbajal16.github.io/soilquality/reference/sqi_validate.md) -
  Distribution across decision categories, sensitivity, fidelity to a
  total-data-set index, and an optional external criterion
- [`sqi_stability()`](https://ccarbajal16.github.io/soilquality/reference/sqi_stability.md) -
  Does the ranking survive a change of recipe?
- [`check_circularity()`](https://ccarbajal16.github.io/soilquality/reference/check_circularity.md) -
  Refuses a model that regresses an index on its own components

### Correcting for What Cannot Be Managed

- [`adjust_inherent()`](https://ccarbajal16.github.io/soilquality/reference/adjust_inherent.md) -
  Remove the variation attributable to parent material and land-use
  history
- [`sensitivity_resistance()`](https://ccarbajal16.github.io/soilquality/reference/sensitivity_resistance.md) -
  Which indicators degrade faster than soil carbon, and which resist

### Visualization

- [`plot.sqi_result()`](https://ccarbajal16.github.io/soilquality/reference/plot.sqi_result.md) -
  S3 plot method with five types
- [`plot_sqi_report()`](https://ccarbajal16.github.io/soilquality/reference/plot_sqi_report.md) -
  Multi-panel report
- [`plot_sqi_validation()`](https://ccarbajal16.github.io/soilquality/reference/plot_sqi_validation.md) -
  The distribution across decision categories

### Interactive Tools

- [`run_sqi_app()`](https://ccarbajal16.github.io/soilquality/reference/run_sqi_app.md) -
  Launch the Shiny application

> **Note:** the Shiny app currently exposes the 1.0.0 workflow. The
> routes added since — sigmoid and reference scoring, area aggregation,
> network and grouped selection, and the whole validation layer — are
> available from the console only.

## Example Data

Three datasets, because they do three different jobs:

| Dataset | Rows | For |
|----|----|----|
| `soil_data` | 50 | Scoring, weighting, aggregation. Properties drawn independently, so it carries almost no covariance |
| `soil_structured` | 120 | Anything reading the structure *between* indicators. Texture sums to 100, `SOC = OM/1.724`, CEC generated by clay and organic colloids |
| `soil_inherent` | 180 | Inherent-property adjustment and nested designs. Carries `soil_type`, `land_use_history`, `management` and `PlotID`, five samples per plot |

All three are simulated, and each generating script in `data-raw/`
states every relationship it used.

## Documentation

Comprehensive documentation is available through:

- **Vignettes**:

  - [**Building and validating a Soil Quality
    Index**](https://ccarbajal16.github.io/soilquality/vignettes/building-and-validating-an-sqi.Rmd)
    — the pipeline end to end, and the one to read first
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

> Carbajal, Carlos (2026). soilquality: Soil Quality Index Calculation
> with PCA and AHP. R package version 2.3.0.
> <https://github.com/ccarbajal16/soilquality>

`citation("soilquality")` reads the installed `DESCRIPTION`, so it is
the authoritative version; the block above will drift as releases go by.

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

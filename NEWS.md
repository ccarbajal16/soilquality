# soilquality 1.2.0 (development)

Adds index validation -- the ability to ask whether an index actually
discriminates, rather than assuming it does.

### New features

#### Validation
- `sqi_validate()` - assesses a computed index on four diagnostics, in
  descending order of how much they should influence a judgement: the
  distribution across the five soil-health decision categories, the
  sensitivity index (max/min), fidelity to a total-data-set index, and
  correlation against an optional external criterion such as yield.
- The distribution is the headline, and it warns. Maaz et al. (2023) found an
  additive index and an SEM index correlating at r = 0.96 while placing 94%
  vs 61% of plots in the middle bands: correlation is the wrong diagnostic
  for an index, the spread across decision categories is the right one. A
  warning fires above `middle_band_threshold` (default 0.8) because a silent
  number gets ignored.
- `sqi_stability()` - runs the same samples through two or more recipes and
  reports whether the ranking survives: Spearman rho per pair, plus a flag
  when the best or worst sample changes. A high rank correlation does not
  rescue a changed extreme if the extreme is what you act on.
- `plot_sqi_validation()` - the distribution plot, accepting an
  `sqi_validation`, an `sqi_result` or a bare numeric vector.
- `compute_sqi_df()` gains `select = c("pca", "none")`. With `"none"` the
  selection step is skipped and every numeric indicator is used, which is how
  the total-data-set index that `sqi_validate()` measures fidelity against is
  built. PCA is still run and reported either way.

### Note on the example data
Running `sqi_validate()` on the package's own default recipe applied to
`soil_data` fires the middle-band warning: the resulting SQI spans roughly
0.36-0.70, so 100% of samples land in the middle bands and the "very low" and
"very high" categories are empty. This is not a bug -- it is the diagnostic
working, on exactly the pathology it was built to expose.

# soilquality 1.1.0 (development)

Broadens the package from a single SQI route (PCA-MDS, AHP/loading weights,
linear scoring, weighted additive aggregation) toward the routes the soil
quality literature actually uses. This release covers non-linear scoring and
weight-free aggregation. All additions are opt-in; the default pipeline
produces exactly the values it produced in 1.0.0, and a golden-output
regression test now enforces that.

### New features

#### Non-linear (sigmoidal) scoring
- `score_sigmoid()` - scores an indicator with `S = 1 / (1 + (x/x0)^b)`, the
  dominant scoring form in the SQI literature. Both `x0` (the value scoring
  0.5) and `b` (steepness) are parameters. The `b = 2.5` default is a
  convention inherited from the literature with empirical support for
  pH/TN/SOC/P only, not a general constant, and the documentation says so.
- `sigmoid_scoring()` - the matching `scoring_rule` constructor, so the new
  curve is reachable from `compute_sqi_properties()`.
- `score_indicators()` gains a `"sigmoid"` scoring type alongside the
  existing `higher`/`lower`/`optimum`/`threshold`.
- `standard_scoring_rules()` gains `scoring = c("linear", "sigmoid")` and `b`.
  pH deliberately remains an optimum-range rule under `"sigmoid"`: the
  sigmoidal curve is monotonic and has no optimum form.

#### Area-based (weight-free) aggregation
- `sqi_area()` - aggregates scored indicators as the area of the radar
  diagram they trace, `A = 0.5 * sum(s^2) * sin(2*pi/n)` (Kuzyakov et al.
  2020, eq. 2). This ignores weights entirely, sidestepping the most
  contested step in the pipeline. Supplying `reference` reports the result as
  a ratio against a non-degraded reference soil, which is what makes
  area-based values comparable across studies -- the absolute value is not.
- `compute_sqi_df()` gains `method = c("weighted", "area")` and `reference`.
  Both flow through `compute_sqi()` and `compute_sqi_properties()` via `...`.
  The returned `sqi_result` now carries a `method` element.

### Documentation
- `score_sigmoid()` documents that the literature contradicts itself on
  linear vs non-linear scoring (Yuan 2026 finds non-linear better; Bilgili et
  al. 2017, cited in Yuan's own introduction, finds the opposite) and
  recommends computing both.
- `sqi_area()` documents why the formula squares each score rather than
  multiplying adjacent radii: the square form is order-independent, whereas
  the true polygon area would depend on the arbitrary order of indicators
  around the diagram.

### Internal
- Added a golden-output regression baseline pinning the MDS, PCA variance
  decomposition, weights and SQI values of the default pipeline against the
  shipped `soil_data`. Every change from here must leave it green or declare
  itself a break.
- Migrated the test suite to `testthat` edition 3 (`Config/testthat/edition: 3`).
  No test changes were required. User-facing behaviour is unaffected.

# soilquality 1.0.0

*Release Date: 2025-12-07*

## Initial Release

This is the first public release of the soilquality package, providing comprehensive tools for calculating Soil Quality Index (SQI) using scientifically validated methods combining Principal Component Analysis (PCA) and Analytic Hierarchy Process (AHP).

### Major Features

#### Core Functionality
- **PCA-based MDS Selection**: Automated selection of Minimum Data Set indicators using Principal Component Analysis with configurable variance and loading thresholds
- **AHP Weighting System**: Expert-based indicator weighting with consistency ratio validation following Saaty's methodology
- **Flexible Scoring Framework**: Multiple normalization methods to handle different soil property characteristics
- **Property Selection**: Pre-defined property sets (basic, standard, comprehensive, physical, chemical, fertility) and custom property selection
- **Standard Scoring Rules**: Automatic rule assignment based on property name patterns for common soil properties
- **Comprehensive Visualization**: Five plot types (distribution, indicators, weights, scree, biplot) plus multi-panel reports
- **Interactive Application**: Shiny-based GUI for non-programmers with file upload, configuration, and results download

#### Workflow Options
- **File-based workflow**: `compute_sqi()` for CSV input/output
- **In-memory workflow**: `compute_sqi_df()` for data frame processing
- **Enhanced workflow**: `compute_sqi_properties()` with property selection and constructor-based scoring

### Complete Function Reference

#### Data Handling Functions
- `read_soil_csv()` - Import soil data from CSV files with encoding handling
- `standardize_numeric()` - Z-score standardization of numeric columns
- `to_numeric()` - Safe type conversion with NA for failures

#### PCA and MDS Selection
- `pca_select_mds()` - Perform PCA and select minimum data set based on variance and loading thresholds

#### AHP Weighting Functions
- `ahp_weights()` - Calculate indicator weights from pairwise comparison matrix using eigenvalue decomposition
- `create_ahp_matrix()` - Interactive or programmatic AHP matrix creation with validation
- `ratio_to_saaty()` - Convert importance ratios to Saaty scale (1-9)
- `print.ahp_matrix()` - S3 print method for AHP matrix objects

#### Scoring Functions (Low-level)
- `score_higher_better()` - Normalize properties where higher values indicate better quality
- `score_lower_better()` - Normalize properties where lower values indicate better quality
- `score_optimum()` - Normalize properties with optimal range using linear or quadratic penalty
- `score_threshold()` - Custom piecewise linear scoring based on threshold-score pairs
- `score_indicators()` - Apply scoring functions to multiple indicators

#### Scoring Constructors (User-facing)
- `higher_better()` - Constructor for higher-is-better scoring rules
- `lower_better()` - Constructor for lower-is-better scoring rules
- `optimum_range()` - Constructor for optimal range scoring with tolerance
- `threshold_scoring()` - Constructor for custom threshold-based scoring
- `print.scoring_rule()` - S3 print method for scoring rule objects

#### Property Sets and Standard Rules
- `soil_property_sets` - Pre-defined collections: basic (pH, OM, P, K), standard (9 properties), comprehensive (14 properties), physical, chemical, fertility
- `standard_scoring_rules()` - Automatic scoring rule assignment based on property name patterns

#### SQI Computation Functions
- `compute_sqi()` - File-based SQI computation with CSV input/output
- `compute_sqi_df()` - In-memory SQI computation with data frame input
- `compute_sqi_properties()` - Enhanced SQI computation with property selection and constructor-based scoring

#### Visualization Functions
- `plot.sqi_result()` - S3 plot method supporting five plot types:
  - "distribution": Histogram of SQI values with mean line
  - "indicators": Boxplots of indicator scores
  - "weights": Bar chart of AHP weights with CR annotation
  - "scree": Variance explained by principal components
  - "biplot": PCA biplot of observations and variables
- `plot_sqi_report()` - Generate comprehensive 2x2 multi-panel visualization report

#### Interactive Tools
- `run_sqi_app()` - Launch interactive Shiny application with file upload, property selection, scoring configuration, AHP input, results display, and CSV download

### Example Datasets

- `soil_ucayali` - Real soil property data from Ucayali, Peru (50 samples, 14 properties)
  - Physical properties: Sand, Silt, Clay, BD (bulk density)
  - Chemical properties: pH, OM (organic matter), SOC (soil organic carbon)
  - Nutrients: N, P, K, CEC, Ca, Mg
  - Other: EC (electrical conductivity)

### Documentation

#### Vignettes
- **Introduction to soilquality**: Basic workflow, installation, quick start examples, result interpretation
- **Advanced Usage**: Property selection strategies, custom scoring rules, AHP matrix creation, visualization options
- **AHP Matrices Guide**: AHP methodology explanation, creating pairwise comparisons, consistency ratio interpretation, tips for improving inconsistent matrices

#### Function Documentation
- Complete roxygen2 documentation for all 28 exported functions
- Parameter descriptions with types and defaults
- Return value specifications with structure details
- Working examples for each function
- Cross-references to related functions

#### Package Documentation
- Comprehensive README with installation instructions, quick start, main functions, citation information
- Package-level documentation with workflow overview and examples
- NEWS file with version history

### Testing and Quality

#### Test Coverage
- Unit tests for all core modules (data handling, PCA/MDS, AHP, scoring, SQI computation, visualization)
- Integration tests for complete workflows
- Test coverage >= 80% of core functions
- All tests pass with testthat framework

#### Package Quality
- Passes R CMD check with 0 errors, 0 warnings
- All examples run without errors
- Valid DESCRIPTION and NAMESPACE files
- MIT License included
- UTF-8 encoding properly declared
- All dependencies declared in DESCRIPTION

### Dependencies

#### Required (Imports)
- `stats` - PCA (prcomp), eigenvalue calculations
- `utils` - CSV reading, data manipulation

#### Optional (Suggests)
- `shiny` - Interactive application
- `DT` - Data tables in Shiny app
- `testthat` (>= 3.0.0) - Unit testing
- `knitr` - Vignette building
- `rmarkdown` - Vignette building
- `covr` - Test coverage analysis

#### R Version
- Requires R >= 3.5.0

### Known Limitations

#### Technical Constraints
- PCA requires at least 3 numeric variables for meaningful dimensionality reduction
- Sufficient observations recommended (n >= p) for stable PCA results
- AHP consistency ratio should be < 0.1 for reliable weights (warning issued if exceeded)
- Interactive AHP matrix creation requires interactive R session (not available in batch mode)

#### Scope Limitations
- Package focuses on PCA-based MDS selection; other selection methods not included
- AHP is the only weighting method implemented; other MCDA methods not included
- Visualization uses base R graphics only (no ggplot2 integration)
- Shiny app requires manual launch; no deployed web version included

### Future Development

Potential enhancements for future versions:
- Additional MDS selection methods (correlation-based, expert selection)
- Alternative weighting methods (equal weights, data-driven weights)
- ggplot2-based visualization option
- Additional scoring functions (membership functions, fuzzy logic)
- Spatial analysis integration
- Time series support for monitoring
- Export to additional formats (PDF reports, GIS layers)

### Acknowledgments

This package implements methodologies from soil quality assessment literature:
- Andrews et al. (2004) - Soil Management Assessment Framework
- Saaty (1980) - Analytic Hierarchy Process
- PCA-based MDS selection approaches widely used in soil science research

### Citation

To cite this package in publications:

```
Carbajal, Carlos (2025). soilquality: Soil Quality Index Calculation with PCA and AHP. R package version 1.0.0. https://github.com/ccarbajal16/soilquality
```

### Getting Help

- Function documentation: `?function_name` or `help(function_name)`
- Vignettes: `browseVignettes("soilquality")`
- Issues: https://github.com/ccarbajal16/soilquality/issues

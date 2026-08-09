# Package index

## Main SQI Computation

Core functions for computing Soil Quality Index with different workflows

- [`compute_sqi()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi.md)
  : Compute Soil Quality Index from CSV file
- [`compute_sqi_df()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_df.md)
  : Compute Soil Quality Index from data frame
- [`compute_sqi_properties()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_properties.md)
  : Compute Soil Quality Index with property selection

## Data Handling

Functions for importing and preprocessing soil data

- [`read_soil_csv()`](https://ccarbajal16.github.io/soilquality/reference/read_soil_csv.md)
  : Read Soil Data from CSV File
- [`standardize_numeric()`](https://ccarbajal16.github.io/soilquality/reference/standardize_numeric.md)
  : Standardize Numeric Columns
- [`to_numeric()`](https://ccarbajal16.github.io/soilquality/reference/to_numeric.md)
  : Convert Values to Numeric

## MDS Selection

Selecting a Minimum Data Set, by variance (PCA) or by centrality
(correlation network)

- [`pca_select_mds()`](https://ccarbajal16.github.io/soilquality/reference/pca_select_mds.md)
  : Select Minimum Data Set (MDS) Using PCA
- [`pca_adequacy()`](https://ccarbajal16.github.io/soilquality/reference/pca_adequacy.md)
  : Test whether data is adequate for PCA
- [`na_select_mds()`](https://ccarbajal16.github.io/soilquality/reference/na_select_mds.md)
  : Select a Minimum Data Set by correlation-network analysis
- [`mds_consensus()`](https://ccarbajal16.github.io/soilquality/reference/mds_consensus.md)
  : Take the consensus of two Minimum Data Set selection routes

## Functional Grouping

Selecting one indicator per soil function (EMDS) rather than across the
whole pool

- [`soil_function_groups`](https://ccarbajal16.github.io/soilquality/reference/soil_function_groups.md)
  : Soil indicators grouped by ecosystem function
- [`assign_function_groups()`](https://ccarbajal16.github.io/soilquality/reference/assign_function_groups.md)
  : Map property names onto soil function groups

## AHP Weighting

Analytic Hierarchy Process for expert-based indicator weighting

- [`ahp_weights()`](https://ccarbajal16.github.io/soilquality/reference/ahp_weights.md)
  : Calculate AHP weights from pairwise comparison matrix
- [`create_ahp_matrix()`](https://ccarbajal16.github.io/soilquality/reference/create_ahp_matrix.md)
  : Create AHP pairwise comparison matrix interactively
- [`ratio_to_saaty()`](https://ccarbajal16.github.io/soilquality/reference/ratio_to_saaty.md)
  : Convert importance ratios to Saaty pairwise comparison matrix

## Scoring Functions

Functions for transforming soil properties into quality scores

- [`score_indicators()`](https://ccarbajal16.github.io/soilquality/reference/score_indicators.md)
  : Score multiple indicators using specified scoring functions
- [`score_higher_better()`](https://ccarbajal16.github.io/soilquality/reference/score_higher_better.md)
  : Score indicator with higher-is-better normalization
- [`score_lower_better()`](https://ccarbajal16.github.io/soilquality/reference/score_lower_better.md)
  : Score indicator with lower-is-better normalization
- [`score_optimum()`](https://ccarbajal16.github.io/soilquality/reference/score_optimum.md)
  : Score indicator with optimum range
- [`score_threshold()`](https://ccarbajal16.github.io/soilquality/reference/score_threshold.md)
  : Score indicator with threshold-based piecewise interpolation
- [`score_sigmoid()`](https://ccarbajal16.github.io/soilquality/reference/score_sigmoid.md)
  : Score indicator with a non-linear (sigmoidal) curve

## Scoring Constructors

Object-oriented constructors for scoring rules

- [`higher_better()`](https://ccarbajal16.github.io/soilquality/reference/higher_better.md)
  : Create a higher-is-better scoring rule
- [`lower_better()`](https://ccarbajal16.github.io/soilquality/reference/lower_better.md)
  : Create a lower-is-better scoring rule
- [`optimum_range()`](https://ccarbajal16.github.io/soilquality/reference/optimum_range.md)
  : Create an optimum range scoring rule
- [`threshold_scoring()`](https://ccarbajal16.github.io/soilquality/reference/threshold_scoring.md)
  : Create a threshold-based scoring rule
- [`sigmoid_scoring()`](https://ccarbajal16.github.io/soilquality/reference/sigmoid_scoring.md)
  : Create a non-linear (sigmoidal) scoring rule
- [`reference_scoring()`](https://ccarbajal16.github.io/soilquality/reference/reference_scoring.md)
  : Create a reference-soil scoring rule

## Reference-Soil Standardisation

Scoring against an undisturbed reference soil, the documented escape
from index incomparability

- [`standardize_to_reference()`](https://ccarbajal16.github.io/soilquality/reference/standardize_to_reference.md)
  : Standardise an indicator against a non-degraded reference soil
- [`sensitivity_resistance()`](https://ccarbajal16.github.io/soilquality/reference/sensitivity_resistance.md)
  : Classify indicators as sensitive or resistant to degradation

## Aggregation

Combining scored indicators into a single index

- [`sqi_area()`](https://ccarbajal16.github.io/soilquality/reference/sqi_area.md)
  : Aggregate indicator scores by the area of a radar diagram

## Validation

Assessing whether an index actually discriminates, and whether a
conclusion survives a change of recipe

- [`sqi_validate()`](https://ccarbajal16.github.io/soilquality/reference/sqi_validate.md)
  : Validate a Soil Quality Index
- [`sqi_stability()`](https://ccarbajal16.github.io/soilquality/reference/sqi_stability.md)
  : Test whether a conclusion survives a change of index recipe

## Property Sets and Standard Rules

Pre-defined property collections and automatic scoring rules

- [`soil_property_sets`](https://ccarbajal16.github.io/soilquality/reference/soil_property_sets.md)
  : Pre-defined soil property sets
- [`standard_scoring_rules()`](https://ccarbajal16.github.io/soilquality/reference/standard_scoring_rules.md)
  : Generate standard scoring rules for soil properties

## Visualization

Functions for plotting and visualizing SQI results

- [`plot(`*`<sqi_result>`*`)`](https://ccarbajal16.github.io/soilquality/reference/plot.sqi_result.md)
  : Plot SQI Results
- [`plot_sqi_report()`](https://ccarbajal16.github.io/soilquality/reference/plot_sqi_report.md)
  : Create Multi-Panel SQI Report
- [`plot_sqi_validation()`](https://ccarbajal16.github.io/soilquality/reference/plot_sqi_validation.md)
  : Plot the distribution of an index across decision categories

## Interactive Tools

Shiny-based interactive applications

- [`run_sqi_app()`](https://ccarbajal16.github.io/soilquality/reference/run_sqi_app.md)
  : Launch Interactive Soil Quality Index Calculator

## Example Data

Two datasets, for two different jobs. `soil_data` for scoring, weighting
and aggregation; `soil_structured` for anything that reads the structure
between indicators.

- [`soil_data`](https://ccarbajal16.github.io/soilquality/reference/soil_data.md)
  : Soil Data from Ucayali, Peru
- [`soil_structured`](https://ccarbajal16.github.io/soilquality/reference/soil_structured.md)
  : Simulated Soil Data with Realistic Covariance Structure

## Print Methods

S3 print methods for custom objects

- [`print(`*`<ahp_matrix>`*`)`](https://ccarbajal16.github.io/soilquality/reference/print.ahp_matrix.md)
  : Print method for ahp_matrix objects
- [`print(`*`<scoring_rule>`*`)`](https://ccarbajal16.github.io/soilquality/reference/print.scoring_rule.md)
  : Print method for scoring_rule objects
- [`print(`*`<sqi_validation>`*`)`](https://ccarbajal16.github.io/soilquality/reference/print.sqi_validation.md)
  : Print method for sqi_validation objects
- [`print(`*`<sqi_stability>`*`)`](https://ccarbajal16.github.io/soilquality/reference/print.sqi_stability.md)
  : Print method for sqi_stability objects
- [`print(`*`<pca_adequacy>`*`)`](https://ccarbajal16.github.io/soilquality/reference/print.pca_adequacy.md)
  : Print method for pca_adequacy objects

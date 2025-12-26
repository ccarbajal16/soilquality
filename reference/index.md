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

## PCA and MDS Selection

Principal Component Analysis for Minimum Data Set selection

- [`pca_select_mds()`](https://ccarbajal16.github.io/soilquality/reference/pca_select_mds.md)
  : Select Minimum Data Set (MDS) Using PCA

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

## Interactive Tools

Shiny-based interactive applications

- [`run_sqi_app()`](https://ccarbajal16.github.io/soilquality/reference/run_sqi_app.md)
  : Launch Interactive Soil Quality Index Calculator

## Example Data

Built-in datasets for examples and testing

- [`soil_ucayali`](https://ccarbajal16.github.io/soilquality/reference/soil_ucayali.md)
  : Example Soil Data from Ucayali, Peru
- [`soil_data`](https://ccarbajal16.github.io/soilquality/reference/soil_data.md)
  : Extended Soil Data from Ucayali, Peru

## Print Methods

S3 print methods for custom objects

- [`print(`*`<ahp_matrix>`*`)`](https://ccarbajal16.github.io/soilquality/reference/print.ahp_matrix.md)
  : Print method for ahp_matrix objects
- [`print(`*`<scoring_rule>`*`)`](https://ccarbajal16.github.io/soilquality/reference/print.scoring_rule.md)
  : Print method for scoring_rule objects

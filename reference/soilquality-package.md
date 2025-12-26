# soilquality: Soil Quality Index Calculation with PCA and AHP

Provides tools for calculating Soil Quality Index (SQI) using Principal
Component Analysis (PCA) for Minimum Data Set (MDS) selection and
Analytic Hierarchy Process (AHP) for expert-based weighting. The package
transforms soil property data into standardized quality metrics with
comprehensive visualization and interactive tools.

The soilquality package provides a comprehensive toolkit for calculating
Soil Quality Index (SQI) using scientifically validated methods. It
combines Principal Component Analysis (PCA) for selecting a Minimum Data
Set (MDS) of indicators with the Analytic Hierarchy Process (AHP) for
expert-based weighting.

## Main Features

- **Data Handling**: Import and standardize soil property data

- **MDS Selection**: Use PCA to identify key soil indicators

- **Expert Weighting**: Apply AHP for indicator importance

- **Flexible Scoring**: Multiple scoring functions for different
  property types

- **Visualization**: Comprehensive plotting functions for results

- **Interactive Tools**: Shiny application for non-programmers

## Key Functions

**Main Workflow Functions:**

- [`compute_sqi`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi.md):
  Calculate SQI from CSV files

- [`compute_sqi_df`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_df.md):
  Calculate SQI from data frames

- [`compute_sqi_properties`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_properties.md):
  Calculate SQI with property selection

**Data Handling:**

- [`read_soil_csv`](https://ccarbajal16.github.io/soilquality/reference/read_soil_csv.md):
  Read soil data from CSV files

- [`standardize_numeric`](https://ccarbajal16.github.io/soilquality/reference/standardize_numeric.md):
  Standardize numeric columns

**PCA and MDS Selection:**

- [`pca_select_mds`](https://ccarbajal16.github.io/soilquality/reference/pca_select_mds.md):
  Perform PCA and select minimum data set

**AHP Weighting:**

- [`create_ahp_matrix`](https://ccarbajal16.github.io/soilquality/reference/create_ahp_matrix.md):
  Interactive AHP matrix creation

- [`ahp_weights`](https://ccarbajal16.github.io/soilquality/reference/ahp_weights.md):
  Calculate weights from pairwise comparisons

**Scoring Functions:**

- [`higher_better`](https://ccarbajal16.github.io/soilquality/reference/higher_better.md):
  Constructor for properties where higher is better

- [`lower_better`](https://ccarbajal16.github.io/soilquality/reference/lower_better.md):
  Constructor for properties where lower is better

- [`optimum_range`](https://ccarbajal16.github.io/soilquality/reference/optimum_range.md):
  Constructor for properties with optimal ranges

- [`threshold_scoring`](https://ccarbajal16.github.io/soilquality/reference/threshold_scoring.md):
  Constructor for custom threshold-based scoring

- [`standard_scoring_rules`](https://ccarbajal16.github.io/soilquality/reference/standard_scoring_rules.md):
  Get standard scoring rules for common properties

**Property Sets:**

- [`soil_property_sets`](https://ccarbajal16.github.io/soilquality/reference/soil_property_sets.md):
  Pre-defined collections of soil properties

**Visualization:**

- [`plot.sqi_result`](https://ccarbajal16.github.io/soilquality/reference/plot.sqi_result.md):
  Plot SQI results (S3 method)

- [`plot_sqi_report`](https://ccarbajal16.github.io/soilquality/reference/plot_sqi_report.md):
  Generate comprehensive multi-panel report

**Interactive Tools:**

- [`run_sqi_app`](https://ccarbajal16.github.io/soilquality/reference/run_sqi_app.md):
  Launch interactive Shiny application

## Getting Started

The typical workflow for calculating SQI involves:

1\. **Load your data**: Use
[`read_soil_csv()`](https://ccarbajal16.github.io/soilquality/reference/read_soil_csv.md)
or provide a data frame 2. **Select properties**: Choose relevant soil
properties for analysis 3. **Define scoring rules**: Specify how each
property should be scored 4. **Calculate SQI**: Use
[`compute_sqi_properties()`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_properties.md)
or related functions 5. **Visualize results**: Use
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) or
[`plot_sqi_report()`](https://ccarbajal16.github.io/soilquality/reference/plot_sqi_report.md)

## Example Workflow

    # Load example data
    data(soil_ucayali)

    # Calculate SQI with standard properties
    result <- compute_sqi_properties(
      data = soil_ucayali,
      properties = c("pH", "OM", "N", "P", "K", "CEC"),
      id_column = "SampleID"
    )

    # View results
    print(result)

    # Create visualizations
    plot(result, type = "distribution")
    plot(result, type = "weights")

    # Generate comprehensive report
    plot_sqi_report(result)

## Custom Scoring Rules

You can define custom scoring rules for each property:

    # Define scoring rules
    rules <- list(
      pH = optimum_range(optimal = 6.5, tolerance = 1),
      OM = higher_better(),
      BD = lower_better(),
      P = higher_better()
    )

    # Calculate SQI with custom rules
    result <- compute_sqi_properties(
      data = soil_ucayali,
      properties = names(rules),
      scoring_rules = rules,
      id_column = "SampleID"
    )

## Interactive Mode

For users who prefer a graphical interface:

    # Launch Shiny application
    run_sqi_app()

## Package Options

The package uses the following options:

- None currently defined

## References

- Andrews, S. S., Karlen, D. L., & Cambardella, C. A. (2004). The soil
  management assessment framework: A quantitative soil quality
  evaluation method. Soil Science Society of America Journal, 68(6),
  1945-1962.

- Saaty, T. L. (1980). The Analytic Hierarchy Process. McGraw-Hill, New
  York.

## See also

Useful links:

- <https://github.com/ccarbajal16/soilquality>

- Report bugs at <https://github.com/ccarbajal16/soilquality/issues>

## Author

**Maintainer**: Carlos Carbajal <ccarbajal@educagis.com>

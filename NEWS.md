# soilquality 1.0.0

## Initial Release

### Features

- Core SQI computation pipeline with PCA-based MDS selection
- AHP weighting with consistency ratio calculation
- Multiple scoring functions (higher_better, lower_better, optimum_range, threshold_scoring)
- Property selection and pre-defined property sets
- Standard scoring rules for common soil properties
- Comprehensive visualization functions
- Interactive Shiny application
- Example datasets and vignettes

### Functions

#### Data Handling
- `read_soil_csv()`: Import soil data from CSV files
- `standardize_numeric()`: Z-score standardization

#### PCA and MDS
- `pca_select_mds()`: PCA-based minimum data set selection

#### AHP Weighting
- `ahp_weights()`: Calculate AHP weights from pairwise matrix
- `create_ahp_matrix()`: Interactive AHP matrix creation
- `ratio_to_saaty()`: Convert importance ratios to Saaty scale

#### Scoring
- `score_higher_better()`: Score properties where higher is better
- `score_lower_better()`: Score properties where lower is better
- `score_optimum()`: Score properties with optimal range
- `score_threshold()`: Score properties with custom thresholds
- `score_indicators()`: Apply scoring to multiple indicators

#### Scoring Constructors
- `higher_better()`: Constructor for higher-is-better scoring
- `lower_better()`: Constructor for lower-is-better scoring
- `optimum_range()`: Constructor for optimal range scoring
- `threshold_scoring()`: Constructor for threshold-based scoring

#### Property Sets
- `soil_property_sets`: Pre-defined property collections
- `standard_scoring_rules()`: Standard scoring rules for common properties

#### SQI Computation
- `compute_sqi()`: File-based SQI computation
- `compute_sqi_df()`: In-memory SQI computation
- `compute_sqi_properties()`: Enhanced SQI computation with property selection

#### Visualization
- `plot.sqi_result()`: S3 plot method for SQI results
- `plot_sqi_report()`: Multi-panel visualization report

#### Interactive
- `run_sqi_app()`: Launch Shiny application

### Documentation

- Introduction vignette with basic workflow
- Advanced usage vignette with custom scoring
- AHP matrices vignette with methodology guide
- Comprehensive function documentation with examples

### Testing

- Unit tests for all core functions
- Integration tests for complete workflows
- Test coverage >= 80%

## Known Limitations

- PCA requires at least 3 numeric variables
- AHP consistency ratio should be < 0.1 for reliable weights
- Interactive AHP matrix creation requires interactive R session

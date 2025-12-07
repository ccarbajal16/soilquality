#' @keywords internal
"_PACKAGE"

#' soilquality: Soil Quality Index Calculation with PCA and AHP
#'
#' @description
#' The soilquality package provides a comprehensive toolkit for calculating
#' Soil Quality Index (SQI) using scientifically validated methods. It combines
#' Principal Component Analysis (PCA) for selecting a Minimum Data Set (MDS)
#' of indicators with the Analytic Hierarchy Process (AHP) for expert-based
#' weighting.
#'
#' @section Main Features:
#' \itemize{
#'   \item \strong{Data Handling}: Import and standardize soil property data
#'   \item \strong{MDS Selection}: Use PCA to identify key soil indicators
#'   \item \strong{Expert Weighting}: Apply AHP for indicator importance
#'   \item \strong{Flexible Scoring}: Multiple scoring functions for different property types
#'   \item \strong{Visualization}: Comprehensive plotting functions for results
#'   \item \strong{Interactive Tools}: Shiny application for non-programmers
#' }
#'
#' @section Key Functions:
#'
#' \strong{Main Workflow Functions:}
#' \itemize{
#'   \item \code{\link{compute_sqi}}: Calculate SQI from CSV files
#'   \item \code{\link{compute_sqi_df}}: Calculate SQI from data frames
#'   \item \code{\link{compute_sqi_properties}}: Calculate SQI with property selection
#' }
#'
#' \strong{Data Handling:}
#' \itemize{
#'   \item \code{\link{read_soil_csv}}: Read soil data from CSV files
#'   \item \code{\link{standardize_numeric}}: Standardize numeric columns
#' }
#'
#' \strong{PCA and MDS Selection:}
#' \itemize{
#'   \item \code{\link{pca_select_mds}}: Perform PCA and select minimum data set
#' }
#'
#' \strong{AHP Weighting:}
#' \itemize{
#'   \item \code{\link{create_ahp_matrix}}: Interactive AHP matrix creation
#'   \item \code{\link{ahp_weights}}: Calculate weights from pairwise comparisons
#' }
#'
#' \strong{Scoring Functions:}
#' \itemize{
#'   \item \code{\link{higher_better}}: Constructor for properties where higher is better
#'   \item \code{\link{lower_better}}: Constructor for properties where lower is better
#'   \item \code{\link{optimum_range}}: Constructor for properties with optimal ranges
#'   \item \code{\link{threshold_scoring}}: Constructor for custom threshold-based scoring
#'   \item \code{\link{standard_scoring_rules}}: Get standard scoring rules for common properties
#' }
#'
#' \strong{Property Sets:}
#' \itemize{
#'   \item \code{\link{soil_property_sets}}: Pre-defined collections of soil properties
#' }
#'
#' \strong{Visualization:}
#' \itemize{
#'   \item \code{\link{plot.sqi_result}}: Plot SQI results (S3 method)
#'   \item \code{\link{plot_sqi_report}}: Generate comprehensive multi-panel report
#' }
#'
#' \strong{Interactive Tools:}
#' \itemize{
#'   \item \code{\link{run_sqi_app}}: Launch interactive Shiny application
#' }
#'
#' @section Getting Started:
#'
#' The typical workflow for calculating SQI involves:
#'
#' 1. \strong{Load your data}: Use \code{read_soil_csv()} or provide a data frame
#' 2. \strong{Select properties}: Choose relevant soil properties for analysis
#' 3. \strong{Define scoring rules}: Specify how each property should be scored
#' 4. \strong{Calculate SQI}: Use \code{compute_sqi_properties()} or related functions
#' 5. \strong{Visualize results}: Use \code{plot()} or \code{plot_sqi_report()}
#'
#' @section Example Workflow:
#'
#' \preformatted{
#' # Load example data
#' data(soil_ucayali)
#'
#' # Calculate SQI with standard properties
#' result <- compute_sqi_properties(
#'   data = soil_ucayali,
#'   properties = c("pH", "OM", "N", "P", "K", "CEC"),
#'   id_column = "SampleID"
#' )
#'
#' # View results
#' print(result)
#'
#' # Create visualizations
#' plot(result, type = "distribution")
#' plot(result, type = "weights")
#'
#' # Generate comprehensive report
#' plot_sqi_report(result)
#' }
#'
#' @section Custom Scoring Rules:
#'
#' You can define custom scoring rules for each property:
#'
#' \preformatted{
#' # Define scoring rules
#' rules <- list(
#'   pH = optimum_range(optimal = 6.5, tolerance = 1),
#'   OM = higher_better(),
#'   BD = lower_better(),
#'   P = higher_better()
#' )
#'
#' # Calculate SQI with custom rules
#' result <- compute_sqi_properties(
#'   data = soil_ucayali,
#'   properties = names(rules),
#'   scoring_rules = rules,
#'   id_column = "SampleID"
#' )
#' }
#'
#' @section Interactive Mode:
#'
#' For users who prefer a graphical interface:
#'
#' \preformatted{
#' # Launch Shiny application
#' run_sqi_app()
#' }
#'
#' @section Package Options:
#'
#' The package uses the following options:
#' \itemize{
#'   \item None currently defined
#' }
#'
#' @section References:
#'
#' \itemize{
#'   \item Andrews, S. S., Karlen, D. L., & Cambardella, C. A. (2004).
#'     The soil management assessment framework: A quantitative soil quality
#'     evaluation method. Soil Science Society of America Journal, 68(6), 1945-1962.
#'   \item Saaty, T. L. (1980). The Analytic Hierarchy Process.
#'     McGraw-Hill, New York.
#' }
#'
#' @name soilquality-package
#' @aliases soilquality
NULL

#' Compute Soil Quality Index from CSV file
#'
#' This is the main file-based workflow function that orchestrates the complete
#' SQI calculation pipeline. It reads soil data from a CSV file, performs
#' standardization, PCA-based MDS selection, AHP weighting, indicator scoring,
#' and calculates the final Soil Quality Index.
#'
#' @param input_csv Character string specifying the path to the input CSV file
#'   containing soil property data. The file should have samples in rows and
#'   properties in columns.
#' @param id_column Optional character string specifying the name of the ID
#'   column to preserve in the output. If NULL, no ID column is preserved.
#' @param pairwise_csv Optional character string specifying the path to a CSV
#'   file containing the AHP pairwise comparison matrix. If NULL, equal weights
#'   are used for all indicators.
#' @param output_csv Optional character string specifying the path where the
#'   results should be saved as a CSV file. If NULL, results are not saved.
#' @param directions Optional named list specifying scoring functions for each
#'   indicator. If NULL, all indicators use higher-is-better scoring.
#' @param var_threshold Numeric value for PCA variance threshold (default 0.05).
#' @param loading_threshold Numeric value for PCA loading threshold (default 0.5).
#' @param ... Additional arguments passed to other functions.
#'
#' @return An object of class "sqi_result" containing:
#'   \describe{
#'     \item{mds}{Character vector of selected MDS indicators}
#'     \item{weights}{Named numeric vector of AHP weights}
#'     \item{CR}{Consistency Ratio from AHP}
#'     \item{results}{Data frame with original data, scored indicators, and SQI}
#'     \item{pca}{PCA object from stats::prcomp}
#'     \item{loadings}{Matrix of variable loadings}
#'     \item{var_exp}{Numeric vector of variance explained by each PC}
#'   }
#'
#' @details
#' The function performs the following steps:
#' \enumerate{
#'   \item Read soil data from CSV file
#'   \item Standardize numeric columns (z-score)
#'   \item Perform PCA and select MDS indicators
#'   \item Calculate AHP weights (from pairwise matrix or equal weights)
#'   \item Score each MDS indicator
#'   \item Calculate weighted SQI as sum of (weight * score)
#'   \item Optionally save results to CSV
#' }
#'
#' @examples
#' \dontrun{
#' # Basic usage with CSV file
#' result <- compute_sqi(
#'   input_csv = "soil_data.csv",
#'   id_column = "SampleID"
#' )
#'
#' # With AHP pairwise matrix
#' result <- compute_sqi(
#'   input_csv = "soil_data.csv",
#'   id_column = "SampleID",
#'   pairwise_csv = "pairwise_matrix.csv"
#' )
#'
#' # With custom scoring directions
#' directions <- list(
#'   pH = list(type = "optimum", optimum = 7, tol = 1.5, penalty = "linear"),
#'   OM = list(type = "higher"),
#'   BD = list(type = "lower")
#' )
#' result <- compute_sqi(
#'   input_csv = "soil_data.csv",
#'   id_column = "SampleID",
#'   directions = directions,
#'   output_csv = "sqi_results.csv"
#' )
#' }
#'
#' @seealso \code{\link{compute_sqi_df}}, \code{\link{compute_sqi_properties}}
#'
#' @export
compute_sqi <- function(input_csv,
                        id_column = NULL,
                        pairwise_csv = NULL,
                        output_csv = NULL,
                        directions = NULL,
                        var_threshold = 0.05,
                        loading_threshold = 0.5,
                        ...) {
  # Read input data
  data <- read_soil_csv(input_csv)

  # Read pairwise matrix if provided
  pairwise_matrix <- NULL
  if (!is.null(pairwise_csv)) {
    pairwise_df <- read_soil_csv(pairwise_csv)
    # Convert to matrix, assuming first column is row names
    if (ncol(pairwise_df) > 1) {
      rownames(pairwise_df) <- pairwise_df[[1]]
      pairwise_matrix <- as.matrix(pairwise_df[, -1])
    } else {
      stop("Pairwise CSV must have at least 2 columns")
    }
  }

  # Call the data frame version
  result <- compute_sqi_df(
    df = data,
    id_column = id_column,
    pairwise_df = pairwise_matrix,
    directions = directions,
    var_threshold = var_threshold,
    loading_threshold = loading_threshold,
    ...
  )

  # Save results if output path provided
  if (!is.null(output_csv)) {
    utils::write.csv(result$results, output_csv, row.names = FALSE)
  }

  result
}


#' Compute Soil Quality Index from data frame
#'
#' This is the in-memory workflow function that orchestrates the complete
#' SQI calculation pipeline using data frames. It performs standardization,
#' PCA-based MDS selection, AHP weighting, indicator scoring, and calculates
#' the final Soil Quality Index.
#'
#' @param df Data frame containing soil property data with samples in rows
#'   and properties in columns.
#' @param id_column Optional character string specifying the name of the ID
#'   column to preserve in the output. If NULL, no ID column is preserved.
#' @param pairwise_df Optional pairwise comparison matrix (as matrix or data
#'   frame). If NULL, equal weights are used for all indicators.
#' @param directions Optional named list specifying scoring functions for each
#'   indicator. If NULL, all indicators use higher-is-better scoring.
#' @param var_threshold Numeric value for PCA variance threshold (default 0.05).
#' @param loading_threshold Numeric value for PCA loading threshold (default 0.5).
#' @param ... Additional arguments (currently unused).
#'
#' @return An object of class "sqi_result" containing:
#'   \describe{
#'     \item{mds}{Character vector of selected MDS indicators}
#'     \item{weights}{Named numeric vector of AHP weights}
#'     \item{CR}{Consistency Ratio from AHP}
#'     \item{results}{Data frame with original data, scored indicators, and SQI}
#'     \item{pca}{PCA object from stats::prcomp}
#'     \item{loadings}{Matrix of variable loadings}
#'     \item{var_exp}{Numeric vector of variance explained by each PC}
#'   }
#'
#' @details
#' The function performs the following steps:
#' \enumerate{
#'   \item Preserve ID column if specified
#'   \item Standardize numeric columns (z-score)
#'   \item Perform PCA and select MDS indicators
#'   \item Calculate AHP weights (from pairwise matrix or equal weights)
#'   \item Score each MDS indicator
#'   \item Calculate weighted SQI as sum of (weight * score)
#' }
#'
#' @examples
#' # Create example data
#' soil_data <- data.frame(
#'   SampleID = paste0("S", 1:20),
#'   Sand = rnorm(20, 45, 10),
#'   Silt = rnorm(20, 30, 5),
#'   Clay = rnorm(20, 25, 5),
#'   pH = rnorm(20, 6.5, 0.5),
#'   OM = rnorm(20, 3, 0.5)
#' )
#'
#' # Compute SQI
#' result <- compute_sqi_df(soil_data, id_column = "SampleID")
#'
#' # View results
#' head(result$results)
#' print(result$mds)
#' print(result$weights)
#'
#' @seealso \code{\link{compute_sqi}}, \code{\link{compute_sqi_properties}}
#'
#' @export
compute_sqi_df <- function(df,
                           id_column = NULL,
                           pairwise_df = NULL,
                           directions = NULL,
                           var_threshold = 0.05,
                           loading_threshold = 0.5,
                           ...) {
  # Validate input
  if (!is.data.frame(df)) {
    stop("df must be a data frame")
  }

  # Preserve ID column if specified
  id_data <- NULL
  exclude_cols <- NULL
  if (!is.null(id_column)) {
    if (!id_column %in% names(df)) {
      stop("ID column '", id_column, "' not found in data")
    }
    id_data <- df[[id_column]]
    exclude_cols <- id_column
  }

  # Standardize numeric columns (excluding ID column)
  data_std <- standardize_numeric(df, exclude = exclude_cols)

  # Perform PCA and select MDS
  pca_result <- pca_select_mds(
    data_std,
    var_threshold = var_threshold,
    loading_threshold = loading_threshold
  )

  mds <- pca_result$mds

  # Check if any indicators were selected
  if (length(mds) == 0) {
    stop("No indicators selected by PCA. Try adjusting thresholds.")
  }

  # Calculate AHP weights
  if (!is.null(pairwise_df)) {
    # Use provided pairwise matrix
    ahp_result <- ahp_weights(pairwise_df, indicators = mds)
    weights <- ahp_result$weights
    CR <- ahp_result$CR
  } else {
    # Use equal weights
    weights <- rep(1 / length(mds), length(mds))
    names(weights) <- mds
    CR <- 0
  }

  # Prepare directions if not provided
  if (is.null(directions)) {
    # Default: all indicators use higher-is-better
    directions <- lapply(mds, function(x) list(type = "higher"))
    names(directions) <- mds
  }

  # Score indicators
  scored_data <- score_indicators(df, mds, directions)

  # Calculate SQI as weighted sum of scored indicators
  scored_cols <- paste0(mds, "_scored")
  sqi_values <- numeric(nrow(scored_data))

  for (i in seq_along(mds)) {
    indicator <- mds[i]
    scored_col <- scored_cols[i]
    weight <- weights[indicator]
    sqi_values <- sqi_values + (weight * scored_data[[scored_col]])
  }

  # Add SQI to results
  scored_data$SQI <- sqi_values

  # Create sqi_result object
  result <- list(
    mds = mds,
    weights = weights,
    CR = CR,
    results = scored_data,
    pca = pca_result$pca,
    loadings = pca_result$loadings,
    var_exp = pca_result$var_exp
  )

  class(result) <- "sqi_result"

  result
}


#' Compute Soil Quality Index with property selection
#'
#' This enhanced workflow function allows explicit property selection and
#' integrates with scoring constructor functions. It validates property
#' selection, subsets the data, and orchestrates the complete SQI calculation
#' pipeline.
#'
#' @param data Data frame containing soil property data with samples in rows
#'   and properties in columns.
#' @param properties Optional character vector of property names to include
#'   in the analysis. If NULL, all numeric columns are used automatically.
#' @param id_column Optional character string specifying the name of the ID
#'   column to preserve in the output. If NULL, no ID column is preserved.
#' @param pairwise_matrix Optional pairwise comparison matrix (as matrix or
#'   data frame). If NULL, equal weights are used for all indicators.
#' @param scoring_rules Optional named list of scoring_rule objects created
#'   with constructor functions (higher_better, lower_better, optimum_range,
#'   threshold_scoring). If NULL, all indicators use higher-is-better scoring.
#' @param var_threshold Numeric value for PCA variance threshold (default 0.05).
#' @param loading_threshold Numeric value for PCA loading threshold (default 0.5).
#' @param ... Additional arguments (currently unused).
#'
#' @return An object of class "sqi_result" containing:
#'   \describe{
#'     \item{mds}{Character vector of selected MDS indicators}
#'     \item{weights}{Named numeric vector of AHP weights}
#'     \item{CR}{Consistency Ratio from AHP}
#'     \item{results}{Data frame with original data, scored indicators, and SQI}
#'     \item{pca}{PCA object from stats::prcomp}
#'     \item{loadings}{Matrix of variable loadings}
#'     \item{var_exp}{Numeric vector of variance explained by each PC}
#'   }
#'
#' @details
#' The function performs the following steps:
#' \enumerate{
#'   \item Validate that all specified properties exist in data
#'   \item Subset data to selected properties plus ID column
#'   \item Convert scoring_rule objects to directions list
#'   \item Call compute_sqi_df() to perform the analysis
#' }
#'
#' If properties is NULL, the function automatically detects and uses all
#' numeric columns in the data.
#'
#' @examples
#' # Create example data
#' soil_data <- data.frame(
#'   SampleID = paste0("S", 1:20),
#'   Sand = rnorm(20, 45, 10),
#'   Silt = rnorm(20, 30, 5),
#'   Clay = rnorm(20, 25, 5),
#'   pH = rnorm(20, 6.5, 0.5),
#'   OM = rnorm(20, 3, 0.5),
#'   BD = rnorm(20, 1.4, 0.1)
#' )
#'
#' # Select specific properties
#' result <- compute_sqi_properties(
#'   data = soil_data,
#'   properties = c("pH", "OM", "BD"),
#'   id_column = "SampleID"
#' )
#'
#' # With custom scoring rules
#' rules <- list(
#'   pH = optimum_range(optimal = 7, tolerance = 1.5),
#'   OM = higher_better(),
#'   BD = lower_better()
#' )
#' result <- compute_sqi_properties(
#'   data = soil_data,
#'   properties = c("pH", "OM", "BD"),
#'   id_column = "SampleID",
#'   scoring_rules = rules
#' )
#'
#' # Use standard scoring rules for a property set
#' result <- compute_sqi_properties(
#'   data = soil_data,
#'   properties = soil_property_sets$basic,
#'   id_column = "SampleID",
#'   scoring_rules = standard_scoring_rules("basic")
#' )
#'
#' @seealso \code{\link{compute_sqi}}, \code{\link{compute_sqi_df}},
#'   \code{\link{higher_better}}, \code{\link{lower_better}},
#'   \code{\link{optimum_range}}, \code{\link{threshold_scoring}},
#'   \code{\link{standard_scoring_rules}}
#'
#' @export
compute_sqi_properties <- function(data,
                                   properties = NULL,
                                   id_column = NULL,
                                   pairwise_matrix = NULL,
                                   scoring_rules = NULL,
                                   var_threshold = 0.05,
                                   loading_threshold = 0.5,
                                   ...) {
  # Validate input
  if (!is.data.frame(data)) {
    stop("data must be a data frame")
  }

  # Handle property selection
  if (is.null(properties)) {
    # Auto-detect numeric columns
    numeric_cols <- sapply(data, is.numeric)
    properties <- names(data)[numeric_cols]

    # Remove ID column from properties if specified
    if (!is.null(id_column) && id_column %in% properties) {
      properties <- setdiff(properties, id_column)
    }

    if (length(properties) == 0) {
      stop("No numeric columns found in data for analysis")
    }
  } else {
    # Validate that all specified properties exist
    missing_props <- setdiff(properties, names(data))
    if (length(missing_props) > 0) {
      stop("Properties not found in data: ",
           paste(missing_props, collapse = ", "))
    }
  }

  # Subset data to selected properties plus ID column
  if (!is.null(id_column)) {
    if (!id_column %in% names(data)) {
      stop("ID column '", id_column, "' not found in data")
    }
    subset_cols <- c(id_column, properties)
  } else {
    subset_cols <- properties
  }

  data_subset <- data[, subset_cols, drop = FALSE]

  # Convert scoring_rule objects to directions list if provided
  directions <- NULL
  if (!is.null(scoring_rules)) {
    # Validate that scoring_rules is a named list
    if (!is.list(scoring_rules) || is.null(names(scoring_rules))) {
      stop("scoring_rules must be a named list")
    }

    # Convert each scoring_rule to a direction specification
    directions <- lapply(scoring_rules, function(rule) {
      if (!inherits(rule, "scoring_rule")) {
        stop("All elements in scoring_rules must be scoring_rule objects")
      }

      # Extract the direction specification from the rule
      # The rule already has the correct structure (type, parameters)
      as.list(rule)
    })
  }

  # Call compute_sqi_df with the subset data
  result <- compute_sqi_df(
    df = data_subset,
    id_column = id_column,
    pairwise_df = pairwise_matrix,
    directions = directions,
    var_threshold = var_threshold,
    loading_threshold = loading_threshold,
    ...
  )

  result
}

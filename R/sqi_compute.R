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
#' @param method Aggregation method. \code{"weighted"} (the default, and the
#'   historical behaviour) computes the weighted sum of scored indicators.
#'   \code{"area"} computes the area of the radar diagram they trace, which
#'   ignores weights entirely -- see \code{\link{sqi_area}}.
#' @param reference Optional named numeric vector of reference scores for the
#'   MDS indicators, used only when \code{method = "area"}. When supplied, the
#'   SQI is reported as a ratio against this non-degraded reference soil,
#'   which is what makes area-based values comparable across studies. Names
#'   must cover every selected MDS indicator.
#' @param select Indicator selection strategy.
#'   \describe{
#'     \item{\code{"pca"}}{The default, and the historical behaviour: a
#'       Minimum Data Set via \code{\link{pca_select_mds}}, selecting on
#'       variance.}
#'     \item{\code{"network"}}{Correlation-network selection via
#'       \code{\link{na_select_mds}}, selecting on centrality. Its
#'       centrality-derived weights are used unless \code{pairwise_df} is
#'       supplied. Requires the suggested package \pkg{igraph}.}
#'     \item{\code{"none"}}{No selection: every numeric indicator is used, the
#'       "total data set" (TDS) index that \code{\link{sqi_validate}} measures
#'       fidelity against.}
#'   }
#'   PCA is run and reported in all three cases.
#' @param network_args A named list of arguments forwarded to
#'   \code{\link{na_select_mds}} when \code{select = "network"}, for example
#'   \code{list(r_min = 0.5, component = "all")}. Ignored otherwise.
#' @param ... Additional arguments (currently unused).
#'
#' @return An object of class "sqi_result" containing:
#'   \describe{
#'     \item{mds}{Character vector of selected MDS indicators}
#'     \item{weights}{Named numeric vector of AHP weights. Still reported when
#'       \code{method = "area"}, but not used in the aggregation.}
#'     \item{CR}{Consistency Ratio from AHP}
#'     \item{results}{Data frame with original data, scored indicators, and SQI}
#'     \item{pca}{PCA object from stats::prcomp}
#'     \item{loadings}{Matrix of variable loadings}
#'     \item{var_exp}{Numeric vector of variance explained by each PC}
#'     \item{method}{The aggregation method used}
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
#'   \item Aggregate: weighted sum of (weight * score), or radar-diagram area
#' }
#'
#' @section Do not build an index from predicted properties:
#' If your inputs are \strong{predictions} -- soil properties inferred from
#' spectra, remote sensing or a digital soil map -- computing an index from
#' them is far less reliable than the individual predictions suggest, because
#' the errors compound through the scoring and aggregation.
#'
#' Chaudhry et al. (2024) measured this directly. On the same spectra, with
#' property models that were individually acceptable (Cubist R-squared 0.35 to
#' 0.93), computing the SQI from predicted properties gave
#' \strong{R-squared 0.23}, while predicting the index \strong{directly} from
#' the same spectra gave \strong{R-squared 0.90}.
#'
#' If you have measured properties, use them. If you only have predictions and
#' you want an index, train a model on the index itself rather than assembling
#' one from predicted parts.
#'
#' \strong{On \code{method = "area"}.} The area route is weight-free, which
#' sidesteps the most contested step in the pipeline. But an absolute area
#' (\code{reference = NULL}) is standardised against nothing but your own
#' sample and is not comparable to any other study; the comparability people
#' cite comes from taking the \emph{ratio} against a reference soil, not from
#' the formula. Weights are still computed and returned so that the two
#' methods can be compared on the same object, but they do not enter the
#' area calculation.
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
                           method = c("weighted", "area"),
                           reference = NULL,
                           select = c("pca", "none", "network"),
                           network_args = list(),
                           ...) {
  method <- match.arg(method)
  select <- match.arg(select)

  # Validate input
  if (!is.data.frame(df)) {
    stop("df must be a data frame")
  }

  if (!is.null(reference) && method != "area") {
    warning("`reference` is only used when method = \"area\"; ignoring it.")
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

  # PCA is always run, because its loadings and variance decomposition are
  # reported regardless of whether they drive the selection.
  pca_result <- pca_select_mds(
    data_std,
    var_threshold = var_threshold,
    loading_threshold = loading_threshold
  )

  network_result <- NULL

  if (select == "pca") {
    mds <- pca_result$mds

    # Check if any indicators were selected
    if (length(mds) == 0) {
      stop("No indicators selected by PCA. Try adjusting thresholds.")
    }
  } else if (select == "network") {
    # Centrality-based selection. Spearman correlation is rank-based, so the
    # unstandardised data is passed deliberately -- standardising would change
    # nothing and would only obscure that.
    indicator_df <- df[, setdiff(names(df), id_column), drop = FALSE]
    network_result <- do.call(na_select_mds,
                              c(list(indicator_df), network_args))
    mds <- network_result$mds
  } else {
    # Total data set: every numeric indicator, no selection step. This is what
    # sqi_validate()'s fidelity metric compares an MDS index against.
    numeric_cols <- vapply(df, is.numeric, logical(1))
    mds <- setdiff(names(df)[numeric_cols], id_column)

    if (length(mds) == 0) {
      stop("No numeric indicator columns found in df")
    }
  }

  # Calculate AHP weights
  if (!is.null(pairwise_df)) {
    # Use provided pairwise matrix
    ahp_result <- ahp_weights(pairwise_df, indicators = mds)
    weights <- ahp_result$weights
    CR <- ahp_result$CR
  } else if (!is.null(network_result)) {
    # Centrality weights come free with the network route, so an explicit
    # pairwise matrix is the only thing that should override them.
    weights <- network_result$weights[mds]
    CR <- 0
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

  # Aggregate the scored indicators into the index
  scored_cols <- paste0(mds, "_scored")

  if (method == "weighted") {
    # Weighted additive: sum of (weight * score)
    sqi_values <- numeric(nrow(scored_data))

    for (i in seq_along(mds)) {
      indicator <- mds[i]
      scored_col <- scored_cols[i]
      weight <- weights[indicator]
      sqi_values <- sqi_values + (weight * scored_data[[scored_col]])
    }
  } else {
    # Area of the radar diagram. Weight-free by construction; see sqi_area().
    if (length(mds) < 3) {
      stop("The area method needs at least 3 MDS indicators to describe a ",
           "polygon, but PCA selected ", length(mds), ". Use ",
           "method = \"weighted\", or relax var_threshold/loading_threshold ",
           "to select more indicators.")
    }

    ref_vector <- NULL
    if (!is.null(reference)) {
      if (is.null(names(reference))) {
        stop("`reference` must be a named numeric vector so that its values ",
             "can be matched to the selected MDS indicators (",
             paste(mds, collapse = ", "), ").")
      }

      missing_ref <- setdiff(mds, names(reference))
      if (length(missing_ref) > 0) {
        stop("`reference` is missing values for these selected MDS ",
             "indicators: ", paste(missing_ref, collapse = ", "))
      }

      # Order the reference to match the MDS so the two vectors line up.
      ref_vector <- unname(reference[mds])
    }

    sqi_values <- apply(
      scored_data[, scored_cols, drop = FALSE],
      MARGIN = 1,
      FUN = function(row) sqi_area(as.numeric(row), reference = ref_vector)
    )
    sqi_values <- unname(sqi_values)
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
    var_exp = pca_result$var_exp,
    method = method,
    select = select,
    network = network_result
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
#' @param ... Additional arguments passed to \code{\link{compute_sqi_df}},
#'   notably \code{method} to choose between weighted and area aggregation,
#'   and \code{reference} to report the area as a ratio against a
#'   non-degraded reference soil.
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
#' # Use standard scoring rules for available properties
#' result <- compute_sqi_properties(
#'   data = soil_data,
#'   properties = c("pH", "OM"),
#'   id_column = "SampleID",
#'   scoring_rules = standard_scoring_rules(c("pH", "OM"))
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

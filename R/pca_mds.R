#' Select Minimum Data Set (MDS) Using PCA
#'
#' Performs Principal Component Analysis (PCA) on soil property data and
#' selects a minimum data set (MDS) of indicators based on variance and
#' loading thresholds. This function implements the PCA-based MDS selection
#' methodology commonly used in soil quality assessment.
#'
#' @param data A data frame containing standardized soil property measurements.
#'   All columns should be numeric. It is recommended to standardize the data
#'   using \code{\link{standardize_numeric}} before applying PCA.
#' @param var_threshold Numeric value specifying the minimum proportion of
#'   variance a principal component must explain to be retained. Components
#'   with variance below this threshold are excluded from MDS selection.
#'   Default is 0.05 (5\%).
#' @param loading_threshold Numeric value specifying the minimum absolute
#'   loading value for a variable to be considered for selection within a
#'   principal component. Variables with absolute loadings below this threshold
#'   are not selected. Default is 0.5.
#'
#' @return A list with the following components:
#'   \describe{
#'     \item{mds}{Character vector of selected variable names representing
#'       the minimum data set.}
#'     \item{pca}{The PCA object returned by \code{stats::prcomp}, containing
#'       the full PCA results including rotation matrix, scores, and other
#'       components.}
#'     \item{loadings}{Numeric matrix of variable loadings (rotation matrix)
#'       for all principal components.}
#'     \item{var_exp}{Numeric vector containing the proportion of variance
#'       explained by each principal component.}
#'   }
#'
#' @details
#' The MDS selection algorithm follows these steps:
#' \enumerate{
#'   \item Perform PCA using \code{stats::prcomp} with scaling disabled
#'     (data should be pre-standardized).
#'   \item Calculate the proportion of variance explained by each PC.
#'   \item Identify PCs that explain variance greater than \code{var_threshold}.
#'   \item For each retained PC, identify the variable with the maximum
#'     absolute loading that exceeds \code{loading_threshold}.
#'   \item Return the unique set of selected variables as the MDS.
#' }
#'
#' If no variables meet the selection criteria, an empty character vector
#' is returned for the MDS component.
#'
#' @examples
#' # Create example soil data
#' soil_data <- data.frame(
#'   Sand = c(45, 50, 42, 48, 52, 38, 44, 49),
#'   Silt = c(30, 28, 35, 32, 25, 40, 33, 29),
#'   Clay = c(25, 22, 23, 20, 23, 22, 23, 22),
#'   pH = c(6.5, 7.0, 6.8, 7.2, 6.9, 6.7, 7.1, 6.6),
#'   OM = c(3.2, 2.8, 3.5, 3.0, 2.9, 3.3, 3.1, 3.4)
#' )
#'
#' # Standardize the data first
#' soil_std <- standardize_numeric(soil_data)
#'
#' # Select MDS using PCA
#' result <- pca_select_mds(soil_std)
#'
#' # View selected indicators
#' print(result$mds)
#'
#' # View variance explained
#' print(result$var_exp)
#'
#' # Use custom thresholds
#' result2 <- pca_select_mds(soil_std,
#'                           var_threshold = 0.10,
#'                           loading_threshold = 0.6)
#'
#' @seealso \code{\link{standardize_numeric}} for data standardization
#'
#' @export
pca_select_mds <- function(data,
                           var_threshold = 0.05,
                           loading_threshold = 0.5) {
  # Input validation
  if (!is.data.frame(data)) {
    stop("data must be a data frame")
  }

  # Check for numeric columns
  numeric_cols <- sapply(data, is.numeric)
  if (!any(numeric_cols)) {
    stop("data must contain at least one numeric column")
  }

  # Extract only numeric columns
  numeric_data <- data[, numeric_cols, drop = FALSE]

  # Check for sufficient data
  if (ncol(numeric_data) < 2) {
    stop("At least 2 numeric columns required for PCA")
  }

  if (nrow(numeric_data) < 3) {
    stop("At least 3 observations required for PCA")
  }

  # Check for all-NA columns
  all_na_cols <- sapply(numeric_data, function(x) all(is.na(x)))
  if (any(all_na_cols)) {
    warning("Removing columns with all NA values: ",
            paste(names(numeric_data)[all_na_cols], collapse = ", "))
    numeric_data <- numeric_data[, !all_na_cols, drop = FALSE]
  }

  # Remove rows with any NA values for PCA
  complete_cases <- complete.cases(numeric_data)
  if (!any(complete_cases)) {
    stop("No complete cases available for PCA after removing NA values")
  }

  if (sum(complete_cases) < nrow(numeric_data)) {
    warning("Removing ", nrow(numeric_data) - sum(complete_cases),
            " rows with NA values for PCA")
  }

  numeric_data <- numeric_data[complete_cases, , drop = FALSE]

  # Validate thresholds
  if (!is.numeric(var_threshold) || length(var_threshold) != 1 ||
      var_threshold < 0 || var_threshold > 1) {
    stop("var_threshold must be a single numeric value between 0 and 1")
  }

  if (!is.numeric(loading_threshold) || length(loading_threshold) != 1 ||
      loading_threshold < 0 || loading_threshold > 1) {
    stop("loading_threshold must be a single numeric value between 0 and 1")
  }

  # Perform PCA (scale = FALSE because data should be pre-standardized)
  pca_result <- stats::prcomp(numeric_data, scale. = FALSE)

  # Extract loadings (rotation matrix)
  loadings <- pca_result$rotation

  # Calculate variance explained by each PC
  variance <- pca_result$sdev^2
  var_exp <- variance / sum(variance)

  # Identify PCs that meet variance threshold
  retained_pcs <- which(var_exp > var_threshold)

  # Select variables with maximum loadings per retained PC
  mds <- character(0)

  if (length(retained_pcs) > 0) {
    for (pc_idx in retained_pcs) {
      # Get loadings for this PC
      pc_loadings <- loadings[, pc_idx]

      # Find variable with maximum absolute loading
      abs_loadings <- abs(pc_loadings)
      max_idx <- which.max(abs_loadings)
      max_loading <- abs_loadings[max_idx]

      # Check if it exceeds loading threshold
      if (max_loading > loading_threshold) {
        var_name <- names(pc_loadings)[max_idx]
        # Add to MDS if not already present (ensure uniqueness)
        if (!(var_name %in% mds)) {
          mds <- c(mds, var_name)
        }
      }
    }
  }

  # Return results as a list
  list(
    mds = mds,
    pca = pca_result,
    loadings = loadings,
    var_exp = var_exp
  )
}

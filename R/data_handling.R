#' Read Soil Data from CSV File
#'
#' Reads soil property data from a CSV file with automatic encoding handling.
#' This function is designed to handle various CSV formats commonly used in
#' soil science research.
#'
#' @param path Character string specifying the path to the CSV file.
#'   The file should contain soil property measurements with samples in rows
#'   and properties in columns.
#'
#' @return A data frame containing the soil data from the CSV file.
#'
#' @examples
#' \dontrun{
#' # Read soil data from a CSV file
#' soil_data <- read_soil_csv("path/to/soil_data.csv")
#' 
#' # View the structure
#' str(soil_data)
#' }
#'
#' @export
read_soil_csv <- function(path) {
  # Validate input
  if (!is.character(path) || length(path) != 1) {
    stop("path must be a single character string")
  }
  
  if (!file.exists(path)) {
    stop("File not found: ", path)
  }
  
  # Read CSV with encoding handling
  # Try UTF-8 first, then fall back to Latin1 if needed
  data <- tryCatch({
    utils::read.csv(path, stringsAsFactors = FALSE, fileEncoding = "UTF-8")
  }, error = function(e) {
    tryCatch({
      utils::read.csv(path, stringsAsFactors = FALSE, fileEncoding = "Latin1")
    }, error = function(e2) {
      stop("Failed to read CSV file: ", e2$message)
    })
  })
  
  return(data)
}


#' Convert Values to Numeric
#'
#' Safely converts a vector to numeric type, returning NA for values that
#' cannot be converted. This is a helper function used internally for
#' data preprocessing.
#'
#' @param x A vector of any type to be converted to numeric.
#'
#' @return A numeric vector with the same length as the input. Values that
#'   cannot be converted to numeric are returned as NA.
#'
#' @examples
#' # Convert character numbers to numeric
#' to_numeric(c("1.5", "2.3", "3.7"))
#' 
#' # Non-numeric values become NA
#' to_numeric(c("1.5", "text", "3.7"))
#' 
#' # Already numeric values pass through
#' to_numeric(c(1.5, 2.3, 3.7))
#'
#' @export
to_numeric <- function(x) {
  suppressWarnings(as.numeric(x))
}


#' Standardize Numeric Columns
#'
#' Applies z-score standardization to numeric columns in a data frame.
#' Non-numeric columns are preserved unchanged. This function is useful
#' for preparing soil property data for multivariate analysis such as PCA.
#'
#' @param df A data frame containing soil property data.
#' @param exclude Optional character vector of column names to exclude from
#'   standardization. These columns will be preserved in their original form.
#'   Default is NULL (no exclusions).
#'
#' @return A data frame with the same structure as the input, where numeric
#'   columns (except those excluded) have been standardized to have mean = 0
#'   and standard deviation = 1. Non-numeric columns and excluded columns
#'   are returned unchanged.
#'
#' @details
#' Z-score standardization is calculated as: (x - mean(x)) / sd(x)
#' 
#' Columns with zero variance (sd = 0) are left unchanged to avoid division
#' by zero. NA values are preserved in their positions.
#'
#' @examples
#' # Create example soil data
#' soil_data <- data.frame(
#'   SampleID = c("S1", "S2", "S3", "S4"),
#'   pH = c(6.5, 7.0, 6.8, 7.2),
#'   OM = c(3.2, 2.8, 3.5, 3.0),
#'   Sand = c(45, 50, 42, 48)
#' )
#' 
#' # Standardize all numeric columns, preserve SampleID
#' standardized <- standardize_numeric(soil_data, exclude = "SampleID")
#' 
#' # Verify standardization
#' colMeans(standardized[, c("pH", "OM", "Sand")], na.rm = TRUE)
#' apply(standardized[, c("pH", "OM", "Sand")], 2, sd, na.rm = TRUE)
#'
#' @export
standardize_numeric <- function(df, exclude = NULL) {
  # Validate input
  if (!is.data.frame(df)) {
    stop("df must be a data frame")
  }
  
  if (!is.null(exclude) && !is.character(exclude)) {
    stop("exclude must be NULL or a character vector")
  }
  
  # Check if excluded columns exist
  if (!is.null(exclude)) {
    missing_cols <- setdiff(exclude, names(df))
    if (length(missing_cols) > 0) {
      warning("Excluded columns not found in data: ", 
              paste(missing_cols, collapse = ", "))
    }
  }
  
  # Create a copy of the data frame
  result <- df
  
  # Identify numeric columns
  numeric_cols <- sapply(df, is.numeric)
  
  # Remove excluded columns from standardization
  if (!is.null(exclude)) {
    exclude_mask <- names(df) %in% exclude
    numeric_cols <- numeric_cols & !exclude_mask
  }
  
  # Standardize each numeric column
  for (col_name in names(df)[numeric_cols]) {
    x <- df[[col_name]]
    
    # Skip if all NA
    if (all(is.na(x))) {
      next
    }
    
    # Calculate mean and sd (excluding NA)
    mean_x <- mean(x, na.rm = TRUE)
    sd_x <- sd(x, na.rm = TRUE)
    
    # Only standardize if sd > 0 (avoid division by zero)
    if (!is.na(sd_x) && sd_x > 0) {
      result[[col_name]] <- (x - mean_x) / sd_x
    }
  }
  
  return(result)
}

#' Calculate AHP weights from pairwise comparison matrix
#'
#' This function calculates indicator weights using the Analytic Hierarchy Process (AHP)
#' method based on a pairwise comparison matrix. It computes weights using eigenvalue
#' decomposition and calculates the Consistency Ratio (CR) to assess the logical
#' consistency of the judgments.
#'
#' @param pairwise A square numeric matrix of pairwise comparisons where element [i,j]
#'   represents the relative importance of indicator i compared to indicator j.
#'   The matrix must be reciprocal (A[i,j] = 1/A[j,i]) with diagonal values equal to 1.
#' @param indicators Optional character vector of indicator names. If NULL, uses
#'   row names from the pairwise matrix or generates default names.
#'
#' @return A list with the following components:
#'   \item{weights}{Named numeric vector of normalized weights summing to 1}
#'   \item{CR}{Consistency Ratio, a measure of logical consistency (should be < 0.1)}
#'   \item{lambda_max}{Maximum eigenvalue of the pairwise matrix}
#'
#' @details
#' The AHP method uses eigenvalue decomposition to derive weights from pairwise
#' comparisons. The Consistency Ratio (CR) is calculated as:
#' \deqn{CR = CI / RI}
#' where CI (Consistency Index) = (lambda_max - n) / (n - 1) and RI is the
#' Random Consistency Index that depends on matrix size.
#'
#' A CR value less than 0.1 indicates acceptable consistency. Values exceeding
#' 0.1 suggest that the pairwise judgments may be inconsistent and should be revised.
#'
#' @examples
#' # Create a 3x3 pairwise comparison matrix
#' pairwise <- matrix(c(
#'   1,   3,   5,
#'   1/3, 1,   2,
#'   1/5, 1/2, 1
#' ), nrow = 3, byrow = TRUE)
#'
#' # Calculate weights
#' result <- ahp_weights(pairwise, indicators = c("pH", "OM", "P"))
#' print(result$weights)
#' print(result$CR)
#'
#' @export
ahp_weights <- function(pairwise, indicators = NULL) {
  # Validate input matrix
  if (!is.matrix(pairwise) && !is.data.frame(pairwise)) {
    stop("pairwise must be a matrix or data frame")
  }
  
  # Convert to matrix if data frame
  if (is.data.frame(pairwise)) {
    pairwise <- as.matrix(pairwise)
  }
  
  # Check if matrix is square
  if (nrow(pairwise) != ncol(pairwise)) {
    stop("Pairwise matrix must be square")
  }
  
  n <- nrow(pairwise)
  
  if (n < 2) {
    stop("Pairwise matrix must have at least 2 indicators")
  }
  
  # Check diagonal values
  if (!all(abs(diag(pairwise) - 1) < 1e-6)) {
    stop("Diagonal values must be 1")
  }
  
  # Check reciprocal property
  for (i in 1:n) {
    for (j in 1:n) {
      if (i != j && abs(pairwise[i, j] * pairwise[j, i] - 1) > 1e-6) {
        stop("Matrix must be reciprocal: A[i,j] = 1/A[j,i]")
      }
    }
  }
  
  # Calculate weights using eigenvalue method
  # The principal eigenvector corresponds to the largest eigenvalue
  eigen_result <- eigen(pairwise)
  
  # Get the eigenvector corresponding to the largest eigenvalue
  max_eigen_idx <- which.max(Re(eigen_result$values))
  lambda_max <- Re(eigen_result$values[max_eigen_idx])
  principal_eigenvector <- Re(eigen_result$vectors[, max_eigen_idx])
  
  # Normalize to get weights (sum to 1)
  weights <- abs(principal_eigenvector) / sum(abs(principal_eigenvector))
  
  # Calculate Consistency Index (CI)
  CI <- (lambda_max - n) / (n - 1)
  
  # Random Consistency Index (RI) values for different matrix sizes
  # Based on Saaty's research
  RI_values <- c(0, 0, 0.58, 0.90, 1.12, 1.24, 1.32, 1.41, 1.45, 1.49, 1.51)
  
  # Get RI for current matrix size
  if (n <= length(RI_values)) {
    RI <- RI_values[n]
  } else {
    # For larger matrices, use approximation
    RI <- 1.98 * (n - 2) / n
  }
  
  # Calculate Consistency Ratio (CR)
  CR <- if (RI > 0) CI / RI else 0
  
  # Set indicator names
  if (is.null(indicators)) {
    if (!is.null(rownames(pairwise))) {
      indicators <- rownames(pairwise)
    } else {
      indicators <- paste0("Indicator", 1:n)
    }
  } else {
    if (length(indicators) != n) {
      stop("Length of indicators must match matrix dimensions")
    }
  }
  
  names(weights) <- indicators
  
  # Warn if CR exceeds threshold
  if (CR > 0.1) {
    warning("Consistency Ratio (", round(CR, 4), 
            ") exceeds 0.1. Consider revising judgments.")
  }
  
  # Return results
  list(
    weights = weights,
    CR = CR,
    lambda_max = lambda_max
  )
}


#' Convert importance ratios to Saaty pairwise comparison matrix
#'
#' This helper function converts a vector of importance ratios into a pairwise
#' comparison matrix following the Saaty scale (1-9). The ratios represent the
#' relative importance of each indicator compared to a baseline.
#'
#' @param ratios Numeric vector of importance ratios. Each value represents
#'   how many times more important an indicator is compared to a baseline.
#'   Values should be positive numbers.
#'
#' @return A square numeric matrix of pairwise comparisons where element [i,j]
#'   represents the relative importance of indicator i compared to indicator j.
#'   The matrix is reciprocal with diagonal values equal to 1.
#'
#' @details
#' The function constructs a pairwise comparison matrix from importance ratios
#' by calculating the ratio between each pair of indicators. For indicators with
#' ratios r_i and r_j, the pairwise comparison is r_i / r_j.
#'
#' The Saaty scale typically uses values from 1/9 to 9, where:
#' \itemize{
#'   \item 1 = Equal importance
#'   \item 3 = Moderate importance
#'   \item 5 = Strong importance
#'   \item 7 = Very strong importance
#'   \item 9 = Extreme importance
#'   \item 2, 4, 6, 8 = Intermediate values
#' }
#'
#' @examples
#' # Three indicators with importance ratios 5:3:1
#' ratios <- c(5, 3, 1)
#' pairwise <- ratio_to_saaty(ratios)
#' print(pairwise)
#'
#' # Calculate weights from the matrix
#' result <- ahp_weights(pairwise, indicators = c("pH", "OM", "P"))
#'
#' @export
ratio_to_saaty <- function(ratios) {
  # Validate input
  if (!is.numeric(ratios)) {
    stop("ratios must be a numeric vector")
  }
  
  if (any(ratios <= 0)) {
    stop("All ratios must be positive")
  }
  
  if (length(ratios) < 2) {
    stop("ratios must have at least 2 elements")
  }
  
  n <- length(ratios)
  
  # Create pairwise comparison matrix
  pairwise <- matrix(0, nrow = n, ncol = n)
  
  for (i in 1:n) {
    for (j in 1:n) {
      if (i == j) {
        pairwise[i, j] <- 1
      } else {
        # Pairwise comparison is the ratio of the two importance values
        pairwise[i, j] <- ratios[i] / ratios[j]
      }
    }
  }
  
  # Set names if ratios has names
  if (!is.null(names(ratios))) {
    rownames(pairwise) <- names(ratios)
    colnames(pairwise) <- names(ratios)
  }
  
  return(pairwise)
}


#' Create AHP pairwise comparison matrix interactively
#'
#' This function creates an AHP pairwise comparison matrix through interactive
#' prompts or from a provided matrix. In interactive mode, it guides the user
#' through pairwise comparisons of all indicators, validates inputs, calculates
#' weights, and returns a structured ahp_matrix object.
#'
#' @param indicators Character vector of indicator names to be compared.
#' @param mode Character string specifying the mode: "interactive" for guided
#'   prompts (default) or "matrix" to provide a pre-built matrix.
#' @param pairwise Optional pre-built pairwise comparison matrix (only used when
#'   mode = "matrix"). Must be a square matrix with dimensions matching the
#'   number of indicators.
#'
#' @return An object of class "ahp_matrix" containing:
#'   \item{indicators}{Character vector of indicator names}
#'   \item{matrix}{Numeric matrix of pairwise comparisons}
#'   \item{weights}{Named numeric vector of normalized weights}
#'   \item{CR}{Consistency Ratio}
#'   \item{lambda_max}{Maximum eigenvalue}
#'
#' @details
#' In interactive mode, the function displays the Saaty scale and prompts for
#' pairwise comparisons between all indicator pairs. The Saaty scale is:
#' \itemize{
#'   \item 1 = Equal importance
#'   \item 3 = Moderate importance of first over second
#'   \item 5 = Strong importance of first over second
#'   \item 7 = Very strong importance of first over second
#'   \item 9 = Extreme importance of first over second
#'   \item 2, 4, 6, 8 = Intermediate values
#'   \item 1/3, 1/5, 1/7, 1/9 = Reciprocal values (second more important)
#' }
#'
#' Users can enter values as decimals (e.g., 0.333) or fractions (e.g., "1/3").
#' The function validates that all inputs are within the valid range (1/9 to 9).
#'
#' After collecting all comparisons, the function calculates weights using
#' eigenvalue decomposition and computes the Consistency Ratio (CR). If CR > 0.1,
#' a warning is displayed indicating inconsistent judgments.
#'
#' @examples
#' \dontrun{
#' # Interactive mode - prompts user for comparisons
#' ahp_result <- create_ahp_matrix(c("pH", "OM", "P"))
#' print(ahp_result)
#' }
#'
#' # Matrix mode - provide pre-built matrix
#' pairwise <- matrix(c(
#'   1,   3,   5,
#'   1/3, 1,   2,
#'   1/5, 1/2, 1
#' ), nrow = 3, byrow = TRUE)
#' ahp_result <- create_ahp_matrix(
#'   indicators = c("pH", "OM", "P"),
#'   mode = "matrix",
#'   pairwise = pairwise
#' )
#' print(ahp_result)
#'
#' @seealso \code{\link{ahp_weights}}, \code{\link{ratio_to_saaty}}
#'
#' @export
create_ahp_matrix <- function(indicators, mode = "interactive", pairwise = NULL) {
  # Validate indicators
  if (!is.character(indicators)) {
    stop("indicators must be a character vector")
  }
  
  if (length(indicators) < 2) {
    stop("At least 2 indicators are required")
  }
  
  n <- length(indicators)
  
  # Validate mode
  mode <- match.arg(mode, c("interactive", "matrix"))
  
  if (mode == "matrix") {
    # Matrix mode - use provided matrix
    if (is.null(pairwise)) {
      stop("pairwise matrix must be provided when mode = 'matrix'")
    }
    
    if (!is.matrix(pairwise) && !is.data.frame(pairwise)) {
      stop("pairwise must be a matrix or data frame")
    }
    
    if (is.data.frame(pairwise)) {
      pairwise <- as.matrix(pairwise)
    }
    
    if (nrow(pairwise) != n || ncol(pairwise) != n) {
      stop("pairwise matrix dimensions must match number of indicators")
    }
    
    # Set row and column names
    rownames(pairwise) <- indicators
    colnames(pairwise) <- indicators
    
  } else {
    # Interactive mode - collect pairwise comparisons
    cat("\n=== AHP Pairwise Comparison ===\n")
    cat("\nSaaty Scale:\n")
    cat("  1 = Equal importance\n")
    cat("  3 = Moderate importance\n")
    cat("  5 = Strong importance\n")
    cat("  7 = Very strong importance\n")
    cat("  9 = Extreme importance\n")
    cat("  2, 4, 6, 8 = Intermediate values\n")
    cat("  Use reciprocals (e.g., 1/3, 0.333) when second indicator is more important\n\n")
    
    # Initialize matrix
    pairwise <- matrix(1, nrow = n, ncol = n)
    rownames(pairwise) <- indicators
    colnames(pairwise) <- indicators
    
    # Collect pairwise comparisons for upper triangle
    for (i in 1:(n - 1)) {
      for (j in (i + 1):n) {
        valid_input <- FALSE
        
        while (!valid_input) {
          cat(sprintf("\nCompare '%s' vs '%s'\n", indicators[i], indicators[j]))
          cat(sprintf("How much more important is '%s' compared to '%s'? ", 
                      indicators[i], indicators[j]))
          
          input <- readline()
          
          # Try to parse input
          value <- tryCatch({
            # Check if input contains "/"
            if (grepl("/", input)) {
              # Parse as fraction
              parts <- strsplit(input, "/")[[1]]
              if (length(parts) == 2) {
                num <- as.numeric(parts[1])
                denom <- as.numeric(parts[2])
                if (!is.na(num) && !is.na(denom) && denom != 0) {
                  num / denom
                } else {
                  NA
                }
              } else {
                NA
              }
            } else {
              # Parse as decimal
              as.numeric(input)
            }
          }, error = function(e) NA)
          
          # Validate value
          if (is.na(value)) {
            cat("Invalid input. Please enter a number or fraction (e.g., 3 or 1/3).\n")
          } else if (value < 1/9 || value > 9) {
            cat("Value must be between 1/9 (0.111) and 9.\n")
          } else {
            pairwise[i, j] <- value
            pairwise[j, i] <- 1 / value
            valid_input <- TRUE
          }
        }
      }
    }
  }
  
  # Calculate weights and consistency
  ahp_result <- ahp_weights(pairwise, indicators)
  
  # Create ahp_matrix object
  result <- list(
    indicators = indicators,
    matrix = pairwise,
    weights = ahp_result$weights,
    CR = ahp_result$CR,
    lambda_max = ahp_result$lambda_max
  )
  
  class(result) <- "ahp_matrix"
  
  return(result)
}


#' Print method for ahp_matrix objects
#'
#' Displays a formatted summary of an AHP pairwise comparison matrix including
#' the matrix itself, calculated weights, and consistency information.
#'
#' @param x An object of class "ahp_matrix" created by \code{\link{create_ahp_matrix}}.
#' @param ... Additional arguments passed to print methods (currently unused).
#'
#' @return Invisibly returns the input object.
#'
#' @details
#' The print method displays:
#' \itemize{
#'   \item The pairwise comparison matrix with indicator names
#'   \item Normalized weights for each indicator
#'   \item Consistency Ratio (CR) with a status indicator
#'   \item Maximum eigenvalue (lambda_max)
#' }
#'
#' The consistency status shows a checkmark (✓) if CR <= 0.1 (acceptable
#' consistency) or an X (✗) if CR > 0.1 (inconsistent judgments).
#'
#' @examples
#' # Create an AHP matrix
#' pairwise <- matrix(c(
#'   1,   3,   5,
#'   1/3, 1,   2,
#'   1/5, 1/2, 1
#' ), nrow = 3, byrow = TRUE)
#' ahp_result <- create_ahp_matrix(
#'   indicators = c("pH", "OM", "P"),
#'   mode = "matrix",
#'   pairwise = pairwise
#' )
#'
#' # Print the result
#' print(ahp_result)
#'
#' @seealso \code{\link{create_ahp_matrix}}, \code{\link{ahp_weights}}
#'
#' @export
print.ahp_matrix <- function(x, ...) {
  cat("\n=== AHP Pairwise Comparison Matrix ===\n\n")
  
  # Print the matrix
  cat("Pairwise Comparison Matrix:\n")
  print(round(x$matrix, 3))
  
  cat("\n")
  
  # Print weights
  cat("Indicator Weights:\n")
  for (i in seq_along(x$weights)) {
    cat(sprintf("  %-15s: %.4f\n", names(x$weights)[i], x$weights[i]))
  }
  
  cat("\n")
  
  # Print consistency information
  cat("Consistency Information:\n")
  cat(sprintf("  Lambda Max: %.4f\n", x$lambda_max))
  cat(sprintf("  Consistency Ratio (CR): %.4f ", x$CR))
  
  # Add status indicator
  if (x$CR <= 0.1) {
    cat("[\U2713 Acceptable]\n")
  } else {
    cat("[\U2717 Inconsistent - Consider revising judgments]\n")
  }
  
  cat("\n")
  
  invisible(x)
}

#' Score indicator with higher-is-better normalization
#'
#' Normalizes values to [0,1] range where higher values indicate better quality.
#' Uses min-max normalization: (x - min) / (max - min).
#'
#' @param x Numeric vector of indicator values
#' @param min_val Minimum value for normalization. If NULL, uses min(x, na.rm = TRUE)
#' @param max_val Maximum value for normalization. If NULL, uses max(x, na.rm = TRUE)
#'
#' @return Numeric vector of scores in [0,1] range
#'
#' @examples
#' # Higher organic matter is better
#' om_values <- c(1.5, 2.0, 2.5, 3.0, 3.5)
#' score_higher_better(om_values)
#'
#' # With custom min/max
#' score_higher_better(om_values, min_val = 1, max_val = 4)
#'
#' @export
score_higher_better <- function(x, min_val = NULL, max_val = NULL) {
  if (is.null(min_val)) {
    min_val <- min(x, na.rm = TRUE)
  }
  if (is.null(max_val)) {
    max_val <- max(x, na.rm = TRUE)
  }
  
  # Handle case where min equals max
  if (min_val == max_val) {
    return(rep(1, length(x)))
  }
  
  # Min-max normalization
  score <- (x - min_val) / (max_val - min_val)
  
  # Ensure values are in [0,1] range
  score[score < 0] <- 0
  score[score > 1] <- 1
  
  return(score)
}

#' Score indicator with lower-is-better normalization
#'
#' Normalizes values to [0,1] range where lower values indicate better quality.
#' Uses inverted min-max normalization: (max - x) / (max - min).
#'
#' @param x Numeric vector of indicator values
#' @param min_val Minimum value for normalization. If NULL, uses min(x, na.rm = TRUE)
#' @param max_val Maximum value for normalization. If NULL, uses max(x, na.rm = TRUE)
#'
#' @return Numeric vector of scores in [0,1] range
#'
#' @examples
#' # Lower bulk density is better
#' bd_values <- c(1.2, 1.3, 1.4, 1.5, 1.6)
#' score_lower_better(bd_values)
#'
#' # With custom min/max
#' score_lower_better(bd_values, min_val = 1.0, max_val = 1.8)
#'
#' @export
score_lower_better <- function(x, min_val = NULL, max_val = NULL) {
  if (is.null(min_val)) {
    min_val <- min(x, na.rm = TRUE)
  }
  if (is.null(max_val)) {
    max_val <- max(x, na.rm = TRUE)
  }
  
  # Handle case where min equals max
  if (min_val == max_val) {
    return(rep(1, length(x)))
  }
  
  # Inverted min-max normalization
  score <- (max_val - x) / (max_val - min_val)
  
  # Ensure values are in [0,1] range
  score[score < 0] <- 0
  score[score > 1] <- 1
  
  return(score)
}

#' Score indicator with optimum range
#'
#' Normalizes values to [0,1] range where values near an optimum are best.
#' Uses linear or quadratic penalty based on distance from optimum.
#'
#' @param x Numeric vector of indicator values
#' @param optimum Optimal value for the indicator
#' @param tol Tolerance around optimum (distance where score reaches 0)
#' @param penalty Type of penalty function: "linear" or "quadratic"
#'
#' @return Numeric vector of scores in [0,1] range
#'
#' @examples
#' # pH optimum around 7
#' ph_values <- c(5.5, 6.0, 6.5, 7.0, 7.5, 8.0, 8.5)
#' score_optimum(ph_values, optimum = 7, tol = 1.5)
#'
#' # With quadratic penalty
#' score_optimum(ph_values, optimum = 7, tol = 1.5, penalty = "quadratic")
#'
#' @export
score_optimum <- function(x, optimum, tol, penalty = "linear") {
  # Calculate distance from optimum
  distance <- abs(x - optimum)
  
  if (penalty == "linear") {
    # Linear penalty: score = 1 - distance/tol
    score <- 1 - (distance / tol)
  } else if (penalty == "quadratic") {
    # Quadratic penalty: score = 1 - (distance/tol)^2
    score <- 1 - (distance / tol)^2
  } else {
    stop("penalty must be 'linear' or 'quadratic'")
  }
  
  # Ensure values are in [0,1] range
  score[score < 0] <- 0
  score[score > 1] <- 1
  
  return(score)
}

#' Score indicator with threshold-based piecewise interpolation
#'
#' Normalizes values to [0,1] range using piecewise linear interpolation
#' between specified threshold-score pairs.
#'
#' @param x Numeric vector of indicator values
#' @param thresholds Numeric vector of threshold values (must be sorted)
#' @param scores Numeric vector of scores corresponding to thresholds
#'
#' @return Numeric vector of scores in [0,1] range
#'
#' @examples
#' # Custom threshold scoring for phosphorus
#' p_values <- c(5, 10, 15, 20, 25, 30, 35)
#' thresholds <- c(0, 10, 20, 30)
#' scores <- c(0, 0.5, 1.0, 1.0)
#' score_threshold(p_values, thresholds, scores)
#'
#' @export
score_threshold <- function(x, thresholds, scores) {
  if (length(thresholds) != length(scores)) {
    stop("thresholds and scores must have the same length")
  }
  
  # Use approx for piecewise linear interpolation
  score <- approx(x = thresholds, y = scores, xout = x, 
                  method = "linear", rule = 2)$y
  
  # Ensure values are in [0,1] range
  score[score < 0] <- 0
  score[score > 1] <- 1
  
  return(score)
}

#' Score multiple indicators using specified scoring functions
#'
#' Applies appropriate scoring functions to each MDS indicator variable
#' based on the directions specification.
#'
#' @param data Data frame containing indicator values
#' @param mds Character vector of MDS indicator names to score
#' @param directions Named list specifying scoring function for each indicator.
#'   Each element should be a list with 'type' and parameters:
#'   - type = "higher": uses score_higher_better()
#'   - type = "lower": uses score_lower_better()
#'   - type = "optimum": uses score_optimum() (requires optimum, tol, penalty)
#'   - type = "threshold": uses score_threshold() (requires thresholds, scores)
#'
#' @return Data frame with original columns plus scored columns (suffixed with "_scored")
#'
#' @examples
#' \dontrun{
#' data <- data.frame(
#'   ID = 1:5,
#'   OM = c(1.5, 2.0, 2.5, 3.0, 3.5),
#'   pH = c(5.5, 6.0, 6.5, 7.0, 7.5),
#'   BD = c(1.2, 1.3, 1.4, 1.5, 1.6)
#' )
#'
#' directions <- list(
#'   OM = list(type = "higher"),
#'   pH = list(type = "optimum", optimum = 7, tol = 1.5, penalty = "linear"),
#'   BD = list(type = "lower")
#' )
#'
#' scored_data <- score_indicators(data, c("OM", "pH", "BD"), directions)
#' }
#'
#' @export
score_indicators <- function(data, mds, directions) {
  # Validate that all MDS variables exist in data
  missing_vars <- setdiff(mds, names(data))
  if (length(missing_vars) > 0) {
    stop("MDS variables not found in data: ", paste(missing_vars, collapse = ", "))
  }
  
  # Create a copy of the data to add scored columns
  result <- data
  
  # Score each MDS indicator
  for (indicator in mds) {
    # Get direction specification for this indicator
    if (is.null(directions[[indicator]])) {
      stop("No scoring direction specified for indicator: ", indicator)
    }
    
    direction <- directions[[indicator]]
    x <- data[[indicator]]
    
    # Apply appropriate scoring function based on type
    scored_col <- paste0(indicator, "_scored")
    
    if (direction$type == "higher") {
      result[[scored_col]] <- score_higher_better(
        x, 
        min_val = direction$min_val,
        max_val = direction$max_val
      )
    } else if (direction$type == "lower") {
      result[[scored_col]] <- score_lower_better(
        x,
        min_val = direction$min_val,
        max_val = direction$max_val
      )
    } else if (direction$type == "optimum") {
      if (is.null(direction$optimum) || is.null(direction$tol)) {
        stop("optimum and tol required for type 'optimum' for indicator: ", indicator)
      }
      result[[scored_col]] <- score_optimum(
        x,
        optimum = direction$optimum,
        tol = direction$tol,
        penalty = direction$penalty %||% "linear"
      )
    } else if (direction$type == "threshold") {
      if (is.null(direction$thresholds) || is.null(direction$scores)) {
        stop("thresholds and scores required for type 'threshold' for indicator: ", indicator)
      }
      result[[scored_col]] <- score_threshold(
        x,
        thresholds = direction$thresholds,
        scores = direction$scores
      )
    } else {
      stop("Invalid scoring type '", direction$type, "' for indicator: ", indicator)
    }
  }
  
  return(result)
}

# Helper function for NULL coalescing
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

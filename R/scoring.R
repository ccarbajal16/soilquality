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
    } else if (direction$type == "sigmoid") {
      result[[scored_col]] <- score_sigmoid(
        x,
        direction = direction$direction %||% "higher",
        x0 = direction$x0,
        b = direction$b %||% 2.5
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

#' Score indicator with a non-linear (sigmoidal) curve
#'
#' Scores an indicator using the sigmoidal curve that dominates the soil
#' quality index literature. Unlike the min-max functions in this package,
#' the curve is anchored on a reference value \code{x0} rather than on the
#' observed extremes, so a sample that happens to contain no degraded soil
#' does not automatically produce a score of 1.
#'
#' @details
#' The scoring function is
#' \deqn{S = \frac{1}{1 + (x / x_0)^b}}
#' where the sign of the exponent encodes the direction:
#' \itemize{
#'   \item \code{direction = "higher"} uses \eqn{-b}, so \eqn{S \to 1} as
#'     \eqn{x \gg x_0} and \eqn{S \to 0} as \eqn{x \to 0}
#'   \item \code{direction = "lower"} uses \eqn{+b}, the mirror image
#' }
#' In both cases \eqn{S(x_0) = 0.5} exactly, which makes \code{x0} the value
#' that separates "better than reference" from "worse than reference".
#'
#' \strong{On the default \code{b = 2.5}.} This value is a convention, not a
#' constant of nature. It reaches this package from Yu et al. via Chaudhry
#' (2024), where it was found to behave reasonably for pH, total nitrogen,
#' soil organic carbon and phosphorus. It has no general justification for
#' other indicators, and it is exposed as a parameter precisely so that it can
#' be changed. Larger \code{b} produces a sharper transition around \code{x0};
#' smaller \code{b} produces a flatter, more forgiving curve.
#'
#' \strong{On the default \code{x0}.} The sample mean is a convenient default
#' but it inherits the comparability problem it was meant to solve: scores
#' remain relative to the data you happen to have. Supplying an external
#' reference value -- a non-degraded reference soil, an agronomic threshold --
#' is what makes scores comparable across studies.
#'
#' \strong{Linear or non-linear?} The literature does not agree. Yuan (2026)
#' reports the non-linear form fitting better than the linear one
#' (R-squared 0.65 vs 0.56), while Bilgili et al. (2017) -- cited inside
#' Yuan's own introduction -- reports the opposite. Compute both and report
#' whether your conclusions change; see \code{\link{score_higher_better}} and
#' \code{\link{score_lower_better}} for the linear route.
#'
#' @param x Numeric vector of indicator values. Must be non-negative: a
#'   negative base raised to a fractional exponent is undefined in real
#'   arithmetic and yields \code{NaN}. Shift the variable or use
#'   \code{\link{score_threshold}} instead.
#' @param direction Either \code{"higher"} (more is better, the default) or
#'   \code{"lower"} (less is better, e.g. bulk density).
#' @param x0 Reference value at which the score equals 0.5. Defaults to
#'   \code{mean(x, na.rm = TRUE)}. Must be strictly positive.
#' @param b Shape parameter controlling the steepness of the curve. Must be
#'   positive; the direction argument supplies the sign. Defaults to 2.5.
#' @param na.rm Logical. Passed to the computation of the default \code{x0}.
#'   Has no effect when \code{x0} is supplied. \code{NA} values in \code{x}
#'   always propagate to \code{NA} scores.
#'
#' @return Numeric vector of scores in the [0,1] range, with \code{NA} where
#'   \code{x} was \code{NA}.
#'
#' @references
#' Chaudhry, H. et al. (2024), eq. (1).
#' Yuan, X. and Shi, Y. (2026), eq. (5).
#' Huera-Lucero, T. et al. (2025), who write it as
#' \eqn{S = a / (1 + (x/x_0)^b)} with \eqn{a = 1}.
#'
#' @examples
#' # Organic matter: more is better
#' om <- c(1.5, 2.0, 2.5, 3.0, 3.5)
#' score_sigmoid(om)
#'
#' # The score at the reference value is exactly 0.5
#' score_sigmoid(om, x0 = 2.5)[3]
#'
#' # Bulk density: less is better
#' bd <- c(1.2, 1.3, 1.4, 1.5, 1.6)
#' score_sigmoid(bd, direction = "lower")
#'
#' # Anchor on an external reference instead of the sample mean
#' score_sigmoid(om, x0 = 3.0)
#'
#' # A sharper transition around the reference
#' score_sigmoid(om, b = 6)
#'
#' @seealso \code{\link{score_higher_better}}, \code{\link{score_lower_better}}
#'   for the linear alternative; \code{\link{sigmoid_scoring}} to build a
#'   scoring rule object for use with \code{\link{compute_sqi_properties}}
#'
#' @export
score_sigmoid <- function(x,
                          direction = c("higher", "lower"),
                          x0 = NULL,
                          b = 2.5,
                          na.rm = TRUE) {
  direction <- match.arg(direction)

  if (!is.numeric(x)) {
    stop("x must be numeric")
  }

  if (!is.numeric(b) || length(b) != 1 || is.na(b) || b <= 0) {
    stop("b must be a single positive number; the direction argument ",
         "supplies its sign")
  }

  # Default reference: the sample mean.
  if (is.null(x0)) {
    if (all(is.na(x))) {
      stop("Cannot derive a default x0: all values in x are NA")
    }
    x0 <- mean(x, na.rm = na.rm)
  }

  if (!is.numeric(x0) || length(x0) != 1 || is.na(x0)) {
    stop("x0 must be a single non-missing numeric value")
  }

  if (x0 <= 0) {
    stop("x0 must be strictly positive (got ", x0, "). The sigmoidal curve ",
         "is defined on a ratio x/x0, which is meaningless for a ",
         "non-positive reference. Shift the variable to a positive range or ",
         "use score_threshold() instead.")
  }

  # A negative base with a fractional exponent is NaN in real arithmetic.
  # Fail loudly rather than silently returning NaN scores.
  if (any(x < 0, na.rm = TRUE)) {
    stop("x contains negative values, for which the sigmoidal score is ",
         "undefined ((x/x0)^b is NaN for a negative base and a fractional ",
         "exponent). Shift the variable to a non-negative range or use ",
         "score_threshold() instead.")
  }

  # The direction supplies the sign of the exponent.
  #   "higher": exponent -b, so large x -> ratio^-b -> 0 -> S -> 1
  #   "lower":  exponent +b, so large x -> ratio^+b -> Inf -> S -> 0
  exponent <- if (direction == "higher") -b else b

  ratio <- x / x0

  # x == 0 is well defined as a limit and R computes it correctly:
  #   0^-b = Inf -> S = 0  (worst, for "higher")
  #   0^+b = 0   -> S = 1  (best, for "lower")
  score <- 1 / (1 + ratio^exponent)

  # Guard against floating point drift at the asymptotes.
  score[!is.na(score) & score < 0] <- 0
  score[!is.na(score) & score > 1] <- 1

  score
}

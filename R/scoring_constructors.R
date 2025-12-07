#' Create a higher-is-better scoring rule
#'
#' Creates a scoring rule object for indicators where higher values indicate
#' better soil quality. The rule will normalize values using min-max
#' normalization: (x - min) / (max - min).
#'
#' @param min_value Optional minimum value for normalization. If NULL,
#'   the minimum will be calculated from the data.
#' @param max_value Optional maximum value for normalization. If NULL,
#'   the maximum will be calculated from the data.
#'
#' @return A scoring_rule object of class c("scoring_rule", "higher_better")
#'
#' @examples
#' # Create a rule for organic matter (higher is better)
#' om_rule <- higher_better()
#'
#' # With custom min/max values
#' om_rule <- higher_better(min_value = 0, max_value = 5)
#'
#' @seealso \code{\link{lower_better}}, \code{\link{optimum_range}},
#'   \code{\link{threshold_scoring}}
#'
#' @export
higher_better <- function(min_value = NULL, max_value = NULL) {
  structure(
    list(
      type = "higher",
      min_val = min_value,
      max_val = max_value
    ),
    class = c("scoring_rule", "higher_better")
  )
}

#' Create a lower-is-better scoring rule
#'
#' Creates a scoring rule object for indicators where lower values indicate
#' better soil quality. The rule will normalize values using inverted
#' min-max normalization: (max - x) / (max - min).
#'
#' @param min_value Optional minimum value for normalization. If NULL,
#'   the minimum will be calculated from the data.
#' @param max_value Optional maximum value for normalization. If NULL,
#'   the maximum will be calculated from the data.
#'
#' @return A scoring_rule object of class c("scoring_rule", "lower_better")
#'
#' @examples
#' # Create a rule for bulk density (lower is better)
#' bd_rule <- lower_better()
#'
#' # With custom min/max values
#' bd_rule <- lower_better(min_value = 1.0, max_value = 1.8)
#'
#' @seealso \code{\link{higher_better}}, \code{\link{optimum_range}},
#'   \code{\link{threshold_scoring}}
#'
#' @export
lower_better <- function(min_value = NULL, max_value = NULL) {
  structure(
    list(
      type = "lower",
      min_val = min_value,
      max_val = max_value
    ),
    class = c("scoring_rule", "lower_better")
  )
}

#' Create an optimum range scoring rule
#'
#' Creates a scoring rule object for indicators where values near an optimum
#' are best. The rule will normalize values based on distance from the
#' optimum, with scores decreasing linearly or quadratically as values
#' move away from the optimum.
#'
#' @param optimal The optimal value for the indicator
#' @param tolerance The distance from optimal where score reaches 0.
#'   Must be a positive number.
#' @param penalty Type of penalty function: "linear" (default) or
#'   "quadratic". Linear penalty decreases score proportionally to
#'   distance, while quadratic penalty is more forgiving near the optimum.
#'
#' @return A scoring_rule object of class c("scoring_rule", "optimum_range")
#'
#' @examples
#' # Create a rule for pH (optimum around 7)
#' ph_rule <- optimum_range(optimal = 7, tolerance = 1.5)
#'
#' # With quadratic penalty for more gradual decrease
#' ph_rule <- optimum_range(optimal = 7, tolerance = 1.5,
#'                          penalty = "quadratic")
#'
#' @seealso \code{\link{higher_better}}, \code{\link{lower_better}},
#'   \code{\link{threshold_scoring}}
#'
#' @export
optimum_range <- function(optimal, tolerance = 1, penalty = "linear") {
  # Validate tolerance is positive
  if (!is.numeric(tolerance) || length(tolerance) != 1 || tolerance <= 0) {
    stop("tolerance must be a positive number")
  }

  # Validate penalty type
  if (!penalty %in% c("linear", "quadratic")) {
    stop("penalty must be 'linear' or 'quadratic'")
  }

  structure(
    list(
      type = "optimum",
      optimum = optimal,
      tol = tolerance,
      penalty = penalty
    ),
    class = c("scoring_rule", "optimum_range")
  )
}

#' Create a threshold-based scoring rule
#'
#' Creates a scoring rule object for indicators with custom piecewise
#' linear scoring based on threshold-score pairs. Values are scored using
#' linear interpolation between the specified thresholds.
#'
#' @param thresholds Numeric vector of threshold values (should be sorted
#'   in ascending order)
#' @param scores Numeric vector of scores corresponding to each threshold.
#'   Must have the same length as thresholds.
#'
#' @return A scoring_rule object of class c("scoring_rule",
#'   "threshold_scoring")
#'
#' @examples
#' # Create a rule for phosphorus with custom thresholds
#' p_rule <- threshold_scoring(
#'   thresholds = c(0, 10, 20, 30),
#'   scores = c(0, 0.5, 1.0, 1.0)
#' )
#'
#' # Create a rule with non-linear scoring pattern
#' custom_rule <- threshold_scoring(
#'   thresholds = c(0, 5, 15, 25, 40),
#'   scores = c(0, 0.3, 0.8, 1.0, 0.9)
#' )
#'
#' @seealso \code{\link{higher_better}}, \code{\link{lower_better}},
#'   \code{\link{optimum_range}}
#'
#' @export
threshold_scoring <- function(thresholds, scores) {
  # Validate that thresholds and scores have equal length
  if (length(thresholds) != length(scores)) {
    stop("thresholds and scores must have equal length")
  }

  # Validate that inputs are numeric
  if (!is.numeric(thresholds) || !is.numeric(scores)) {
    stop("thresholds and scores must be numeric vectors")
  }

  structure(
    list(
      type = "threshold",
      thresholds = thresholds,
      scores = scores
    ),
    class = c("scoring_rule", "threshold_scoring")
  )
}

#' Print method for scoring_rule objects
#'
#' @param x A scoring_rule object
#' @param ... Additional arguments (not used)
#'
#' @return Invisibly returns the input object
#'
#' @export
print.scoring_rule <- function(x, ...) {
  cat("Scoring Rule:", class(x)[2], "\n")

  if (inherits(x, "higher_better")) {
    cat("  Type: Higher values are better\n")
    if (!is.null(x$min_val)) cat("  Min value:", x$min_val, "\n")
    if (!is.null(x$max_val)) cat("  Max value:", x$max_val, "\n")
  } else if (inherits(x, "lower_better")) {
    cat("  Type: Lower values are better\n")
    if (!is.null(x$min_val)) cat("  Min value:", x$min_val, "\n")
    if (!is.null(x$max_val)) cat("  Max value:", x$max_val, "\n")
  } else if (inherits(x, "optimum_range")) {
    cat("  Type: Optimum range\n")
    cat("  Optimal value:", x$optimum, "\n")
    cat("  Tolerance:", x$tol, "\n")
    cat("  Penalty:", x$penalty, "\n")
  } else if (inherits(x, "threshold_scoring")) {
    cat("  Type: Threshold-based scoring\n")
    cat("  Thresholds:", paste(x$thresholds, collapse = ", "), "\n")
    cat("  Scores:", paste(x$scores, collapse = ", "), "\n")
  }

  invisible(x)
}

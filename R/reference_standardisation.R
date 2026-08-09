#' Standardise an indicator against a non-degraded reference soil
#'
#' Scores an indicator relative to the same indicator measured in an
#' \strong{undisturbed reference soil}, which takes the value 1 while degraded
#' samples fall toward 0. This is the only documented escape from the
#' comparability problem that makes published soil quality indices impossible
#' to set beside one another.
#'
#' @details
#' \strong{The problem it solves.} Every other scoring function in this
#' package -- \code{\link{score_higher_better}} and its relatives -- normalises
#' against the sample's own extremes. That guarantees the best site in your
#' data scores about 1 \emph{by construction}, whether that site is pristine or
#' merely the least ruined of a bad set. Two studies can report an SQI of 0.8
#' and mean entirely different soils. Standardising against a fixed external
#' reference replaces "best in this data set" with "relative to undisturbed",
#' which is a quantity that means the same thing in both studies.
#'
#' \strong{The price, stated plainly.} You need a defensible non-degraded
#' reference soil: same soil type, same parent material, same climate,
#' undisturbed. Kuzyakov et al. (2020) call this the approach's key
#' disadvantage, and it is a real one -- a fully converted agricultural
#' landscape often has no such site left within reach. A badly chosen
#' reference does not merely add noise, it silently rescales every index built
#' on it. If you cannot defend the reference, the sample-relative functions are
#' the more honest choice, and you say so in the methods.
#'
#' \strong{The three directions.}
#' \describe{
#'   \item{\code{"higher"}}{More is better -- organic matter, nutrients. The
#'     reference holds the maximum, and the score is \code{x / reference}.}
#'   \item{\code{"lower"}}{Less is better -- bulk density, compaction. The
#'     \strong{minimum} belongs to the undisturbed soil, so the score inverts
#'     to \code{reference / x}.}
#'   \item{\code{"optimum"}}{Neither extreme is good -- pH, water and air
#'     permeability, hydrophobicity. Kuzyakov is explicit that these need the
#'     \strong{difference from the optimum}, not a monotone scale, so the score
#'     is \code{1 - abs(x - reference) / tolerance} with \code{reference}
#'     taken as the optimal value.}
#' }
#'
#' \strong{Scores above 1.} A sample can beat the reference. That is not an
#' error, and it is worth knowing about: it usually means the chosen reference
#' is not actually the least disturbed soil available. With
#' \code{clamp = TRUE} the score is capped at 1 and a warning names how many
#' samples exceeded it. With \code{clamp = FALSE} the raw ratio is returned.
#'
#' @param x Numeric vector of indicator values.
#' @param reference Single numeric value: the same indicator measured in the
#'   reference soil. For \code{direction = "optimum"} this is the optimal
#'   value rather than a measured reference.
#' @param direction One of \code{"higher"} (the default), \code{"lower"} or
#'   \code{"optimum"}.
#' @param tolerance Required for \code{direction = "optimum"}: the distance
#'   from the optimum at which the score reaches 0.
#' @param clamp If \code{TRUE} (the default), scores are confined to [0,1] and
#'   a warning reports any sample that exceeded the reference.
#'
#' @return Numeric vector of scores, 1 at the reference and falling toward 0
#'   with degradation.
#'
#' @references
#' Kuzyakov, Y. et al. (2020). Frontiers of Agricultural Science and
#' Engineering 7(3):282-288. \doi{10.15302/J-FASE-2020338}
#'
#' @examples
#' # Organic matter against an undisturbed reference of 4.2%
#' standardize_to_reference(c(2.1, 3.0, 4.2), reference = 4.2)
#'
#' # Bulk density: the reference holds the minimum, so the score inverts
#' standardize_to_reference(c(1.2, 1.4, 1.6), reference = 1.2,
#'                          direction = "lower")
#'
#' # pH: distance from the optimum, not a monotone scale
#' standardize_to_reference(c(5.0, 6.5, 8.0), reference = 6.5,
#'                          direction = "optimum", tolerance = 1.5)
#'
#' @seealso \code{\link{reference_scoring}} to use this inside
#'   \code{\link{compute_sqi_properties}}; \code{\link{score_higher_better}}
#'   for the sample-relative alternative
#'
#' @export
standardize_to_reference <- function(x,
                                     reference,
                                     direction = c("higher", "lower",
                                                   "optimum"),
                                     tolerance = NULL,
                                     clamp = TRUE) {
  direction <- match.arg(direction)

  if (!is.numeric(x)) {
    stop("x must be numeric")
  }
  if (!is.numeric(reference) || length(reference) != 1 || is.na(reference)) {
    stop("reference must be a single non-missing numeric value")
  }

  if (direction == "optimum") {
    if (is.null(tolerance) || !is.numeric(tolerance) ||
        length(tolerance) != 1 || is.na(tolerance) || tolerance <= 0) {
      stop("tolerance must be a single positive number when ",
           "direction = \"optimum\"; it is the distance from the optimum at ",
           "which the score reaches 0")
    }
    score <- 1 - abs(x - reference) / tolerance
  } else {
    if (reference <= 0) {
      stop("reference must be strictly positive for direction = \"",
           direction, "\", because the score is a ratio against it (got ",
           reference, ")")
    }

    if (direction == "higher") {
      if (any(x < 0, na.rm = TRUE)) {
        stop("x contains negative values, for which a ratio against a ",
             "reference has no meaning")
      }
      score <- x / reference
    } else {
      if (any(x <= 0, na.rm = TRUE)) {
        stop("x contains zero or negative values; direction = \"lower\" ",
             "divides by x, so they are undefined")
      }
      score <- reference / x
    }
  }

  if (clamp) {
    exceeded <- sum(score > 1, na.rm = TRUE)
    if (exceeded > 0) {
      warning(exceeded, " of ", sum(!is.na(score)), " samples scored above ",
              "the reference and were capped at 1. That usually means the ",
              "reference soil is not the least disturbed one available. ",
              "Pass clamp = FALSE to see the raw ratios.")
    }
    score[!is.na(score) & score > 1] <- 1
    score[!is.na(score) & score < 0] <- 0
  }

  score
}


#' Create a reference-soil scoring rule
#'
#' Creates a scoring rule that standardises an indicator against a
#' non-degraded reference soil rather than against the sample's own extremes.
#' See \code{\link{standardize_to_reference}} for what that buys and what it
#' costs.
#'
#' @param reference Single numeric value: the indicator measured in the
#'   reference soil, or the optimal value when
#'   \code{direction = "optimum"}.
#' @param direction One of \code{"higher"} (the default), \code{"lower"} or
#'   \code{"optimum"}.
#' @param tolerance Required for \code{direction = "optimum"}.
#' @param clamp Passed to \code{\link{standardize_to_reference}}.
#'
#' @return A scoring_rule object of class
#'   c("scoring_rule", "reference_scoring")
#'
#' @examples
#' rules <- list(
#'   OM = reference_scoring(reference = 4.2),
#'   BD = reference_scoring(reference = 1.2, direction = "lower"),
#'   pH = reference_scoring(reference = 6.5, direction = "optimum",
#'                          tolerance = 1.5)
#' )
#'
#' result <- compute_sqi_properties(
#'   soil_structured, properties = names(rules), id_column = "SampleID",
#'   scoring_rules = rules
#' )
#'
#' @seealso \code{\link{standardize_to_reference}},
#'   \code{\link{higher_better}} for the sample-relative equivalent
#'
#' @export
reference_scoring <- function(reference,
                              direction = c("higher", "lower", "optimum"),
                              tolerance = NULL,
                              clamp = TRUE) {
  direction <- match.arg(direction)

  if (!is.numeric(reference) || length(reference) != 1 || is.na(reference)) {
    stop("reference must be a single non-missing numeric value")
  }

  if (direction == "optimum" &&
      (is.null(tolerance) || !is.numeric(tolerance) ||
       length(tolerance) != 1 || is.na(tolerance) || tolerance <= 0)) {
    stop("tolerance must be a single positive number when ",
         "direction = \"optimum\"")
  }

  if (direction != "optimum" && reference <= 0) {
    stop("reference must be strictly positive for direction = \"",
         direction, "\"")
  }

  structure(
    list(
      type = "reference",
      reference = reference,
      direction = direction,
      tolerance = tolerance,
      clamp = clamp
    ),
    class = c("scoring_rule", "reference_scoring")
  )
}


#' Classify indicators as sensitive or resistant to degradation
#'
#' Compares how far each indicator has moved between a degraded soil and a
#' reference soil, \strong{relative to how far soil organic carbon moved}.
#' Indicators that decline faster than carbon are sensitive -- they register
#' degradation early -- and those that decline more slowly are resistant.
#'
#' @details
#' This is Kuzyakov et al.'s (2020) second and much less used approach. Each
#' indicator's relative change is divided by the relative change in the carbon
#' indicator. On the 1:1 identity line the indicator degrades at exactly
#' carbon's rate; below it, faster; above it, slower.
#'
#' The expected pattern is that (micro)biological properties are sensitive and
#' physical properties resistant, which is why an early-warning monitoring
#' programme should watch the biological ones.
#'
#' \strong{It does not always separate.} Kuzyakov reports the classification
#' resolving cleanly on a Luvic Phaeozem and \strong{failing to separate on a
#' Calcic Chernozem}. Treat a tidy result as informative and an untidy one as
#' a fact about the soil rather than a failure of the analysis -- a
#' \code{ratio} near 1 for everything means the indicators are degrading
#' together, which is itself worth reporting.
#'
#' Both inputs are single soils summarised to one value per indicator -- a
#' mean over the plots of each condition, typically. The function does not
#' propagate the uncertainty in those means, so a ratio close to 1 should not
#' be over-read.
#'
#' @param degraded Named numeric vector of indicator values in the degraded
#'   soil, or a one-row data frame.
#' @param reference Named numeric vector of the same indicators in the
#'   reference soil, or a one-row data frame. Must cover every name in
#'   \code{degraded}.
#' @param carbon Name of the carbon indicator against which the others are
#'   compared. Defaults to \code{"SOC"}.
#' @param tolerance Half-width of the band around 1 within which an indicator
#'   is called \code{"proportional"} rather than sensitive or resistant.
#'   Defaults to 0.1.
#'
#' @return A data frame with one row per indicator, ordered from most
#'   sensitive to most resistant:
#'   \describe{
#'     \item{indicator}{Indicator name}
#'     \item{degraded, reference}{The two input values}
#'     \item{change}{\code{degraded / reference}}
#'     \item{ratio}{\code{change} divided by the carbon indicator's change}
#'     \item{class}{\code{"sensitive"}, \code{"proportional"} or
#'       \code{"resistant"}}
#'   }
#'
#' @references
#' Kuzyakov, Y. et al. (2020). Frontiers of Agricultural Science and
#' Engineering 7(3):282-288. \doi{10.15302/J-FASE-2020338}
#'
#' @examples
#' degraded  <- c(SOC = 1.1, OM = 1.9, N = 0.09, CEC = 9.0, BD = 1.55)
#' reference <- c(SOC = 2.0, OM = 3.4, N = 0.18, CEC = 13.0, BD = 1.25)
#'
#' sensitivity_resistance(degraded, reference)
#'
#' @seealso \code{\link{standardize_to_reference}}
#'
#' @export
sensitivity_resistance <- function(degraded,
                                   reference,
                                   carbon = "SOC",
                                   tolerance = 0.1) {
  degraded <- .as_named_numeric(degraded, "degraded")
  reference <- .as_named_numeric(reference, "reference")

  missing <- setdiff(names(degraded), names(reference))
  if (length(missing) > 0) {
    stop("reference is missing these indicators present in degraded: ",
         paste(missing, collapse = ", "))
  }

  if (!carbon %in% names(degraded)) {
    stop("The carbon indicator \"", carbon, "\" is not among the indicators ",
         "supplied. Everything here is measured relative to it, so it must ",
         "be present; pass `carbon` to name a different one.")
  }

  reference <- reference[names(degraded)]

  if (any(reference == 0, na.rm = TRUE)) {
    stop("reference contains zero values; the relative change divides by it")
  }

  change <- degraded / reference
  carbon_change <- change[[carbon]]

  if (is.na(carbon_change) || carbon_change == 0) {
    stop("The change in \"", carbon, "\" is zero or missing, so the other ",
         "indicators cannot be expressed relative to it")
  }

  ratio <- change / carbon_change

  class_of <- ifelse(
    abs(ratio - 1) <= tolerance, "proportional",
    ifelse(ratio < 1, "sensitive", "resistant")
  )

  out <- data.frame(
    indicator = names(degraded),
    degraded = unname(degraded),
    reference = unname(reference),
    change = unname(change),
    ratio = unname(ratio),
    class = class_of,
    stringsAsFactors = FALSE
  )

  out <- out[order(out$ratio), , drop = FALSE]
  rownames(out) <- NULL
  out
}


# Internal: accept a named numeric vector or a one-row data frame.
.as_named_numeric <- function(x, arg_name) {
  if (is.data.frame(x)) {
    if (nrow(x) != 1) {
      stop(arg_name, " must be a single soil: one named numeric vector, or a ",
           "data frame with exactly one row (got ", nrow(x), ")")
    }
    numeric_cols <- vapply(x, is.numeric, logical(1))
    x <- unlist(x[, numeric_cols, drop = FALSE])
  }

  if (!is.numeric(x) || is.null(names(x)) || any(names(x) == "")) {
    stop(arg_name, " must be a named numeric vector")
  }

  x
}

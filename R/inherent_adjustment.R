#' Adjust indicators for inherent soil properties
#'
#' Removes the variation in each indicator that is attributable to properties
#' a manager cannot change -- parent material, land-use history -- so that what
#' remains is the part an index can fairly hold anyone responsible for. A soil
#' should not be scored down for being what its geology made it.
#'
#' @details
#' \strong{The idea, and its provenance.} Maaz et al. (2023) built scoring
#' functions that account for inherent properties precisely to stop them
#' biasing the overall score, noting that land-use history and soil type were
#' the two most influential inherent drivers in their region. \strong{No
#' additive-index paper in the reviewed corpus does this.} Everyone else scores
#' the raw measurement, which means a clay soil on old alluvium and a sandy
#' soil on weathered granite are judged on the same scale for a difference
#' neither farmer created.
#'
#' \strong{The arithmetic is unremarkable and the framing is the point.} Each
#' indicator is regressed on the inherent factors and the residuals are kept,
#' recentred on the indicator's own mean so that the scale is preserved and
#' the scoring functions behave exactly as before. A reviewer can fairly say
#' "those are just residuals". They are. What this function adds is an
#' opinionated, documented, correctly-defaulted step in an index pipeline, and
#' a report of what the adjustment cost.
#'
#' \strong{Do not do this by reflex.} Adjusting removes inherent variation
#' \emph{by design}. If your question is "which of these soils is inherently
#' better?" -- siting a plantation, valuing land, mapping capability -- then
#' adjusting destroys the answer you came for. Adjust when the question is
#' about \strong{management}: has this field been looked after, given what it
#' started as. The two questions look similar and are not.
#'
#' \strong{What the R-squared tells you.} The returned \code{r_squared} is the
#' share of each indicator's variation that was inheritance rather than
#' anything a manager did. It is informative in its own right. On
#' \code{\link{soil_inherent}}, \code{Clay} and \code{pH} come back above
#' 0.9 -- almost entirely inherited -- while \code{P} and bulk density sit near
#' 0.2, meaning they were mostly telling you about management all along and had
#' little to adjust away. An indicator above \code{warn_r_squared} is flagged,
#' because once nearly all the variation is inherited the residual is mostly
#' noise.
#'
#' \strong{On the default.} The plan this implements proposed
#' \code{method = "none"} so that adjustment is always deliberate. The default
#' here is \code{"residual"} instead, because \strong{calling this function is
#' the deliberate act}; a no-op default would mean
#' \code{adjust_inherent(data, indicators, ~ soil_type)} silently did nothing,
#' which is its own footgun. The deliberateness lives where it belongs: the
#' \code{inherent} argument of \code{\link{compute_sqi_df}} defaults to
#' \code{NULL}, so the pipeline never adjusts unless asked. \code{"none"}
#' remains available for switching the step off programmatically.
#'
#' @param data A data frame containing the indicators and the inherent
#'   factors.
#' @param indicators Character vector naming the numeric columns to adjust.
#' @param inherent A one-sided formula naming the inherent factors, for
#'   example \code{~ soil_type * land_use_history}. Interactions are usually
#'   what you want: the effect of history often depends on the parent material.
#' @param method \code{"residual"} (the default) adjusts;
#'   \code{"none"} returns the data untouched, for switching the step off
#'   without restructuring code.
#' @param warn_r_squared Flag indicators whose inherent model explains more
#'   than this share of their variation. Defaults to 0.95. \code{NA} disables.
#'
#' @return An object of class \code{inherent_adjustment}:
#'   \describe{
#'     \item{data}{The data frame, with the named indicators replaced by their
#'       adjusted values and every other column untouched}
#'     \item{r_squared}{Named vector: the share of each indicator's variation
#'       explained by the inherent factors}
#'     \item{models}{The fitted \code{lm} objects, for inspection}
#'     \item{indicators, inherent, method}{The settings used}
#'   }
#'
#' @references
#' Maaz, T. M. et al. (2023), after Crow et al. (2022) on land-use history and
#' soil type as the dominant inherent drivers.
#'
#' @examples
#' # Parent material dominates the exchange capacity
#' summary(aov(CEC ~ soil_type, data = soil_inherent))[[1]][["Pr(>F)"]][1]
#'
#' adjusted <- adjust_inherent(
#'   soil_inherent,
#'   indicators = c("OM", "CEC", "pH", "P"),
#'   inherent = ~ soil_type * land_use_history
#' )
#'
#' # What each indicator inherited rather than earned
#' round(adjusted$r_squared, 3)
#'
#' # The soil-type effect is gone, and the management signal is sharper
#' summary(aov(CEC ~ soil_type, data = adjusted$data))[[1]][["Pr(>F)"]][1]
#' summary(aov(CEC ~ management, data = adjusted$data))[[1]][["Pr(>F)"]][1]
#'
#' @seealso \code{\link{compute_sqi_df}}, whose \code{inherent} argument runs
#'   this as a pre-scoring step; \code{\link{soil_inherent}} for data that has
#'   the factors this needs
#'
#' @export
adjust_inherent <- function(data,
                            indicators,
                            inherent,
                            method = c("residual", "none"),
                            warn_r_squared = 0.95) {
  method <- match.arg(method)

  if (!is.data.frame(data)) {
    stop("data must be a data frame")
  }
  if (!is.character(indicators) || length(indicators) == 0) {
    stop("indicators must be a non-empty character vector")
  }

  missing_indicators <- setdiff(indicators, names(data))
  if (length(missing_indicators) > 0) {
    stop("Indicators not found in data: ",
         paste(missing_indicators, collapse = ", "))
  }

  not_numeric <- indicators[!vapply(data[indicators], is.numeric, logical(1))]
  if (length(not_numeric) > 0) {
    stop("These indicators are not numeric and cannot be adjusted: ",
         paste(not_numeric, collapse = ", "))
  }

  if (method == "none") {
    return(structure(
      list(
        data = data,
        r_squared = stats::setNames(rep(NA_real_, length(indicators)),
                                    indicators),
        models = NULL,
        indicators = indicators,
        inherent = if (missing(inherent)) NULL else inherent,
        method = "none"
      ),
      class = "inherent_adjustment"
    ))
  }

  if (missing(inherent) || !inherits(inherent, "formula")) {
    stop("inherent must be a one-sided formula naming the inherent factors, ",
         "for example ~ soil_type * land_use_history")
  }

  inherent_vars <- all.vars(inherent)
  missing_factors <- setdiff(inherent_vars, names(data))
  if (length(missing_factors) > 0) {
    stop("Inherent factors not found in data: ",
         paste(missing_factors, collapse = ", "),
         ". See soil_inherent for a dataset that carries them.")
  }

  overlap <- intersect(indicators, inherent_vars)
  if (length(overlap) > 0) {
    stop("These variables appear as both an indicator and an inherent ",
         "factor: ", paste(overlap, collapse = ", "),
         ". Adjusting an indicator for itself removes all of it.")
  }

  rhs <- paste(deparse(inherent[[2]]), collapse = " ")

  models <- list()
  r_squared <- stats::setNames(numeric(length(indicators)), indicators)
  adjusted <- data

  for (ind in indicators) {
    # na.exclude keeps the residual vector the same length as the data, with
    # NA where the input was NA, so rows stay aligned.
    fit <- stats::lm(stats::as.formula(paste(ind, "~", rhs)),
                     data = data, na.action = stats::na.exclude)

    resid <- stats::residuals(fit)

    # Recentre on the indicator's own mean so the scale survives and the
    # scoring functions behave exactly as they did on the raw values.
    adjusted[[ind]] <- as.numeric(resid) + mean(data[[ind]], na.rm = TRUE)

    models[[ind]] <- fit
    r_squared[[ind]] <- summary(fit)$r.squared
  }

  if (!is.na(warn_r_squared)) {
    saturated <- names(r_squared)[r_squared > warn_r_squared]
    if (length(saturated) > 0) {
      warning("The inherent factors explain more than ",
              format(100 * warn_r_squared), "% of these indicators: ",
              paste(sprintf("%s (%.3f)", saturated, r_squared[saturated]),
                    collapse = ", "),
              ". Almost nothing is left after adjustment, so the residual is ",
              "largely noise. Consider dropping them rather than scoring ",
              "what remains.", call. = FALSE)
    }
  }

  structure(
    list(
      data = adjusted,
      r_squared = r_squared,
      models = models,
      indicators = indicators,
      inherent = inherent,
      method = "residual"
    ),
    class = "inherent_adjustment"
  )
}


#' Print method for inherent_adjustment objects
#'
#' @param x An \code{inherent_adjustment} object
#' @param ... Additional arguments (not used)
#'
#' @return Invisibly returns the input object
#'
#' @export
print.inherent_adjustment <- function(x, ...) {
  cat("Inherent-property adjustment\n")

  if (x$method == "none") {
    cat("  method = \"none\": the data was returned untouched.\n")
    return(invisible(x))
  }

  cat("  Adjusted for:", paste(deparse(x$inherent), collapse = " "), "\n")
  cat("  Indicators  :", length(x$indicators), "\n\n")

  cat("Share of each indicator that was inheritance, not management\n")

  ordered <- sort(x$r_squared, decreasing = TRUE)
  for (nm in names(ordered)) {
    bar <- strrep("#", round(ordered[[nm]] * 30))
    cat(sprintf("  %-10s %.3f  %s\n", nm, ordered[[nm]], bar))
  }

  cat("\n  A high value means the indicator was mostly telling you about the\n")
  cat("  soil's inheritance. A low one means it was already about management,\n")
  cat("  and there was little to remove.\n")

  invisible(x)
}

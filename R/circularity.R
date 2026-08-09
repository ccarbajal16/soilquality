#' Detect circularity between an index and its predictors
#'
#' Refuses to let you regress a soil quality index on the indicators that
#' \strong{built} it. An index is a weighted sum of its components, so a model
#' predicting it from those components must fit well: the R-squared is
#' structural arithmetic, not evidence about soil.
#'
#' @details
#' \strong{Why this exists.} If an SQI is built from organic carbon, total
#' nitrogen, the humic-to-fulvic ratio and enzyme activity, then a path model
#' regressing that SQI on those four variables is guaranteed to succeed. It is
#' not a finding. Sarapatka et al. (2026) report \strong{R-squared = 0.99} from
#' exactly this arrangement and, to their credit, name the cause: "the
#' methodological dependence of SQI on its own components". Wang et al. (2025)
#' conclude that soil organic carbon positively affects soil quality in every
#' vegetation pattern, where carbon is an input to the index.
#'
#' No general-purpose modelling package can catch this, because none of them
#' knows which variables constructed your index. This one does.
#'
#' \strong{Two legitimate uses, and the function distinguishes them.}
#'
#' \describe{
#'   \item{Explanation}{Predictors from \strong{outside} the index --
#'     erosion, slope, management, years since conversion. These carry real
#'     information and the fit means something. This is the default, and
#'     overlap is an error.}
#'   \item{Decomposition}{Predictors that \strong{are} components, asked
#'     deliberately: "which of my indicators dominates this index?". A fair
#'     question with a real answer, but the fit statistic is meaningless.
#'     Pass \code{allow_components = TRUE}; the result is labelled a
#'     decomposition, and \code{\link{print.sqi_circularity}} says so and tells
#'     you not to report the R-squared.}
#' }
#'
#' \strong{Renaming is not laundering.} Name matching alone would miss the
#' commonest version of this mistake: an index built on \code{OM} regressed
#' against \code{SOC}, which is the same measurement times 1.724. Supply
#' \code{data} and every predictor is also checked for correlation against
#' every index component; anything above \code{r_max} is reported as a proxy
#' and treated exactly like a name collision. On the package's own
#' \code{\link{soil_structured}}, \code{OM} and \code{SOC} correlate at 0.99.
#'
#' @param index An \code{sqi_result} object, whose \code{$mds} names the
#'   indicators that built the index, or a character vector of those names.
#' @param predictors The variables you intend to model the index on: a
#'   character vector, a one-sided formula such as \code{~ erosion + slope},
#'   or a data frame whose column names are used.
#' @param data Optional data frame containing both the index components and
#'   the predictors. When supplied, differently-named proxies are detected by
#'   correlation as well as by name.
#' @param allow_components If \code{FALSE} (the default) any overlap is an
#'   error. \code{TRUE} permits it and marks the result as a decomposition.
#' @param r_max Absolute Spearman correlation above which a differently-named
#'   predictor counts as a proxy for an index component. Defaults to 0.9.
#'   Only used when \code{data} is supplied.
#'
#' @return An object of class \code{sqi_circularity}:
#'   \describe{
#'     \item{components}{The indicators that built the index}
#'     \item{predictors}{The predictors checked}
#'     \item{shared}{Predictors that are index components by name}
#'     \item{proxies}{Data frame of predictor, component and correlation for
#'       proxies detected numerically}
#'     \item{circular}{\code{TRUE} if any overlap was found}
#'     \item{mode}{\code{"explanation"} or \code{"decomposition"}}
#'   }
#'
#' @references
#' Sarapatka, B. et al. (2026) -- the R-squared 0.99 case, and the authors'
#' own diagnosis of it.
#' Wang, Y. et al. (2025) -- carbon "affecting" an index carbon helped build.
#'
#' @examples
#' props <- c("pH", "OM", "N", "P", "K", "CEC", "BD")
#' index <- compute_sqi_properties(soil_structured, properties = props,
#'                                 id_column = "SampleID")
#'
#' # Predictors from outside the index: fine
#' check_circularity(index, ~ Sand + Clay)
#'
#' # A component of the index: refused
#' try(check_circularity(index, ~ OM + Sand))
#'
#' # Asked deliberately as a decomposition: permitted, and labelled
#' check_circularity(index, ~ OM + Sand, allow_components = TRUE)
#'
#' # Renaming does not launder it: SOC is OM by another name
#' check_circularity(index, ~ SOC, data = soil_structured,
#'                   allow_components = TRUE)
#'
#' @seealso \code{\link{sqi_validate}}, which applies the same check to an
#'   external validation criterion
#'
#' @export
check_circularity <- function(index,
                              predictors,
                              data = NULL,
                              allow_components = FALSE,
                              r_max = 0.9) {
  components <- .index_components(index)
  predictors <- .predictor_names(predictors)

  if (!is.numeric(r_max) || length(r_max) != 1 || r_max < 0 || r_max > 1) {
    stop("r_max must be a single numeric value between 0 and 1")
  }

  shared <- intersect(predictors, components)

  # Renaming is not laundering: check for proxies numerically when we can.
  proxies <- data.frame(predictor = character(0), component = character(0),
                        correlation = numeric(0), stringsAsFactors = FALSE)

  if (!is.null(data)) {
    if (!is.data.frame(data)) {
      stop("data must be a data frame")
    }

    candidates <- setdiff(predictors, shared)

    for (p in candidates) {
      for (cmp in components) {
        if (!all(c(p, cmp) %in% names(data))) {
          next
        }
        if (!is.numeric(data[[p]]) || !is.numeric(data[[cmp]])) {
          next
        }

        r <- suppressWarnings(
          stats::cor(data[[p]], data[[cmp]], method = "spearman",
                     use = "pairwise.complete.obs")
        )

        if (!is.na(r) && abs(r) >= r_max) {
          proxies <- rbind(proxies, data.frame(
            predictor = p, component = cmp, correlation = r,
            stringsAsFactors = FALSE
          ))
        }
      }
    }
  }

  circular <- length(shared) > 0 || nrow(proxies) > 0

  result <- structure(
    list(
      components = components,
      predictors = predictors,
      shared = shared,
      proxies = proxies,
      circular = circular,
      mode = if (circular && allow_components) "decomposition" else "explanation",
      r_max = r_max,
      checked_numerically = !is.null(data)
    ),
    class = "sqi_circularity"
  )

  if (circular && !allow_components) {
    stop(.circularity_message(result), call. = FALSE)
  }

  result
}


#' Print method for sqi_circularity objects
#'
#' @param x An \code{sqi_circularity} object
#' @param ... Additional arguments (not used)
#'
#' @return Invisibly returns the input object
#'
#' @export
print.sqi_circularity <- function(x, ...) {
  cat("Circularity check\n")
  cat("  Index built from:", paste(x$components, collapse = ", "), "\n")
  cat("  Predictors      :", paste(x$predictors, collapse = ", "), "\n")
  if (!x$checked_numerically) {
    cat("  (names only -- pass `data` to also catch renamed proxies)\n")
  }
  cat("\n")

  if (!x$circular) {
    cat("No overlap. The predictors sit outside the index, so a fit between\n")
    cat("them carries information rather than arithmetic.\n")
    return(invisible(x))
  }

  cat("CIRCULAR -- reported as a DECOMPOSITION\n\n")

  if (length(x$shared) > 0) {
    cat("  Predictors that ARE index components:\n")
    cat("   ", paste(x$shared, collapse = ", "), "\n")
  }

  if (nrow(x$proxies) > 0) {
    cat("  Predictors that are components under another name:\n")
    for (i in seq_len(nrow(x$proxies))) {
      cat(sprintf("    %-12s ~ %-12s rho = %.3f\n",
                  x$proxies$predictor[i], x$proxies$component[i],
                  x$proxies$correlation[i]))
    }
  }

  cat("\n  This is a legitimate question -- which component dominates the\n")
  cat("  index -- but the fit statistic is not. DO NOT REPORT THE R-SQUARED:\n")
  cat("  an index is a weighted sum of these variables, so a model predicting\n")
  cat("  it from them must fit well. The number is arithmetic, not evidence.\n")

  invisible(x)
}


# Internal: the message raised when circularity is refused. Kept separate so
# the wording is identical whether it errors or prints.
.circularity_message <- function(x) {
  parts <- character(0)

  if (length(x$shared) > 0) {
    parts <- c(parts, paste0(
      "these predictors ARE components of the index: ",
      paste(x$shared, collapse = ", ")
    ))
  }

  if (nrow(x$proxies) > 0) {
    parts <- c(parts, paste0(
      "these predictors are components under another name: ",
      paste(sprintf("%s ~ %s (rho = %.2f)", x$proxies$predictor,
                    x$proxies$component, x$proxies$correlation),
            collapse = "; ")
    ))
  }

  paste0(
    "Circular model refused: ", paste(parts, collapse = "; "), ".\n",
    "An index is a weighted sum of its components, so regressing it on them ",
    "must fit well -- the R-squared would be arithmetic, not evidence about ",
    "soil.\n",
    "If you want to explain the index, use predictors from OUTSIDE it. If ",
    "you deliberately want to ask which component dominates it, pass ",
    "allow_components = TRUE and report the result as a decomposition ",
    "without its R-squared."
  )
}


# Internal: the indicators that built an index.
.index_components <- function(index) {
  if (inherits(index, "sqi_result")) {
    if (is.null(index$mds)) {
      stop("index is an sqi_result but carries no $mds")
    }
    return(index$mds)
  }

  if (is.character(index) && length(index) > 0) {
    return(index)
  }

  stop("index must be an sqi_result object or a character vector naming the ",
       "indicators that built the index (got ", class(index)[1], ")")
}


# Internal: predictor names from a character vector, a one-sided formula or a
# data frame.
.predictor_names <- function(predictors) {
  if (inherits(predictors, "formula")) {
    return(all.vars(predictors))
  }

  if (is.data.frame(predictors)) {
    return(names(predictors))
  }

  if (is.character(predictors) && length(predictors) > 0) {
    return(predictors)
  }

  stop("predictors must be a character vector, a one-sided formula, or a ",
       "data frame (got ", class(predictors)[1], ")")
}

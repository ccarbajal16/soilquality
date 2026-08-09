#' Test whether data is adequate for PCA
#'
#' Reports the two standard checks that a correlation matrix is worth factoring
#' at all: the Kaiser-Meyer-Olkin measure of sampling adequacy and Bartlett's
#' test of sphericity. Most published soil quality indices skip both and go
#' straight to the principal components; Theresa et al. (2026) do not, and
#' report KMO 0.81 with Bartlett chi-squared 425.37 on 136 degrees of freedom.
#'
#' @details
#' \strong{Bartlett's test of sphericity} asks whether the correlation matrix
#' is distinguishable from the identity. If it is not -- if the indicators are
#' mutually uncorrelated -- then there are no components to find and PCA has
#' nothing to reduce. The statistic is
#' \deqn{\chi^2 = -\left(n - 1 - \frac{2p + 5}{6}\right) \ln |R|}
#' on \eqn{p(p-1)/2} degrees of freedom. A small p-value is what you want: it
#' means the matrix is \emph{not} an identity.
#'
#' Be aware that this test is close to a formality on real soil data. With a
#' decent sample size almost any set of soil properties rejects sphericity, so
#' passing it is weak evidence. Failing it is strong evidence, and that is the
#' point.
#'
#' \strong{The KMO measure} is the more informative of the two. It compares the
#' size of ordinary correlations to the size of partial correlations:
#' \deqn{KMO = \frac{\sum_{i \ne j} r_{ij}^2}{\sum_{i \ne j} r_{ij}^2 +
#'   \sum_{i \ne j} a_{ij}^2}}
#' where \eqn{a_{ij}} are the partial correlations. When indicators share
#' common factors, partialling out the others leaves little behind and KMO
#' approaches 1. Kaiser's labels:
#'
#' \tabular{ll}{
#'   \strong{KMO} \tab \strong{Verdict} \cr
#'   below 0.50 \tab unacceptable \cr
#'   0.50-0.60 \tab miserable \cr
#'   0.60-0.70 \tab mediocre \cr
#'   0.70-0.80 \tab middling \cr
#'   0.80-0.90 \tab meritorious \cr
#'   0.90 and above \tab marvellous
#' }
#'
#' The per-variable measure (\code{msa}) is often more useful than the overall
#' figure: a single indicator with a low MSA is a candidate for removal, and
#' removing it usually lifts the whole matrix.
#'
#' \strong{A singular correlation matrix.} KMO requires inverting the
#' correlation matrix, which is impossible when indicators are exactly
#' collinear. This is not an edge case in soil science: particle-size
#' fractions sum to 100, so \code{Sand}, \code{Silt} and \code{Clay} together
#' are perfectly collinear by construction, and organic matter and organic
#' carbon are related by a fixed factor. When the matrix is singular the KMO
#' fields come back \code{NA} with an explanation in \code{$kmo_message},
#' rather than the function erroring or returning a number computed from a
#' pseudo-inverse that nobody asked for. Drop one member of each collinear set
#' and try again.
#'
#' @param data A data frame or matrix of indicator values. Only numeric
#'   columns are used. Standardisation is irrelevant here -- both statistics
#'   are computed from the correlation matrix.
#'
#' @return An object of class \code{pca_adequacy}, a list with:
#'   \describe{
#'     \item{kmo}{Overall Kaiser-Meyer-Olkin measure, or \code{NA}}
#'     \item{msa}{Named vector of per-variable measures, or \code{NA}}
#'     \item{kmo_interpretation}{Kaiser's label for the overall KMO}
#'     \item{kmo_message}{Why KMO could not be computed, when it could not}
#'     \item{bartlett}{List of \code{statistic}, \code{df}, \code{p_value}}
#'     \item{n, p}{Observations and indicators used}
#'   }
#'
#' @references
#' Kaiser, H. F. (1974). An index of factorial simplicity.
#' Bartlett, M. S. (1951). The effect of standardization on a chi-square
#' approximation in factor analysis.
#' Theresa, M. et al. (2026) -- an SQI study that reports both.
#'
#' @examples
#' props <- c("pH", "OM", "N", "P", "K", "CEC", "BD")
#' pca_adequacy(soil_structured[, props])
#'
#' # Particle-size fractions sum to 100, so including all three makes the
#' # correlation matrix singular and KMO undefined
#' pca_adequacy(soil_structured[, c("Sand", "Silt", "Clay", "pH", "OM")])
#'
#' @seealso \code{\link{pca_select_mds}}, which reports this automatically
#'
#' @export
pca_adequacy <- function(data) {
  if (!is.data.frame(data) && !is.matrix(data)) {
    stop("data must be a data frame or matrix")
  }

  data <- as.data.frame(data)
  numeric_cols <- vapply(data, is.numeric, logical(1))
  if (!any(numeric_cols)) {
    stop("data must contain at least one numeric column")
  }

  x <- as.matrix(data[, numeric_cols, drop = FALSE])
  x <- x[stats::complete.cases(x), , drop = FALSE]

  n <- nrow(x)
  p <- ncol(x)

  if (p < 2) {
    stop("At least 2 numeric indicators are required (got ", p, ")")
  }
  if (n < 3) {
    stop("At least 3 complete observations are required (got ", n, ")")
  }

  R <- stats::cor(x)

  # ---- Bartlett's test of sphericity ----------------------------------------
  det_R <- det(R)

  bartlett <- if (det_R <= 0) {
    # A non-positive determinant means the matrix is singular, so the log is
    # undefined. Report rather than produce a number.
    list(statistic = NA_real_, df = p * (p - 1) / 2, p_value = NA_real_)
  } else {
    chi_sq <- -(n - 1 - (2 * p + 5) / 6) * log(det_R)
    df <- p * (p - 1) / 2
    list(statistic = chi_sq, df = df,
         p_value = stats::pchisq(chi_sq, df, lower.tail = FALSE))
  }

  # ---- Kaiser-Meyer-Olkin ---------------------------------------------------
  R_inv <- try(solve(R), silent = TRUE)

  if (inherits(R_inv, "try-error")) {
    collinear <- .name_collinear(R)
    return(structure(
      list(
        kmo = NA_real_,
        msa = NA_real_,
        kmo_interpretation = NA_character_,
        kmo_message = paste0(
          "The correlation matrix is singular, so it cannot be inverted and ",
          "KMO is undefined. This usually means some indicators are exactly ",
          "collinear -- particle-size fractions summing to 100 is the ",
          "classic case.",
          if (length(collinear) > 0) {
            paste0(" Pairs correlating above 0.99: ",
                   paste(collinear, collapse = "; "), ".")
          } else {
            ""
          }
        ),
        bartlett = bartlett,
        n = n,
        p = p
      ),
      class = "pca_adequacy"
    ))
  }

  # Anti-image (partial) correlations.
  d <- sqrt(diag(R_inv))
  partial <- -R_inv / outer(d, d)
  diag(partial) <- 0

  R_off <- R
  diag(R_off) <- 0

  kmo <- sum(R_off^2) / (sum(R_off^2) + sum(partial^2))

  msa <- rowSums(R_off^2) / (rowSums(R_off^2) + rowSums(partial^2))
  names(msa) <- colnames(R)

  structure(
    list(
      kmo = kmo,
      msa = msa,
      kmo_interpretation = .kmo_label(kmo),
      kmo_message = NULL,
      bartlett = bartlett,
      n = n,
      p = p
    ),
    class = "pca_adequacy"
  )
}


#' Print method for pca_adequacy objects
#'
#' @param x A \code{pca_adequacy} object
#' @param ... Additional arguments (not used)
#'
#' @return Invisibly returns the input object
#'
#' @export
print.pca_adequacy <- function(x, ...) {
  cat("PCA adequacy\n")
  cat("  Observations:", x$n, " Indicators:", x$p, "\n\n")

  if (is.na(x$kmo)) {
    cat("Kaiser-Meyer-Olkin: not computable\n")
    cat("  ", x$kmo_message, "\n", sep = "")
  } else {
    cat(sprintf("Kaiser-Meyer-Olkin: %.3f (%s)\n", x$kmo,
                x$kmo_interpretation))

    weak <- sort(x$msa)
    weak <- weak[weak < 0.6]
    if (length(weak) > 0) {
      cat("  Indicators below 0.60, worth considering for removal:\n")
      for (nm in names(weak)) {
        cat(sprintf("    %-10s %.3f\n", nm, weak[[nm]]))
      }
    }
  }

  cat("\nBartlett's test of sphericity\n")
  if (is.na(x$bartlett$statistic)) {
    cat("  Not computable: the correlation matrix is singular.\n")
  } else {
    cat(sprintf("  chi-squared = %.2f, df = %d, p = %.4g\n",
                x$bartlett$statistic, x$bartlett$df, x$bartlett$p_value))
    if (x$bartlett$p_value < 0.05) {
      cat("  The matrix differs from the identity, so there is structure to\n")
      cat("  factor. Note this test rejects on almost any real soil data.\n")
    } else {
      cat("  WARNING: sphericity is NOT rejected. The indicators are close to\n")
      cat("  mutually uncorrelated, and PCA has nothing to reduce.\n")
    }
  }

  invisible(x)
}


# Internal: Kaiser's verdicts for an overall KMO.
.kmo_label <- function(kmo) {
  if (is.na(kmo)) return(NA_character_)
  if (kmo < 0.5) return("unacceptable")
  if (kmo < 0.6) return("miserable")
  if (kmo < 0.7) return("mediocre")
  if (kmo < 0.8) return("middling")
  if (kmo < 0.9) return("meritorious")
  "marvellous"
}


# Internal: name the pairs most likely responsible for a singular matrix, so
# the error message points at something actionable.
.name_collinear <- function(R) {
  offenders <- character(0)
  nm <- colnames(R)

  for (i in seq_len(ncol(R) - 1)) {
    for (j in seq(i + 1, ncol(R))) {
      if (!is.na(R[i, j]) && abs(R[i, j]) > 0.99) {
        offenders <- c(offenders, paste0(nm[i], "/", nm[j]))
      }
    }
  }

  offenders
}

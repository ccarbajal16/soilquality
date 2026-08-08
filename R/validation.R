#' Validate a Soil Quality Index
#'
#' Assesses whether a computed index actually discriminates between samples,
#' rather than assuming it does. A soil quality index has \strong{no ground
#' truth} -- there is no measurement you can compare it against to see whether
#' it is "right" -- so validation has to proceed by asking whether the index
#' behaves like something useful for a decision.
#'
#' @details
#' Four diagnostics are reported, in descending order of how much they should
#' influence your judgement.
#'
#' \strong{1. Distribution across decision categories (the headline).} The
#' share of samples falling in each of the five conventional soil-health
#' bands: very low (0-0.2), low (0.2-0.4), medium (0.4-0.6), high (0.6-0.8)
#' and very high (0.8-1.0). This is the corpus's strongest methodological
#' finding and the reason it is printed first.
#'
#' Maaz et al. (2023) compared a structural-equation-model index against a
#' simple additive one. The two correlated at \strong{r = 0.96} -- apparent
#' agreement -- yet the additive index placed \strong{94\%} of plots in the
#' middle 20-80\% band against \strong{61\%} for the SEM index. An index that
#' calls almost everything "medium" cannot inform a decision, no matter how
#' well it correlates with anything else. \strong{Correlation is the wrong
#' diagnostic for an index; the distribution across decision categories is the
#' right one.}
#'
#' A warning is raised when the middle-band share exceeds
#' \code{middle_band_threshold}, because a silent number gets ignored.
#'
#' \strong{2. Sensitivity index.} \eqn{SI = \max(SQI) / \min(SQI)}, after
#' Rezaee et al. via Yuan (2026). A larger value means the index spreads
#' samples further apart. For reference, Yuan's observed ranges across method
#' combinations were: area 1.12-2.92, weighted 1.14-1.82, non-linear scoring
#' 1.21-2.92, linear scoring 1.14-2.49, network-analysis MDS 1.30-2.92, PCA
#' MDS 1.14-2.72.
#'
#' \strong{3. Fidelity to the total data set.} The R-squared of
#' \code{lm(sqi ~ tds)}, where the TDS index uses every measured indicator
#' (see the \code{select = "none"} argument of \code{\link{compute_sqi_df}}).
#' \strong{The TDS index is not ground truth.} It is simply the index with
#' everything in it. High fidelity means your reduced index is faithful to
#' your full measurement set -- not that either one is correct.
#'
#' \strong{4. External criterion (optional).} Correlation against an
#' independently measured outcome such as crop yield. This is the only
#' diagnostic here that involves information from outside the index, which
#' makes it the strongest evidence available -- and the rarest. Theresa et al.
#' (2026) validate against four seasons of rice yield.
#'
#' @param x An \code{sqi_result} object (from \code{\link{compute_sqi_df}} and
#'   friends) or a plain numeric vector of index values.
#' @param tds Optional total-data-set index for the fidelity metric: an
#'   \code{sqi_result} or numeric vector of the same length as \code{x}. Build
#'   one with \code{compute_sqi_df(data, select = "none")}.
#' @param external Optional numeric vector of an independently measured
#'   outcome (yield, a known contrast) of the same length as \code{x}.
#' @param external_method Correlation method for the external criterion,
#'   passed to \code{\link[stats]{cor.test}}. One of \code{"pearson"} (the
#'   default), \code{"spearman"} or \code{"kendall"}.
#' @param bands Numeric vector of band boundaries on the index scale.
#'   Defaults to the conventional five soil-health categories,
#'   \code{c(0, 0.2, 0.4, 0.6, 0.8, 1)}.
#' @param middle_band_threshold Share of samples in the middle bands above
#'   which a warning is raised. Defaults to 0.8. Set to \code{NA} to disable
#'   the warning while still reporting the number.
#'
#' @return An object of class \code{sqi_validation}, a list with:
#'   \describe{
#'     \item{n}{Number of non-missing index values}
#'     \item{distribution}{Data frame of band, count and proportion}
#'     \item{middle_band_share}{Share of samples outside the extreme bands}
#'     \item{sensitivity}{The sensitivity index, max/min}
#'     \item{fidelity}{List with \code{r_squared} and \code{n}, or NULL}
#'     \item{external}{List with \code{estimate}, \code{p_value} and
#'       \code{method}, or NULL}
#'     \item{range}{Named numeric vector of min, max, mean and sd}
#'     \item{out_of_bands}{Count of values falling outside \code{bands}}
#'   }
#'
#' @references
#' Maaz, T. M. et al. (2023) -- validation by distribution.
#' Yuan, X. and Shi, Y. (2026) -- sensitivity index, fidelity to the TDS.
#' Theresa, M. et al. (2026) -- yield as an external validator.
#'
#' @examples
#' props <- c("pH", "OM", "N", "P", "K", "CEC", "BD")
#' result <- compute_sqi_properties(soil_data, properties = props,
#'                                  id_column = "SampleID")
#'
#' # The distribution alone
#' sqi_validate(result)
#'
#' # With fidelity against the total data set
#' tds <- compute_sqi_df(soil_data[, c("SampleID", props)],
#'                       id_column = "SampleID", select = "none")
#' sqi_validate(result, tds = tds)
#'
#' @seealso \code{\link{sqi_compare}} to check whether conclusions survive a
#'   change of recipe; \code{\link{plot_sqi_validation}} for the distribution
#'   plot
#'
#' @export
sqi_validate <- function(x,
                         tds = NULL,
                         external = NULL,
                         external_method = c("pearson", "spearman", "kendall"),
                         bands = c(0, 0.2, 0.4, 0.6, 0.8, 1),
                         middle_band_threshold = 0.8) {
  external_method <- match.arg(external_method)

  sqi <- .extract_sqi(x, "x")
  sqi <- sqi[!is.na(sqi)]

  if (length(sqi) < 2) {
    stop("At least 2 non-missing index values are needed to validate an index")
  }

  if (!is.numeric(bands) || length(bands) < 3 || is.unsorted(bands)) {
    stop("bands must be an increasing numeric vector of at least 3 boundaries")
  }

  # ---- 1. Distribution across decision categories --------------------------
  #
  # The bands are on the INDEX VALUE scale, not on the empirical CDF. Cutting
  # ecdf(sqi)(sqi) into equal bands would return a uniform distribution by
  # construction -- n/5 in every band, for every index -- and could never show
  # the contrast this diagnostic exists to reveal.
  band_labels <- .band_labels(bands)
  binned <- cut(sqi, breaks = bands, include.lowest = TRUE, labels = band_labels)

  out_of_bands <- sum(is.na(binned))
  if (out_of_bands > 0) {
    warning(out_of_bands, " of ", length(sqi), " index values fall outside ",
            "the band range [", min(bands), ", ", max(bands), "] and are ",
            "excluded from the distribution. An area-based index computed ",
            "without a reference soil is not on a [0,1] scale; pass ",
            "different `bands`, or use the ratio form.")
  }

  counts <- as.integer(table(binned))
  n_binned <- sum(counts)

  distribution <- data.frame(
    band = band_labels,
    count = counts,
    proportion = if (n_binned > 0) counts / n_binned else rep(NA_real_, length(counts)),
    stringsAsFactors = FALSE
  )

  # The middle-band share is everything that is not in the first or last band:
  # the samples the index declines to call clearly good or clearly bad.
  middle_idx <- seq_along(counts)[-c(1, length(counts))]
  middle_band_share <- if (n_binned > 0) sum(counts[middle_idx]) / n_binned else NA_real_

  if (!is.na(middle_band_threshold) && !is.na(middle_band_share) &&
      middle_band_share > middle_band_threshold) {
    warning(sprintf(
      paste0("%.0f%% of samples fall in the middle bands (threshold %.0f%%). ",
             "An index that declines to separate samples cannot inform a ",
             "decision, however well it correlates with anything else. ",
             "Consider a scoring or aggregation route that discriminates ",
             "more strongly -- see sqi_compare()."),
      100 * middle_band_share, 100 * middle_band_threshold
    ), call. = FALSE)
  }

  # ---- 2. Sensitivity index -------------------------------------------------
  min_sqi <- min(sqi)
  max_sqi <- max(sqi)

  sensitivity <- if (min_sqi == 0) {
    warning("The minimum index value is 0, so the sensitivity index ",
            "max/min is undefined (reported as Inf).")
    Inf
  } else {
    max_sqi / min_sqi
  }

  # ---- 3. Fidelity to the total data set ------------------------------------
  fidelity <- NULL
  if (!is.null(tds)) {
    tds_values <- .extract_sqi(tds, "tds")

    if (length(tds_values) != length(.extract_sqi(x, "x"))) {
      stop("tds has ", length(tds_values), " values but x has ",
           length(.extract_sqi(x, "x")), ". Fidelity compares two indices ",
           "computed over the same samples.")
    }

    both <- stats::complete.cases(.extract_sqi(x, "x"), tds_values)
    if (sum(both) < 3) {
      stop("At least 3 paired non-missing values are needed for the fidelity ",
           "regression")
    }

    fit <- stats::lm(.extract_sqi(x, "x")[both] ~ tds_values[both])
    fidelity <- list(
      r_squared = summary(fit)$r.squared,
      n = sum(both)
    )
  }

  # ---- 4. External criterion ------------------------------------------------
  ext <- NULL
  if (!is.null(external)) {
    if (!is.numeric(external)) {
      stop("external must be a numeric vector")
    }

    sqi_full <- .extract_sqi(x, "x")
    if (length(external) != length(sqi_full)) {
      stop("external has ", length(external), " values but x has ",
           length(sqi_full), "; they must describe the same samples")
    }

    both <- stats::complete.cases(sqi_full, external)
    if (sum(both) < 3) {
      stop("At least 3 paired non-missing values are needed to correlate ",
           "against an external criterion")
    }

    ct <- suppressWarnings(
      stats::cor.test(sqi_full[both], external[both], method = external_method)
    )
    ext <- list(
      estimate = unname(ct$estimate),
      p_value = ct$p.value,
      method = external_method,
      n = sum(both)
    )
  }

  structure(
    list(
      n = length(sqi),
      distribution = distribution,
      middle_band_share = middle_band_share,
      middle_band_threshold = middle_band_threshold,
      sensitivity = sensitivity,
      fidelity = fidelity,
      external = ext,
      range = c(min = min_sqi, max = max_sqi,
                mean = mean(sqi), sd = stats::sd(sqi)),
      out_of_bands = out_of_bands,
      bands = bands
    ),
    class = "sqi_validation"
  )
}


#' Print method for sqi_validation objects
#'
#' Surfaces the distribution across decision categories first, because that is
#' the diagnostic most likely to change a conclusion and the one most likely
#' to be ignored if buried.
#'
#' @param x An \code{sqi_validation} object
#' @param ... Additional arguments (not used)
#'
#' @return Invisibly returns the input object
#'
#' @export
print.sqi_validation <- function(x, ...) {
  cat("Soil Quality Index validation\n")
  cat("  Samples:", x$n, "\n\n")

  cat("Distribution across decision categories\n")
  for (i in seq_len(nrow(x$distribution))) {
    prop <- x$distribution$proportion[i]
    bar <- strrep("#", round(prop * 40))
    cat(sprintf("  %-14s %4d  %5.1f%%  %s\n",
                x$distribution$band[i],
                x$distribution$count[i],
                100 * prop,
                bar))
  }

  cat(sprintf("\n  Middle bands: %.1f%% of samples\n",
              100 * x$middle_band_share))

  if (!is.na(x$middle_band_threshold) &&
      x$middle_band_share > x$middle_band_threshold) {
    cat(sprintf(paste0("  WARNING: above the %.0f%% threshold. This index ",
                       "declines to separate\n           most samples, so it ",
                       "cannot inform a decision.\n"),
                100 * x$middle_band_threshold))
  }

  if (x$out_of_bands > 0) {
    cat(sprintf("  NOTE: %d values fell outside the band range and were excluded.\n",
                x$out_of_bands))
  }

  cat("\nSensitivity index (max/min): ", format(x$sensitivity, digits = 3), "\n",
      sep = "")
  cat(sprintf("  Range: %.4f to %.4f (mean %.4f, sd %.4f)\n",
              x$range[["min"]], x$range[["max"]],
              x$range[["mean"]], x$range[["sd"]]))

  if (!is.null(x$fidelity)) {
    cat(sprintf("\nFidelity to the total data set: R-squared = %.4f (n = %d)\n",
                x$fidelity$r_squared, x$fidelity$n))
    cat("  The TDS index is not ground truth; it is the index with everything\n")
    cat("  in it. High fidelity means faithful to your full measurement set.\n")
  }

  if (!is.null(x$external)) {
    cat(sprintf("\nExternal criterion (%s): r = %.4f, p = %.4g (n = %d)\n",
                x$external$method, x$external$estimate,
                x$external$p_value, x$external$n))
  }

  invisible(x)
}


#' Compare Soil Quality Indices computed by different recipes
#'
#' Runs the same samples through two or more index recipes and reports whether
#' the \strong{ranking of samples survives}. This is the practical question
#' behind most methodological disagreements in the literature: it usually does
#' not matter which scoring or aggregation route is "better" in the abstract,
#' it matters whether your conclusion changes when you switch.
#'
#' @details
#' For every pair of indices the Spearman rank correlation is reported, along
#' with a flag for whether the best-ranked and worst-ranked sample stay the
#' same. A high rank correlation with a changed top sample is still a changed
#' conclusion if the top sample is what you act on.
#'
#' Yuan (2026) used this kind of stability as a selection criterion in its own
#' right: the EMDS route achieved fidelity R-squared of 0.74-0.77 with no
#' combination of scoring and aggregation producing p > 0.05 -- that is, it
#' was \strong{stable}, not merely accurate.
#'
#' @param ... Two or more \code{sqi_result} objects or numeric vectors, all of
#'   the same length. Name them (e.g. \code{linear = }, \code{sigmoid = }) and
#'   the names are used in the report.
#' @param labels Optional character vector of names, overriding those taken
#'   from \code{...}.
#'
#' @return An object of class \code{sqi_comparison}, a list with:
#'   \describe{
#'     \item{n}{Number of samples}
#'     \item{indices}{Named list of the index vectors compared}
#'     \item{pairs}{Data frame with one row per pair: the two labels, the
#'       Spearman rho, and whether the top and bottom samples are preserved}
#'     \item{stable}{TRUE when every pair preserves both extremes}
#'   }
#'
#' @examples
#' props <- c("pH", "OM", "N", "P", "K", "CEC", "BD")
#'
#' linear <- compute_sqi_properties(
#'   soil_data, properties = props, id_column = "SampleID",
#'   scoring_rules = standard_scoring_rules(props, scoring = "linear")
#' )
#' sigmoid <- compute_sqi_properties(
#'   soil_data, properties = props, id_column = "SampleID",
#'   scoring_rules = standard_scoring_rules(props, scoring = "sigmoid")
#' )
#'
#' sqi_compare(linear = linear, sigmoid = sigmoid)
#'
#' @seealso \code{\link{sqi_validate}} to assess a single index
#'
#' @export
sqi_compare <- function(..., labels = NULL) {
  inputs <- list(...)

  if (length(inputs) < 2) {
    stop("sqi_compare() needs at least 2 indices to compare (got ",
         length(inputs), ")")
  }

  if (is.null(labels)) {
    labels <- names(inputs)
    if (is.null(labels) || any(labels == "")) {
      labels <- paste0("index_", seq_along(inputs))
    }
  }

  if (length(labels) != length(inputs)) {
    stop("labels has ", length(labels), " entries but ", length(inputs),
         " indices were supplied")
  }

  indices <- lapply(seq_along(inputs), function(i) {
    .extract_sqi(inputs[[i]], labels[i])
  })
  names(indices) <- labels

  lengths_seen <- vapply(indices, length, integer(1))
  if (length(unique(lengths_seen)) > 1) {
    stop("All indices must describe the same samples, but their lengths ",
         "differ: ",
         paste(sprintf("%s = %d", labels, lengths_seen), collapse = ", "))
  }

  pair_idx <- utils::combn(seq_along(indices), 2)

  pairs <- do.call(rbind, lapply(seq_len(ncol(pair_idx)), function(k) {
    i <- pair_idx[1, k]
    j <- pair_idx[2, k]
    a <- indices[[i]]
    b <- indices[[j]]

    both <- stats::complete.cases(a, b)

    rho <- if (sum(both) >= 3) {
      suppressWarnings(stats::cor(a[both], b[both], method = "spearman"))
    } else {
      NA_real_
    }

    data.frame(
      a = labels[i],
      b = labels[j],
      spearman = rho,
      top_preserved = which.max(a) == which.max(b),
      bottom_preserved = which.min(a) == which.min(b),
      stringsAsFactors = FALSE
    )
  }))

  structure(
    list(
      n = length(indices[[1]]),
      indices = indices,
      pairs = pairs,
      stable = all(pairs$top_preserved & pairs$bottom_preserved)
    ),
    class = "sqi_comparison"
  )
}


#' Print method for sqi_comparison objects
#'
#' @param x An \code{sqi_comparison} object
#' @param ... Additional arguments (not used)
#'
#' @return Invisibly returns the input object
#'
#' @export
print.sqi_comparison <- function(x, ...) {
  cat("Soil Quality Index recipe comparison\n")
  cat("  Samples:", x$n, "\n")
  cat("  Indices:", paste(names(x$indices), collapse = ", "), "\n\n")

  cat("Pairwise rank agreement\n")
  for (i in seq_len(nrow(x$pairs))) {
    p <- x$pairs[i, ]
    cat(sprintf("  %-12s vs %-12s  rho = %6.3f   top %s   bottom %s\n",
                p$a, p$b, p$spearman,
                if (p$top_preserved) "kept   " else "CHANGED",
                if (p$bottom_preserved) "kept" else "CHANGED"))
  }

  cat("\n")
  if (x$stable) {
    cat("  Both extremes are preserved across every pair: the choice of\n")
    cat("  recipe does not change which sample is best or worst.\n")
  } else {
    cat("  At least one pair disagrees on the best or worst sample. A high\n")
    cat("  rank correlation does not rescue this if the extreme is what you\n")
    cat("  act on.\n")
  }

  invisible(x)
}


# Internal: accept either an sqi_result or a bare numeric vector.
.extract_sqi <- function(x, arg_name) {
  if (inherits(x, "sqi_result")) {
    if (is.null(x$results) || is.null(x$results$SQI)) {
      stop(arg_name, " is an sqi_result but carries no SQI column")
    }
    return(x$results$SQI)
  }

  if (is.numeric(x)) {
    return(x)
  }

  stop(arg_name, " must be an sqi_result object or a numeric vector (got ",
       class(x)[1], ")")
}


# Internal: human-readable labels for the band boundaries.
.band_labels <- function(bands) {
  n <- length(bands) - 1L

  # The conventional five soil-health categories get their conventional names.
  if (n == 5L && isTRUE(all.equal(bands, c(0, 0.2, 0.4, 0.6, 0.8, 1)))) {
    return(c("very low", "low", "medium", "high", "very high"))
  }

  sprintf("%g-%g", bands[-length(bands)], bands[-1])
}

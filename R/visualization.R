#' Plot SQI Results
#'
#' S3 plot method for sqi_result objects. Provides multiple visualization
#' types to explore and communicate Soil Quality Index results and analysis
#' components.
#'
#' @param x An object of class "sqi_result" returned by
#'   \code{\link{compute_sqi}}, \code{\link{compute_sqi_df}}, or
#'   \code{\link{compute_sqi_properties}}.
#' @param type Character string specifying the plot type. Options are:
#'   \describe{
#'     \item{"distribution"}{Histogram of SQI values with mean line}
#'     \item{"indicators"}{Boxplots of indicator scores}
#'     \item{"weights"}{Bar chart of AHP weights with CR annotation}
#'     \item{"scree"}{Variance explained by PCs with cumulative line}
#'     \item{"biplot"}{PCA biplot of observations and variables}
#'   }
#' @param ... Additional graphical parameters passed to plotting functions.
#'
#' @return NULL (invisibly). The function is called for its side effect of
#'   creating a plot.
#'
#' @details
#' The function creates different visualizations based on the \code{type}
#' parameter:
#'
#' \strong{Distribution Plot:} Shows the distribution of SQI values across
#' all samples using a histogram. A vertical line indicates the mean SQI.
#'
#' \strong{Indicators Plot:} Displays boxplots for each scored indicator,
#' allowing comparison of score distributions across different soil
#' properties.
#'
#' \strong{Weights Plot:} Shows the AHP weights assigned to each indicator
#' as a bar chart. The Consistency Ratio (CR) is annotated on the plot.
#'
#' \strong{Scree Plot:} Displays the proportion of variance explained by
#' each principal component, with both individual (bars) and cumulative
#' (line) variance shown.
#'
#' \strong{Biplot:} Creates a PCA biplot showing both observations (points)
#' and variable loadings (arrows), useful for understanding relationships
#' between samples and soil properties.
#'
#' @examples
#' # Create example data
#' soil_data <- data.frame(
#'   SampleID = paste0("S", 1:20),
#'   Sand = rnorm(20, 45, 10),
#'   Silt = rnorm(20, 30, 5),
#'   Clay = rnorm(20, 25, 5),
#'   pH = rnorm(20, 6.5, 0.5),
#'   OM = rnorm(20, 3, 0.5)
#' )
#'
#' # Compute SQI
#' result <- compute_sqi_df(soil_data, id_column = "SampleID")
#'
#' # Distribution plot
#' plot(result, type = "distribution")
#'
#' # Indicators plot
#' plot(result, type = "indicators")
#'
#' # Weights plot
#' plot(result, type = "weights")
#'
#' # Scree plot
#' plot(result, type = "scree")
#'
#' # Biplot
#' plot(result, type = "biplot")
#'
#' @seealso \code{\link{plot_sqi_report}} for multi-panel visualization,
#'   \code{\link{compute_sqi}}, \code{\link{compute_sqi_df}},
#'   \code{\link{compute_sqi_properties}}
#'
#' @export
plot.sqi_result <- function(x, type = c("distribution", "indicators",
                                        "weights", "scree", "biplot"),
                           ...) {
  # Validate input
  if (!inherits(x, "sqi_result")) {
    stop("x must be an sqi_result object")
  }

  # Match and validate plot type
  type <- match.arg(type)

  # Dispatch to appropriate plotting function
  switch(type,
         distribution = plot_sqi_distribution(x, ...),
         indicators = plot_sqi_indicators(x, ...),
         weights = plot_sqi_weights(x, ...),
         scree = plot_sqi_scree(x, ...),
         biplot = plot_sqi_biplot(x, ...))

  invisible(NULL)
}


#' Plot SQI Distribution
#'
#' Internal function to create histogram of SQI values.
#'
#' @param x An sqi_result object.
#' @param ... Additional graphical parameters.
#'
#' @return NULL (invisibly).
#' @keywords internal
#' @noRd
plot_sqi_distribution <- function(x, ...) {
  sqi_values <- x$results$SQI

  # Create histogram
  hist(sqi_values,
       main = "Distribution of Soil Quality Index",
       xlab = "SQI",
       ylab = "Frequency",
       col = "lightblue",
       border = "white",
       las = 1,
       ...)

  # Add mean line
  mean_sqi <- mean(sqi_values, na.rm = TRUE)
  abline(v = mean_sqi, col = "red", lwd = 2, lty = 2)

  # Add legend
  legend("topright",
         legend = paste("Mean =", round(mean_sqi, 3)),
         col = "red",
         lty = 2,
         lwd = 2,
         bty = "n")

  invisible(NULL)
}


#' Plot Indicator Scores
#'
#' Internal function to create boxplots of indicator scores.
#'
#' @param x An sqi_result object.
#' @param ... Additional graphical parameters.
#'
#' @return NULL (invisibly).
#' @keywords internal
#' @noRd
plot_sqi_indicators <- function(x, ...) {
  # Get scored column names
  scored_cols <- paste0(x$mds, "_scored")

  # Extract scored data
  scored_data <- x$results[, scored_cols, drop = FALSE]

  # Create boxplot
  boxplot(scored_data,
          main = "Distribution of Indicator Scores",
          ylab = "Score",
          xlab = "Indicator",
          col = "lightgreen",
          border = "darkgreen",
          las = 2,
          names = x$mds,
          ...)

  # Add reference line at 0.5
  abline(h = 0.5, col = "gray", lty = 2)

  invisible(NULL)
}


#' Plot AHP Weights
#'
#' Internal function to create bar chart of AHP weights.
#'
#' @param x An sqi_result object.
#' @param ... Additional graphical parameters.
#'
#' @return NULL (invisibly).
#' @keywords internal
#' @noRd
plot_sqi_weights <- function(x, ...) {
  weights <- x$weights
  CR <- x$CR

  # Create bar plot
  barplot(weights,
          main = "AHP Indicator Weights",
          ylab = "Weight",
          xlab = "Indicator",
          col = "coral",
          border = "darkred",
          las = 2,
          ylim = c(0, max(weights) * 1.2),
          ...)

  # Add CR annotation
  cr_text <- paste0("CR = ", round(CR, 4))
  cr_status <- if (CR <= 0.1) " (Consistent)" else " (Inconsistent)"
  cr_color <- if (CR <= 0.1) "darkgreen" else "red"

  mtext(paste0(cr_text, cr_status),
        side = 3,
        line = 0.5,
        col = cr_color,
        font = 2)

  invisible(NULL)
}


#' Plot Scree Plot
#'
#' Internal function to create scree plot showing variance explained.
#'
#' @param x An sqi_result object.
#' @param ... Additional graphical parameters.
#'
#' @return NULL (invisibly).
#' @keywords internal
#' @noRd
plot_sqi_scree <- function(x, ...) {
  var_exp <- x$var_exp
  n_pcs <- length(var_exp)
  pc_labels <- paste0("PC", 1:n_pcs)

  # Calculate cumulative variance
  cum_var <- cumsum(var_exp)

  # Create bar plot for individual variance
  bp <- barplot(var_exp,
                main = "PCA Variance Explained",
                ylab = "Proportion of Variance",
                xlab = "Principal Component",
                col = "skyblue",
                border = "darkblue",
                names.arg = pc_labels,
                las = 2,
                ylim = c(0, max(c(var_exp, cum_var)) * 1.1),
                ...)

  # Add cumulative variance line
  lines(bp, cum_var, col = "red", lwd = 2, type = "b", pch = 19)

  # Add legend
  legend("topright",
         legend = c("Individual", "Cumulative"),
         col = c("skyblue", "red"),
         lwd = c(10, 2),
         pch = c(NA, 19),
         bty = "n")

  invisible(NULL)
}


#' Plot PCA Biplot
#'
#' Internal function to create PCA biplot.
#'
#' @param x An sqi_result object.
#' @param ... Additional graphical parameters.
#'
#' @return NULL (invisibly).
#' @keywords internal
#' @noRd
plot_sqi_biplot <- function(x, ...) {
  pca_obj <- x$pca

  # Create biplot using base R
  biplot(pca_obj,
         main = "PCA Biplot",
         col = c("gray50", "red"),
         cex = c(0.6, 0.8),
         arrow.len = 0.1,
         xlabs = rep(".", nrow(pca_obj$x)),
         ...)

  invisible(NULL)
}


#' Create Multi-Panel SQI Report
#'
#' Creates a comprehensive 2x2 multi-panel visualization showing multiple
#' aspects of the SQI analysis results. This function provides a quick
#' overview of the analysis by displaying distribution, indicators, weights,
#' and scree plots together.
#'
#' @param sqi_result An object of class "sqi_result" returned by
#'   \code{\link{compute_sqi}}, \code{\link{compute_sqi_df}}, or
#'   \code{\link{compute_sqi_properties}}.
#' @param ... Additional graphical parameters passed to individual plot
#'   functions.
#'
#' @return NULL (invisibly). The function is called for its side effect of
#'   creating a multi-panel plot.
#'
#' @details
#' The function creates a 2x2 grid layout containing:
#' \enumerate{
#'   \item Top-left: SQI distribution histogram
#'   \item Top-right: Indicator scores boxplots
#'   \item Bottom-left: AHP weights bar chart
#'   \item Bottom-right: PCA scree plot
#' }
#'
#' The graphics parameters are automatically saved and restored after
#' plotting, so the function does not affect subsequent plots.
#'
#' @examples
#' # Create example data
#' soil_data <- data.frame(
#'   SampleID = paste0("S", 1:20),
#'   Sand = rnorm(20, 45, 10),
#'   Silt = rnorm(20, 30, 5),
#'   Clay = rnorm(20, 25, 5),
#'   pH = rnorm(20, 6.5, 0.5),
#'   OM = rnorm(20, 3, 0.5)
#' )
#'
#' # Compute SQI
#' result <- compute_sqi_df(soil_data, id_column = "SampleID")
#'
#' # Create comprehensive report
#' plot_sqi_report(result)
#'
#' @seealso \code{\link{plot.sqi_result}} for individual plot types,
#'   \code{\link{compute_sqi}}, \code{\link{compute_sqi_df}},
#'   \code{\link{compute_sqi_properties}}
#'
#' @export
plot_sqi_report <- function(sqi_result, ...) {
  # Validate input
  if (!inherits(sqi_result, "sqi_result")) {
    stop("sqi_result must be an sqi_result object")
  }

  # Save current graphics parameters
  old_par <- par(no.readonly = TRUE)
  on.exit(par(old_par))

  # Set up 2x2 layout
  par(mfrow = c(2, 2), mar = c(5, 4, 4, 2) + 0.1)

  # Create four plots
  plot(sqi_result, type = "distribution", ...)
  plot(sqi_result, type = "indicators", ...)
  plot(sqi_result, type = "weights", ...)
  plot(sqi_result, type = "scree", ...)

  invisible(NULL)
}

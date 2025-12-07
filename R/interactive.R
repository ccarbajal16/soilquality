#' Launch Interactive Soil Quality Index Calculator
#'
#' Launches a Shiny web application that provides an interactive graphical
#' interface for computing Soil Quality Index (SQI). The app allows users
#' to upload data, select properties, configure scoring rules, and visualize
#' results without writing code.
#'
#' @param launch.browser Logical value indicating whether to launch the app
#'   in the system's default web browser. If TRUE (default), the app opens
#'   in a browser window. If FALSE, the app URL is printed to the console
#'   and can be opened manually.
#' @param ... Additional arguments passed to \code{shiny::runApp()}, such as
#'   \code{port} to specify a custom port number, or \code{host} to specify
#'   the host IP address.
#'
#' @return This function does not return a value. It runs the Shiny
#'   application until the user stops it (typically by closing the browser
#'   window or pressing Ctrl+C in the R console).
#'
#' @details
#' The Shiny application provides the following features:
#' \itemize{
#'   \item File upload for soil data CSV files
#'   \item Property selection (auto-detect, pre-defined sets, or custom)
#'   \item Scoring rule configuration (standard rules or all higher-better)
#'   \item AHP weight specification (equal weights or upload matrix)
#'   \item Interactive results display with summary statistics
#'   \item Multiple visualization types (distribution, indicators, weights,
#'     scree plot)
#'   \item Download results as CSV file
#' }
#'
#' The app is located in the package's \code{inst/shiny/} directory and is
#' automatically installed with the package. If the app directory cannot be
#' found, an error is raised indicating improper installation.
#'
#' To stop the app, close the browser window and press Ctrl+C (or Esc) in
#' the R console, or click the stop button in RStudio.
#'
#' @examples
#' \dontrun{
#' # Launch the app in default browser
#' run_sqi_app()
#'
#' # Launch without opening browser (print URL only)
#' run_sqi_app(launch.browser = FALSE)
#'
#' # Launch on a specific port
#' run_sqi_app(port = 8080)
#' }
#'
#' @seealso \code{\link{compute_sqi}}, \code{\link{compute_sqi_properties}}
#'
#' @export
run_sqi_app <- function(launch.browser = TRUE, ...) {
  # Locate the Shiny app directory
  app_dir <- system.file("shiny", package = "soilquality")
  
  # Validate that app directory exists
  if (app_dir == "") {
    stop("Shiny app not found. The package may not be properly installed.\n",
         "Try reinstalling the package with: install.packages('soilquality')")
  }
  
  # Check that app.R exists in the directory
  app_file <- file.path(app_dir, "app.R")
  if (!file.exists(app_file)) {
    stop("Shiny app file (app.R) not found in: ", app_dir, "\n",
         "The package installation may be incomplete.")
  }
  
  # Check if shiny package is available
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("The 'shiny' package is required to run the interactive app.\n",
         "Install it with: install.packages('shiny')")
  }
  
  # Launch the Shiny app
  message("Launching Soil Quality Index Calculator...")
  message("App location: ", app_dir)
  message("To stop the app, close the browser and press Ctrl+C (or Esc)")
  
  shiny::runApp(
    appDir = app_dir,
    launch.browser = launch.browser,
    ...
  )
}

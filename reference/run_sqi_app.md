# Launch Interactive Soil Quality Index Calculator

Launches a Shiny web application that provides an interactive graphical
interface for computing Soil Quality Index (SQI). The app allows users
to upload data, select properties, configure scoring rules, and
visualize results without writing code.

## Usage

``` r
run_sqi_app(launch.browser = TRUE, ...)
```

## Arguments

- launch.browser:

  Logical value indicating whether to launch the app in the system's
  default web browser. If TRUE (default), the app opens in a browser
  window. If FALSE, the app URL is printed to the console and can be
  opened manually.

- ...:

  Additional arguments passed to
  [`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html), such
  as `port` to specify a custom port number, or `host` to specify the
  host IP address.

## Value

This function does not return a value. It runs the Shiny application
until the user stops it (typically by closing the browser window or
pressing Ctrl+C in the R console).

## Details

The Shiny application provides the following features:

- File upload for soil data CSV files

- Property selection (auto-detect, pre-defined sets, or custom)

- Scoring rule configuration (standard rules or all higher-better)

- AHP weight specification (equal weights or upload matrix)

- Interactive results display with summary statistics

- Multiple visualization types (distribution, indicators, weights, scree
  plot)

- Download results as CSV file

The app is located in the package's `inst/shiny/` directory and is
automatically installed with the package. If the app directory cannot be
found, an error is raised indicating improper installation.

To stop the app, close the browser window and press Ctrl+C (or Esc) in
the R console, or click the stop button in RStudio.

## See also

[`compute_sqi`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi.md),
[`compute_sqi_properties`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_properties.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Launch the app in default browser
run_sqi_app()

# Launch without opening browser (print URL only)
run_sqi_app(launch.browser = FALSE)

# Launch on a specific port
run_sqi_app(port = 8080)
} # }
```

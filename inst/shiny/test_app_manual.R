# Manual Test Script for Shiny App
# This script can be run manually to test the Shiny app functionality
#
# To test the app:
# 1. Install the package: devtools::install("path/to/soilquality")
# 2. Load the package: library(soilquality)
# 3. Run the app: run_sqi_app()
#
# Expected behavior:
# - App should launch in default browser
# - UI should display with 4 sections: Upload Data, Select Properties,
#   Scoring Rules, AHP Weights
# - After uploading a CSV file, properties should be detected
# - Compute button should trigger SQI calculation
# - Results should display in tabs: Summary, Results Data, Visualizations
# - Download button should save results as CSV
#
# Test data can be created with:
# soil_data <- data.frame(
#   SampleID = paste0("S", 1:20),
#   Sand = rnorm(20, 45, 10),
#   Silt = rnorm(20, 30, 5),
#   Clay = rnorm(20, 25, 5),
#   pH = rnorm(20, 6.5, 0.5),
#   OM = rnorm(20, 3, 0.5),
#   BD = rnorm(20, 1.4, 0.1)
# )
# write.csv(soil_data, "test_soil_data.csv", row.names = FALSE)

cat("To test the Shiny app:\n")
cat("1. library(soilquality)\n")
cat("2. run_sqi_app()\n")
cat("\nThe app should open in your browser.\n")
cat("Upload a CSV file with soil data to test functionality.\n")

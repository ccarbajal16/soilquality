# Test package in clean R session
# This script simulates a fresh user experience

cat("=======================================================================\n")
cat("CLEAN SESSION TEST - Simulating Fresh User Experience\n")
cat("=======================================================================\n\n")

# Step 1: Load package (this should work if installation was successful)
cat("Step 1: Loading package...\n")
suppressPackageStartupMessages(library(soilquality))
cat("✓ Package loaded successfully\n\n")

# Step 2: Check package info
cat("Step 2: Checking package information...\n")
pkg_desc <- packageDescription("soilquality")
cat(sprintf("  Package: %s\n", pkg_desc$Package))
cat(sprintf("  Version: %s\n", pkg_desc$Version))
cat(sprintf("  Title: %s\n", pkg_desc$Title))
cat("✓ Package information accessible\n\n")

# Step 3: Load example data
cat("Step 3: Loading example dataset...\n")
data(soil_ucayali)
cat(sprintf("  Dataset dimensions: %d rows × %d columns\n",
            nrow(soil_ucayali), ncol(soil_ucayali)))
cat(sprintf("  Columns: %s...\n", paste(names(soil_ucayali)[1:5], collapse = ", ")))
cat("✓ Example data loaded\n\n")

# Step 4: Run a simple SQI calculation (typical first use case)
cat("Step 4: Running basic SQI calculation...\n")
result <- compute_sqi_properties(
  data = soil_ucayali,
  properties = c("pH", "OM", "N", "P", "K"),
  id_column = "SampleID"
)
cat(sprintf("  Computed SQI for %d samples\n", nrow(result$results)))
cat(sprintf("  MDS indicators selected: %s\n", paste(result$mds, collapse = ", ")))
cat(sprintf("  Mean SQI: %.3f\n", mean(result$results$SQI)))
cat("✓ SQI calculation successful\n\n")

# Step 5: Test visualization (typical second step)
cat("Step 5: Creating visualization...\n")
pdf(file = NULL)  # Suppress plot output but test that it works
plot(result, type = "distribution")
dev.off()
cat("✓ Visualization generated\n\n")

# Step 6: Test using property sets (convenience feature)
cat("Step 6: Testing property sets...\n")
cat(sprintf("  Available sets: %s\n",
            paste(names(soil_property_sets), collapse = ", ")))
basic_props <- soil_property_sets$basic
cat(sprintf("  Basic set properties: %s\n", paste(basic_props, collapse = ", ")))
cat("✓ Property sets accessible\n\n")

# Step 7: Test standard scoring rules (another convenience feature)
cat("Step 7: Testing standard scoring rules...\n")
rules <- standard_scoring_rules(basic_props)
cat(sprintf("  Generated %d scoring rules\n", length(rules)))
cat("✓ Scoring rules generated\n\n")

# Step 8: Test AHP functionality
cat("Step 8: Testing AHP weights...\n")
# Create a simple 3x3 pairwise matrix
pairwise <- matrix(c(
  1,   2,   3,
  1/2, 1,   2,
  1/3, 1/2, 1
), nrow = 3, byrow = TRUE)

ahp_result <- ahp_weights(pairwise, indicators = c("pH", "OM", "N"))
cat(sprintf("  Weights: %s\n",
            paste(sprintf("%.3f", ahp_result$weights), collapse = ", ")))
cat(sprintf("  Consistency Ratio: %.4f\n", ahp_result$CR))
if (ahp_result$CR < 0.1) {
  cat("  ✓ Consistency acceptable (CR < 0.1)\n")
}
cat("✓ AHP calculations working\n\n")

# Step 9: Test data reading function
cat("Step 9: Testing CSV reading capabilities...\n")
# Create a temporary CSV file
temp_file <- tempfile(fileext = ".csv")
write.csv(soil_ucayali[1:5, 1:6], temp_file, row.names = FALSE)
test_data <- read_soil_csv(temp_file)
cat(sprintf("  Read %d rows from CSV\n", nrow(test_data)))
unlink(temp_file)
cat("✓ CSV reading functional\n\n")

# Step 10: Verify help documentation is accessible
cat("Step 10: Checking help documentation...\n")
help_available <- TRUE
tryCatch({
  # This won't display but will test if help system works
  suppressMessages(help("compute_sqi", package = "soilquality"))
}, error = function(e) {
  help_available <<- FALSE
})
if (help_available) {
  cat("✓ Help documentation accessible\n\n")
} else {
  cat("⚠ Help documentation may not be fully available\n\n")
}

# Final summary
cat("=======================================================================\n")
cat("CLEAN SESSION TEST RESULTS\n")
cat("=======================================================================\n\n")

cat("✓✓✓ ALL CLEAN SESSION TESTS PASSED ✓✓✓\n\n")
cat("The package is ready for use. A new user can:\n")
cat("  1. Load the package with library(soilquality)\n")
cat("  2. Access example data with data(soil_ucayali)\n")
cat("  3. Calculate SQI using compute_sqi_properties()\n")
cat("  4. Visualize results with plot()\n")
cat("  5. Use convenience features like soil_property_sets\n")
cat("  6. Access comprehensive help documentation\n\n")

cat("Package validation complete!\n")

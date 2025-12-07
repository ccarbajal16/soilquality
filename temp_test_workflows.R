# Test complete workflow examples from vignettes
# This script runs the main examples from all three vignettes

cat("=" , rep("=", 70), "\n", sep = "")
cat("TESTING SOILQUALITY PACKAGE WORKFLOWS\n")
cat("=" , rep("=", 70), "\n", sep = "")

library(soilquality)

# Track test results
tests_passed <- 0
tests_failed <- 0
errors <- list()

test_section <- function(name) {
  cat("\n\n")
  cat("-" , rep("-", 70), "\n", sep = "")
  cat("TEST:", name, "\n")
  cat("-" , rep("-", 70), "\n", sep = "")
}

# ============================================================================
# VIGNETTE 1: Introduction - Basic Workflow
# ============================================================================

test_section("Introduction Vignette - Basic SQI Calculation")

tryCatch({
  # Load the example dataset
  data(soil_ucayali)
  cat("✓ Loaded soil_ucayali dataset\n")
  cat(sprintf("  Dimensions: %d samples × %d properties\n",
              nrow(soil_ucayali), ncol(soil_ucayali)))

  # Calculate SQI using standard fertility properties
  result <- compute_sqi_properties(
    data = soil_ucayali,
    properties = c("pH", "OM", "N", "P", "K", "CEC"),
    id_column = "SampleID"
  )
  cat("✓ Computed SQI successfully\n")

  # Check result components
  cat("\nResult components:\n")
  cat(sprintf("  MDS indicators: %s\n", paste(result$mds, collapse = ", ")))
  cat(sprintf("  Weights: %s\n",
              paste(sprintf("%.3f", result$weights), collapse = ", ")))
  cat(sprintf("  Consistency Ratio: %.4f\n", result$CR))
  cat(sprintf("  Number of samples: %d\n", nrow(result$results)))

  # SQI summary
  cat("\nSQI Summary Statistics:\n")
  print(summary(result$results$SQI))

  # Quality classification
  sqi_values <- result$results$SQI
  quality_class <- cut(sqi_values,
                       breaks = c(0, 0.2, 0.4, 0.6, 0.8, 1.0),
                       labels = c("Very Poor", "Poor", "Moderate",
                                  "Good", "Excellent"))
  cat("\nQuality Classification:\n")
  print(table(quality_class))

  tests_passed <- tests_passed + 1
  cat("\n✓✓✓ PASSED: Basic SQI calculation\n")
}, error = function(e) {
  tests_failed <- tests_failed + 1
  errors <<- append(errors, list(list(test = "Basic SQI", error = e$message)))
  cat(sprintf("\n✗✗✗ FAILED: %s\n", e$message))
})

# ============================================================================
# VIGNETTE 1: Visualization Tests
# ============================================================================

test_section("Introduction Vignette - Visualization")

tryCatch({
  # Test different plot types
  plot_types <- c("distribution", "indicators", "weights", "scree")

  for (plot_type in plot_types) {
    plot(result, type = plot_type)
    cat(sprintf("✓ Generated '%s' plot\n", plot_type))
  }

  tests_passed <- tests_passed + 1
  cat("\n✓✓✓ PASSED: All visualization types\n")
}, error = function(e) {
  tests_failed <- tests_failed + 1
  errors <<- append(errors, list(list(test = "Visualization", error = e$message)))
  cat(sprintf("\n✗✗✗ FAILED: %s\n", e$message))
})

# ============================================================================
# VIGNETTE 2: AHP Matrices
# ============================================================================

test_section("AHP Matrices Vignette - Pairwise Comparisons")

tryCatch({
  # Test creating AHP matrix
  indicators <- c("pH", "OM", "N", "P")

  pairwise <- matrix(c(
    1,   1/3, 1/5, 1/3,  # pH
    3,   1,   1/2, 1,    # OM
    5,   2,   1,   3,    # N
    3,   1,   1/3, 1     # P
  ), nrow = 4, byrow = TRUE)
  colnames(pairwise) <- rownames(pairwise) <- indicators

  ahp_mat <- create_ahp_matrix(pairwise)
  cat("✓ Created AHP matrix\n")
  print(ahp_mat)

  # Calculate weights
  weights_result <- ahp_weights(ahp_mat)
  cat("\n✓ Calculated AHP weights\n")
  cat(sprintf("  Weights: %s\n",
              paste(sprintf("%.3f", weights_result$weights), collapse = ", ")))
  cat(sprintf("  Consistency Ratio: %.4f\n", weights_result$CR))

  if (weights_result$CR < 0.1) {
    cat("  ✓ Consistency is acceptable (CR < 0.1)\n")
  } else {
    cat("  ⚠ Warning: Inconsistent comparisons (CR >= 0.1)\n")
  }

  tests_passed <- tests_passed + 1
  cat("\n✓✓✓ PASSED: AHP matrix creation and weight calculation\n")
}, error = function(e) {
  tests_failed <- tests_failed + 1
  errors <<- append(errors, list(list(test = "AHP Matrices", error = e$message)))
  cat(sprintf("\n✗✗✗ FAILED: %s\n", e$message))
})

# ============================================================================
# Test Property Sets and Standard Scoring Rules
# ============================================================================

test_section("Property Sets and Standard Scoring Rules")

tryCatch({
  # Test soil_property_sets
  cat("Available property sets:\n")
  for (set_name in names(soil_property_sets)) {
    properties <- soil_property_sets[[set_name]]
    cat(sprintf("  %s: %s\n", set_name, paste(properties, collapse = ", ")))
  }

  # Test standard_scoring_rules with property set
  rules <- standard_scoring_rules("basic")
  cat("\n✓ Generated standard scoring rules for 'basic' set\n")
  cat(sprintf("  Number of rules: %d\n", length(rules)))
  cat("  Rules:\n")
  for (prop in names(rules)) {
    cat(sprintf("    %s: %s\n", prop, class(rules[[prop]])[1]))
  }

  # Test with custom properties
  custom_props <- c("pH", "BD", "OM", "Sand")
  rules_custom <- standard_scoring_rules(custom_props)
  cat("\n✓ Generated standard scoring rules for custom properties\n")

  tests_passed <- tests_passed + 1
  cat("\n✓✓✓ PASSED: Property sets and scoring rules\n")
}, error = function(e) {
  tests_failed <- tests_failed + 1
  errors <<- append(errors, list(list(test = "Property Sets", error = e$message)))
  cat(sprintf("\n✗✗✗ FAILED: %s\n", e$message))
})

# ============================================================================
# Test PCA and MDS Selection
# ============================================================================

test_section("PCA and MDS Selection")

tryCatch({
  # Test PCA MDS selection
  data(soil_ucayali)

  # Select comprehensive property set
  properties <- soil_property_sets$standard
  data_subset <- soil_ucayali[, c("SampleID", properties)]

  # Standardize numeric columns
  numeric_cols <- sapply(data_subset[, -1], is.numeric)
  data_standardized <- data_subset
  data_standardized[, -1][, numeric_cols] <- scale(data_subset[, -1][, numeric_cols])

  # Run PCA
  mds_result <- pca_select_mds(data_standardized, id_column = "SampleID")

  cat("✓ Performed PCA and MDS selection\n")
  cat(sprintf("  Original properties: %d\n", length(properties)))
  cat(sprintf("  MDS selected: %d (%s)\n",
              length(mds_result$mds),
              paste(mds_result$mds, collapse = ", ")))
  cat(sprintf("  Variance explained: %.2f%%\n", mds_result$variance_explained * 100))

  tests_passed <- tests_passed + 1
  cat("\n✓✓✓ PASSED: PCA and MDS selection\n")
}, error = function(e) {
  tests_failed <- tests_failed + 1
  errors <<- append(errors, list(list(test = "PCA MDS", error = e$message)))
  cat(sprintf("\n✗✗✗ FAILED: %s\n", e$message))
})

# ============================================================================
# Test Custom Scoring Functions
# ============================================================================

test_section("Custom Scoring Functions")

tryCatch({
  # Test different scoring constructors
  rule1 <- higher_better()
  cat("✓ Created higher_better() rule\n")

  rule2 <- lower_better()
  cat("✓ Created lower_better() rule\n")

  rule3 <- optimum_range(optimal = 7, tolerance = 1)
  cat("✓ Created optimum_range() rule\n")

  rule4 <- threshold_scoring(
    thresholds = c(5.5, 6.0, 7.0, 7.5),
    scores = c(0, 0.5, 1, 0.5, 0)
  )
  cat("✓ Created threshold_scoring() rule\n")

  # Test scoring with sample data
  test_values <- c(5.0, 5.5, 6.0, 6.5, 7.0, 7.5, 8.0)
  scored <- score_optimum(test_values, optimal = 7, tolerance = 1)
  cat(sprintf("\n✓ Scored test values with optimum_range\n"))
  cat(sprintf("  Input range: %.1f - %.1f\n", min(test_values), max(test_values)))
  cat(sprintf("  Score range: %.2f - %.2f\n", min(scored), max(scored)))

  tests_passed <- tests_passed + 1
  cat("\n✓✓✓ PASSED: Custom scoring functions\n")
}, error = function(e) {
  tests_failed <- tests_failed + 1
  errors <<- append(errors, list(list(test = "Scoring Functions", error = e$message)))
  cat(sprintf("\n✗✗✗ FAILED: %s\n", e$message))
})

# ============================================================================
# Final Summary
# ============================================================================

cat("\n\n")
cat("=" , rep("=", 70), "\n", sep = "")
cat("FINAL SUMMARY\n")
cat("=" , rep("=", 70), "\n", sep = "")
cat(sprintf("\nTests Passed: %d\n", tests_passed))
cat(sprintf("Tests Failed: %d\n", tests_failed))

if (tests_failed > 0) {
  cat("\nFailed Tests:\n")
  for (err in errors) {
    cat(sprintf("  - %s: %s\n", err$test, err$error))
  }
  cat("\n✗✗✗ SOME TESTS FAILED ✗✗✗\n")
  stop("Workflow validation failed")
} else {
  cat("\n✓✓✓ ALL WORKFLOW TESTS PASSED ✓✓✓\n")
}

# Tests for SQI computation functions

# Create test data for use across tests
create_test_data <- function(n = 20) {
  set.seed(123)
  data.frame(
    SampleID = paste0("S", 1:n),
    Sand = rnorm(n, 45, 10),
    Silt = rnorm(n, 30, 5),
    Clay = rnorm(n, 25, 5),
    pH = rnorm(n, 6.5, 0.5),
    OM = rnorm(n, 3, 0.5),
    BD = rnorm(n, 1.4, 0.1)
  )
}

test_that("compute_sqi_df returns all expected components", {
  data <- create_test_data()

  result <- compute_sqi_df(data, id_column = "SampleID")

  # Check that result is an sqi_result object
  expect_s3_class(result, "sqi_result")

  # Check that all expected components are present
  expect_true("mds" %in% names(result))
  expect_true("weights" %in% names(result))
  expect_true("CR" %in% names(result))
  expect_true("results" %in% names(result))
  expect_true("pca" %in% names(result))
  expect_true("loadings" %in% names(result))
  expect_true("var_exp" %in% names(result))

  # Check component types
  expect_type(result$mds, "character")
  expect_type(result$weights, "double")
  expect_type(result$CR, "double")
  expect_s3_class(result$results, "data.frame")
  expect_s3_class(result$pca, "prcomp")
  expect_type(result$loadings, "double")
  expect_type(result$var_exp, "double")
})

test_that("compute_sqi_df produces valid SQI values", {
  data <- create_test_data()

  result <- compute_sqi_df(data, id_column = "SampleID")

  # Check that SQI column exists
  expect_true("SQI" %in% names(result$results))

  # Check that all SQI values are in [0,1] range
  expect_true(all(result$results$SQI >= 0))
  expect_true(all(result$results$SQI <= 1))

  # Check that SQI values are not all the same
  expect_true(length(unique(result$results$SQI)) > 1)
})

test_that("compute_sqi_df weights sum to 1", {
  data <- create_test_data()

  result <- compute_sqi_df(data, id_column = "SampleID")

  # Check that weights sum to 1
  expect_equal(sum(result$weights), 1, tolerance = 1e-10)

  # Check that all weights are positive
  expect_true(all(result$weights > 0))
})

test_that("compute_sqi_df preserves ID column", {
  data <- create_test_data()

  result <- compute_sqi_df(data, id_column = "SampleID")

  # Check that ID column is preserved in results
  expect_true("SampleID" %in% names(result$results))

  # Check that ID values match original data
  expect_equal(result$results$SampleID, data$SampleID)
})

test_that("compute_sqi_df works without ID column", {
  data <- create_test_data()
  data_no_id <- data[, -1]  # Remove ID column

  result <- compute_sqi_df(data_no_id)

  # Should still work and return valid results
  expect_s3_class(result, "sqi_result")
  expect_true("SQI" %in% names(result$results))
})

test_that("compute_sqi_df uses equal weights when no pairwise matrix", {
  data <- create_test_data()

  result <- compute_sqi_df(data, id_column = "SampleID")

  # With no pairwise matrix, weights should be equal
  n_indicators <- length(result$mds)
  expected_weight <- 1 / n_indicators

  # Check that all weights are equal (ignoring names)
  expect_equal(as.numeric(result$weights), rep(expected_weight, n_indicators),
               tolerance = 1e-10)

  # CR should be 0 for equal weights
  expect_equal(result$CR, 0)
})

test_that("compute_sqi_df uses provided pairwise matrix", {
  data <- create_test_data()

  # First run to get MDS indicators
  result1 <- compute_sqi_df(data, id_column = "SampleID")
  mds <- result1$mds

  # Create a pairwise matrix for the MDS indicators
  n <- length(mds)
  pairwise <- matrix(1, nrow = n, ncol = n)
  rownames(pairwise) <- mds
  colnames(pairwise) <- mds

  # Make first indicator more important
  if (n >= 2) {
    pairwise[1, 2] <- 3
    pairwise[2, 1] <- 1/3
  }

  result2 <- compute_sqi_df(data, id_column = "SampleID",
                            pairwise_df = pairwise)

  # Weights should not be equal
  if (n >= 2) {
    expect_false(all(result2$weights == result2$weights[1]))
  }

  # CR should be calculated
  expect_type(result2$CR, "double")
})

test_that("compute_sqi_df applies custom scoring directions", {
  data <- create_test_data()

  # First run to get MDS indicators
  result_initial <- compute_sqi_df(data, id_column = "SampleID")
  mds <- result_initial$mds

  # Define custom directions for all MDS indicators
  directions <- list()
  for (indicator in mds) {
    if (indicator == "pH") {
      directions[[indicator]] <- list(type = "optimum", optimum = 7,
                                     tol = 1.5, penalty = "linear")
    } else if (indicator == "BD") {
      directions[[indicator]] <- list(type = "lower")
    } else {
      directions[[indicator]] <- list(type = "higher")
    }
  }

  result <- compute_sqi_df(data, id_column = "SampleID",
                          directions = directions)

  # Check that scored columns exist for all MDS indicators
  for (indicator in result$mds) {
    scored_col <- paste0(indicator, "_scored")
    expect_true(scored_col %in% names(result$results))
  }
})

test_that("compute_sqi_df validates input", {
  # Test with non-data.frame input
  expect_error(compute_sqi_df(list(a = 1, b = 2)),
               "df must be a data frame")

  # Test with invalid ID column
  data <- create_test_data()
  expect_error(compute_sqi_df(data, id_column = "InvalidID"),
               "ID column 'InvalidID' not found in data")
})

test_that("compute_sqi_df handles insufficient indicators", {
  # Create data with only one numeric column
  data <- data.frame(
    ID = c("S1", "S2", "S3"),
    Value = c(1, 2, 3)
  )

  # Should fail because PCA needs at least 2 columns
  expect_error(compute_sqi_df(data, id_column = "ID"))
})

test_that("compute_sqi_properties validates property selection", {
  data <- create_test_data()

  # Test with non-existent properties
  expect_error(
    compute_sqi_properties(data, properties = c("pH", "InvalidProp")),
    "Properties not found in data: InvalidProp"
  )

  # Test with multiple missing properties
  expect_error(
    compute_sqi_properties(data, properties = c("Prop1", "Prop2")),
    "Properties not found in data: Prop1, Prop2"
  )
})

test_that("compute_sqi_properties subsets data correctly", {
  data <- create_test_data()

  # Select only specific properties
  result <- compute_sqi_properties(
    data,
    properties = c("pH", "OM", "BD"),
    id_column = "SampleID"
  )

  # Check that result is valid
  expect_s3_class(result, "sqi_result")

  # MDS should only come from selected properties
  expect_true(all(result$mds %in% c("pH", "OM", "BD")))
})

test_that("compute_sqi_properties auto-detects numeric columns", {
  data <- create_test_data()

  # Don't specify properties - should auto-detect
  result <- compute_sqi_properties(data, id_column = "SampleID")

  # Should work and return valid results
  expect_s3_class(result, "sqi_result")
  expect_true(length(result$mds) > 0)

  # MDS should not include ID column
  expect_false("SampleID" %in% result$mds)
})

test_that("compute_sqi_properties integrates with scoring constructors", {
  data <- create_test_data()

  # Create scoring rules using constructors
  rules <- list(
    pH = optimum_range(optimal = 7, tolerance = 1.5),
    OM = higher_better(),
    BD = lower_better()
  )

  result <- compute_sqi_properties(
    data,
    properties = c("pH", "OM", "BD"),
    id_column = "SampleID",
    scoring_rules = rules
  )

  # Check that result is valid
  expect_s3_class(result, "sqi_result")
  expect_true("SQI" %in% names(result$results))

  # Check that all SQI values are in [0,1]
  expect_true(all(result$results$SQI >= 0 & result$results$SQI <= 1))
})

test_that("compute_sqi_properties validates scoring_rules format", {
  data <- create_test_data()

  # Test with non-list scoring_rules
  expect_error(
    compute_sqi_properties(data, properties = c("pH", "OM"),
                          scoring_rules = "invalid"),
    "scoring_rules must be a named list"
  )

  # Test with unnamed list
  expect_error(
    compute_sqi_properties(data, properties = c("pH", "OM"),
                          scoring_rules = list(higher_better(), lower_better())),
    "scoring_rules must be a named list"
  )
})

test_that("compute_sqi_properties validates scoring_rule objects", {
  data <- create_test_data()

  # Test with non-scoring_rule objects
  rules <- list(
    pH = "not a scoring rule",
    OM = higher_better()
  )

  expect_error(
    compute_sqi_properties(data, properties = c("pH", "OM"),
                          scoring_rules = rules),
    "All elements in scoring_rules must be scoring_rule objects"
  )
})

test_that("compute_sqi_properties works with standard_scoring_rules", {
  data <- create_test_data()

  # Use standard scoring rules
  rules <- standard_scoring_rules(c("pH", "OM", "BD"))

  result <- compute_sqi_properties(
    data,
    properties = c("pH", "OM", "BD"),
    id_column = "SampleID",
    scoring_rules = rules
  )

  # Check that result is valid
  expect_s3_class(result, "sqi_result")
  expect_true("SQI" %in% names(result$results))
})

test_that("compute_sqi_properties validates ID column", {
  data <- create_test_data()

  # Test with invalid ID column
  expect_error(
    compute_sqi_properties(data, properties = c("pH", "OM"),
                          id_column = "InvalidID"),
    "ID column 'InvalidID' not found in data"
  )
})

test_that("compute_sqi_properties handles no numeric columns", {
  # Create data with only character columns
  data <- data.frame(
    ID = c("S1", "S2", "S3"),
    Name = c("A", "B", "C")
  )

  expect_error(
    compute_sqi_properties(data, id_column = "ID"),
    "No numeric columns found in data for analysis"
  )
})

test_that("SQI computation is reproducible", {
  data <- create_test_data()

  result1 <- compute_sqi_df(data, id_column = "SampleID")
  result2 <- compute_sqi_df(data, id_column = "SampleID")

  # Results should be identical
  expect_equal(result1$mds, result2$mds)
  expect_equal(result1$weights, result2$weights)
  expect_equal(result1$CR, result2$CR)
  expect_equal(result1$results$SQI, result2$results$SQI)
})

test_that("compute_sqi_df creates scored columns for all MDS indicators", {
  data <- create_test_data()

  result <- compute_sqi_df(data, id_column = "SampleID")

  # Check that scored columns exist for all MDS indicators
  for (indicator in result$mds) {
    scored_col <- paste0(indicator, "_scored")
    expect_true(scored_col %in% names(result$results),
                info = paste("Missing scored column:", scored_col))
  }
})

test_that("compute_sqi_df validates data frame input", {
  # Test with NULL
  expect_error(compute_sqi_df(NULL), "df must be a data frame")

  # Test with vector
  expect_error(compute_sqi_df(c(1, 2, 3)), "df must be a data frame")

  # Test with matrix
  mat <- matrix(1:12, nrow = 4)
  expect_error(compute_sqi_df(mat), "df must be a data frame")
})

test_that("compute_sqi_properties validates data frame input", {
  # Test with NULL
  expect_error(compute_sqi_properties(NULL), "data must be a data frame")

  # Test with list
  expect_error(compute_sqi_properties(list(a = 1, b = 2)),
               "data must be a data frame")
})


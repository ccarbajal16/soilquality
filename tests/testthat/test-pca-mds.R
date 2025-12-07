# Tests for PCA and MDS selection functions

test_that("pca_select_mds returns correct structure", {
  # Create test data
  test_data <- data.frame(
    prop1 = c(1, 2, 3, 4, 5, 6, 7, 8),
    prop2 = c(2, 4, 6, 8, 10, 12, 14, 16),
    prop3 = c(10, 9, 8, 7, 6, 5, 4, 3),
    prop4 = c(5, 5.5, 6, 6.5, 7, 7.5, 8, 8.5)
  )

  result <- pca_select_mds(test_data)

  # Check that result is a list
  expect_type(result, "list")

  # Check that all expected components are present
  expect_true("mds" %in% names(result))
  expect_true("pca" %in% names(result))
  expect_true("loadings" %in% names(result))
  expect_true("var_exp" %in% names(result))

  # Check types of components
  expect_type(result$mds, "character")
  expect_s3_class(result$pca, "prcomp")
  expect_true(is.matrix(result$loadings))
  expect_type(result$var_exp, "double")
})


test_that("pca_select_mds selects correct number of indicators", {
  # Create test data with clear structure
  set.seed(123)
  test_data <- data.frame(
    prop1 = rnorm(20, 50, 10),
    prop2 = rnorm(20, 30, 5),
    prop3 = rnorm(20, 70, 15),
    prop4 = rnorm(20, 40, 8)
  )

  # Standardize data
  test_std <- standardize_numeric(test_data)

  result <- pca_select_mds(test_std)

  # MDS should contain at least one variable
  expect_true(length(result$mds) >= 1)

  # MDS should not contain more variables than input
  expect_true(length(result$mds) <= ncol(test_data))

  # All MDS variables should be from the original data
  expect_true(all(result$mds %in% names(test_data)))

  # MDS should contain unique variables only
  expect_equal(length(result$mds), length(unique(result$mds)))
})


test_that("pca_select_mds variance threshold filtering works", {
  # Create test data
  set.seed(456)
  test_data <- data.frame(
    prop1 = rnorm(15, 50, 10),
    prop2 = rnorm(15, 30, 5),
    prop3 = rnorm(15, 70, 15)
  )

  test_std <- standardize_numeric(test_data)

  # Test with high variance threshold (should select fewer PCs)
  result_high <- pca_select_mds(test_std, var_threshold = 0.30)

  # Test with low variance threshold (should select more PCs)
  result_low <- pca_select_mds(test_std, var_threshold = 0.01)

  # Higher threshold should select same or fewer indicators
  expect_true(length(result_high$mds) <= length(result_low$mds))

  # Variance explained should sum to 1
  expect_equal(sum(result_high$var_exp), 1, tolerance = 1e-10)
  expect_equal(sum(result_low$var_exp), 1, tolerance = 1e-10)
})


test_that("pca_select_mds loading threshold filtering works", {
  # Create test data
  set.seed(789)
  test_data <- data.frame(
    prop1 = rnorm(15, 50, 10),
    prop2 = rnorm(15, 30, 5),
    prop3 = rnorm(15, 70, 15)
  )

  test_std <- standardize_numeric(test_data)

  # Test with high loading threshold
  result_high <- pca_select_mds(test_std,
                                var_threshold = 0.05,
                                loading_threshold = 0.8)

  # Test with low loading threshold
  result_low <- pca_select_mds(test_std,
                               var_threshold = 0.05,
                               loading_threshold = 0.3)

  # Higher loading threshold should select same or fewer indicators
  expect_true(length(result_high$mds) <= length(result_low$mds))
})


test_that("pca_select_mds handles edge case with all variables selected", {
  # Create data where each variable dominates a different PC
  test_data <- data.frame(
    prop1 = c(10, 11, 12, 13, 14, 15, 16, 17),
    prop2 = c(20, 21, 22, 23, 24, 25, 26, 27),
    prop3 = c(30, 31, 32, 33, 34, 35, 36, 37)
  )

  test_std <- standardize_numeric(test_data)

  # Use very low thresholds to select all
  result <- pca_select_mds(test_std,
                          var_threshold = 0.01,
                          loading_threshold = 0.1)

  # Should select at least some variables
  expect_true(length(result$mds) >= 1)
})


test_that("pca_select_mds handles edge case with no variables selected", {
  # Create test data
  set.seed(321)
  test_data <- data.frame(
    prop1 = rnorm(10, 50, 10),
    prop2 = rnorm(10, 30, 5),
    prop3 = rnorm(10, 70, 15)
  )

  test_std <- standardize_numeric(test_data)

  # Use very high thresholds to potentially select none
  result <- pca_select_mds(test_std,
                          var_threshold = 0.99,
                          loading_threshold = 0.99)

  # MDS should be a character vector (possibly empty)
  expect_type(result$mds, "character")

  # Other components should still be present
  expect_s3_class(result$pca, "prcomp")
  expect_true(is.matrix(result$loadings))
  expect_type(result$var_exp, "double")
})


test_that("pca_select_mds validates input data", {
  # Test with non-data.frame input
  expect_error(pca_select_mds(c(1, 2, 3)),
               "data must be a data frame")

  # Test with no numeric columns
  test_df <- data.frame(
    col1 = c("a", "b", "c"),
    col2 = c("d", "e", "f")
  )
  expect_error(pca_select_mds(test_df),
               "data must contain at least one numeric column")

  # Test with only one numeric column
  test_df <- data.frame(prop1 = c(1, 2, 3))
  expect_error(pca_select_mds(test_df),
               "At least 2 numeric columns required for PCA")

  # Test with insufficient observations
  test_df <- data.frame(
    prop1 = c(1, 2),
    prop2 = c(3, 4)
  )
  expect_error(pca_select_mds(test_df),
               "At least 3 observations required for PCA")
})


test_that("pca_select_mds validates threshold parameters", {
  test_data <- data.frame(
    prop1 = c(1, 2, 3, 4, 5),
    prop2 = c(2, 4, 6, 8, 10)
  )

  # Test invalid var_threshold
  expect_error(pca_select_mds(test_data, var_threshold = -0.1),
               "var_threshold must be a single numeric value between 0 and 1")

  expect_error(pca_select_mds(test_data, var_threshold = 1.5),
               "var_threshold must be a single numeric value between 0 and 1")

  expect_error(pca_select_mds(test_data, var_threshold = c(0.1, 0.2)),
               "var_threshold must be a single numeric value between 0 and 1")

  # Test invalid loading_threshold
  expect_error(pca_select_mds(test_data, loading_threshold = -0.1),
               "loading_threshold must be a single numeric value between 0 and 1")

  expect_error(pca_select_mds(test_data, loading_threshold = 1.5),
               "loading_threshold must be a single numeric value between 0 and 1")
})


test_that("pca_select_mds handles NA values appropriately", {
  # Create data with NA values
  test_data <- data.frame(
    prop1 = c(1, 2, NA, 4, 5, 6, 7, 8),
    prop2 = c(2, 4, 6, 8, 10, 12, 14, 16),
    prop3 = c(10, 9, 8, 7, 6, 5, 4, 3)
  )

  # Should warn about removing rows with NA
  expect_warning(pca_select_mds(test_data), "Removing .* rows with NA values")

  # Should still return valid results
  result <- suppressWarnings(pca_select_mds(test_data))
  expect_type(result$mds, "character")
  expect_s3_class(result$pca, "prcomp")
})


test_that("pca_select_mds handles all-NA columns", {
  # Create data with all-NA column (use NA_real_ for numeric NA)
  test_data <- data.frame(
    prop1 = c(1, 2, 3, 4, 5, 6, 7, 8),
    prop2 = c(NA_real_, NA_real_, NA_real_, NA_real_,
              NA_real_, NA_real_, NA_real_, NA_real_),
    prop3 = c(10, 9, 8, 7, 6, 5, 4, 3),
    prop4 = c(2, 4, 6, 8, 10, 12, 14, 16)
  )

  # Should warn about removing all-NA columns
  expect_warning(pca_select_mds(test_data),
                "Removing columns with all NA values")

  # Should still return valid results
  result <- suppressWarnings(pca_select_mds(test_data))
  expect_type(result$mds, "character")
})


test_that("pca_select_mds PCA object structure is correct", {
  # Create test data
  test_data <- data.frame(
    prop1 = c(1, 2, 3, 4, 5, 6, 7, 8),
    prop2 = c(2, 4, 6, 8, 10, 12, 14, 16),
    prop3 = c(10, 9, 8, 7, 6, 5, 4, 3)
  )

  result <- pca_select_mds(test_data)

  # Check PCA object has expected components
  expect_true("sdev" %in% names(result$pca))
  expect_true("rotation" %in% names(result$pca))
  expect_true("center" %in% names(result$pca))
  expect_true("scale" %in% names(result$pca))
  expect_true("x" %in% names(result$pca))

  # Check loadings matrix dimensions
  expect_equal(nrow(result$loadings), ncol(test_data))
  expect_equal(ncol(result$loadings), ncol(test_data))

  # Check variance explained vector length
  expect_equal(length(result$var_exp), ncol(test_data))
})


test_that("pca_select_mds works with mixed numeric and non-numeric columns", {
  # Create data with ID column
  test_data <- data.frame(
    ID = c("S1", "S2", "S3", "S4", "S5"),
    prop1 = c(1, 2, 3, 4, 5),
    prop2 = c(2, 4, 6, 8, 10),
    prop3 = c(10, 9, 8, 7, 6)
  )

  # Should work by extracting only numeric columns
  result <- pca_select_mds(test_data)

  expect_type(result$mds, "character")
  expect_s3_class(result$pca, "prcomp")

  # MDS should only contain numeric column names
  expect_true(all(result$mds %in% c("prop1", "prop2", "prop3")))
  expect_false("ID" %in% result$mds)
})

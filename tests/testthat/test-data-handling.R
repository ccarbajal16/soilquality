# Tests for data handling functions

test_that("to_numeric converts values correctly", {
  # Test numeric conversion from character
  expect_equal(to_numeric(c("1.5", "2.3", "3.7")), c(1.5, 2.3, 3.7))
  
  # Test that non-numeric values become NA
  result <- to_numeric(c("1.5", "text", "3.7"))
  expect_equal(result[1], 1.5)
  expect_true(is.na(result[2]))
  expect_equal(result[3], 3.7)
  
  # Test that already numeric values pass through
  expect_equal(to_numeric(c(1.5, 2.3, 3.7)), c(1.5, 2.3, 3.7))
  
  # Test with NA values
  result <- to_numeric(c("1.5", NA, "3.7"))
  expect_equal(result[1], 1.5)
  expect_true(is.na(result[2]))
  expect_equal(result[3], 3.7)
  
  # Test with empty vector
  expect_equal(to_numeric(character(0)), numeric(0))
})


test_that("standardize_numeric preserves data frame structure", {
  # Create test data
  test_df <- data.frame(
    ID = c("S1", "S2", "S3", "S4"),
    pH = c(6.5, 7.0, 6.8, 7.2),
    OM = c(3.2, 2.8, 3.5, 3.0),
    Sand = c(45, 50, 42, 48),
    stringsAsFactors = FALSE
  )
  
  # Standardize without exclusions
  result <- standardize_numeric(test_df)
  
  # Check that structure is preserved
  expect_equal(nrow(result), nrow(test_df))
  expect_equal(ncol(result), ncol(test_df))
  expect_equal(names(result), names(test_df))
  
  # Check that non-numeric column is unchanged
  expect_equal(result$ID, test_df$ID)
  
  # Check that numeric columns are standardized
  expect_equal(mean(result$pH), 0, tolerance = 1e-10)
  expect_equal(sd(result$pH), 1, tolerance = 1e-10)
  expect_equal(mean(result$OM), 0, tolerance = 1e-10)
  expect_equal(sd(result$OM), 1, tolerance = 1e-10)
})


test_that("standardize_numeric respects exclude parameter", {
  test_df <- data.frame(
    ID = c("S1", "S2", "S3", "S4"),
    pH = c(6.5, 7.0, 6.8, 7.2),
    OM = c(3.2, 2.8, 3.5, 3.0)
  )
  
  # Exclude ID and pH from standardization
  result <- standardize_numeric(test_df, exclude = c("ID", "pH"))
  
  # ID should be unchanged (non-numeric)
  expect_equal(result$ID, test_df$ID)
  
  # pH should be unchanged (excluded)
  expect_equal(result$pH, test_df$pH)
  
  # OM should be standardized
  expect_equal(mean(result$OM), 0, tolerance = 1e-10)
  expect_equal(sd(result$OM), 1, tolerance = 1e-10)
})


test_that("standardize_numeric handles NA values", {
  test_df <- data.frame(
    prop1 = c(1, 2, NA, 4),
    prop2 = c(10, NA, 30, 40)
  )
  
  result <- standardize_numeric(test_df)
  
  # Check that NA positions are preserved
  expect_true(is.na(result$prop1[3]))
  expect_true(is.na(result$prop2[2]))
  
  # Check that non-NA values are standardized
  expect_false(is.na(result$prop1[1]))
  expect_false(is.na(result$prop2[1]))
})


test_that("standardize_numeric handles zero variance columns", {
  test_df <- data.frame(
    constant = c(5, 5, 5, 5),
    variable = c(1, 2, 3, 4)
  )
  
  result <- standardize_numeric(test_df)
  
  # Constant column should remain unchanged
  expect_equal(result$constant, test_df$constant)
  
  # Variable column should be standardized
  expect_equal(mean(result$variable), 0, tolerance = 1e-10)
  expect_equal(sd(result$variable), 1, tolerance = 1e-10)
})


test_that("standardize_numeric handles all-NA columns", {
  test_df <- data.frame(
    all_na = c(NA, NA, NA, NA),
    normal = c(1, 2, 3, 4)
  )
  
  result <- standardize_numeric(test_df)
  
  # All-NA column should remain all NA
  expect_true(all(is.na(result$all_na)))
  
  # Normal column should be standardized
  expect_equal(mean(result$normal), 0, tolerance = 1e-10)
})


test_that("read_soil_csv validates input", {
  # Test with non-character input
  expect_error(read_soil_csv(123), "path must be a single character string")
  
  # Test with multiple paths
  expect_error(read_soil_csv(c("path1", "path2")), "path must be a single character string")
  
  # Test with non-existent file
  expect_error(read_soil_csv("nonexistent_file.csv"), "File not found")
})


test_that("read_soil_csv reads CSV files", {
  # Create a temporary CSV file for testing
  temp_file <- tempfile(fileext = ".csv")
  test_data <- data.frame(
    SampleID = c("S1", "S2", "S3"),
    pH = c(6.5, 7.0, 6.8),
    OM = c(3.2, 2.8, 3.5)
  )
  write.csv(test_data, temp_file, row.names = FALSE)
  
  # Read the file
  result <- read_soil_csv(temp_file)
  
  # Check that data is read correctly
  expect_equal(nrow(result), 3)
  expect_equal(ncol(result), 3)
  expect_true("SampleID" %in% names(result))
  expect_true("pH" %in% names(result))
  expect_true("OM" %in% names(result))
  
  # Clean up
  unlink(temp_file)
})


test_that("standardize_numeric input validation", {
  # Test with non-data.frame input
  expect_error(standardize_numeric(c(1, 2, 3)), "df must be a data frame")
  
  # Test with invalid exclude parameter
  expect_error(standardize_numeric(data.frame(x = 1:3), exclude = 123), 
               "exclude must be NULL or a character vector")
})

# Tests for visualization functions

# Create test data and result for use across tests
create_test_result <- function() {
  set.seed(123)
  data <- data.frame(
    SampleID = paste0("S", 1:20),
    Sand = rnorm(20, 45, 10),
    Silt = rnorm(20, 30, 5),
    Clay = rnorm(20, 25, 5),
    pH = rnorm(20, 6.5, 0.5),
    OM = rnorm(20, 3, 0.5)
  )

  compute_sqi_df(data, id_column = "SampleID")
}

test_that("plot.sqi_result handles distribution type", {
  result <- create_test_result()

  # Should not throw an error
  expect_error(plot(result, type = "distribution"), NA)
})

test_that("plot.sqi_result handles indicators type", {
  result <- create_test_result()

  # Should not throw an error
  expect_error(plot(result, type = "indicators"), NA)
})

test_that("plot.sqi_result handles weights type", {
  result <- create_test_result()

  # Should not throw an error
  expect_error(plot(result, type = "weights"), NA)
})

test_that("plot.sqi_result handles scree type", {
  result <- create_test_result()

  # Should not throw an error
  expect_error(plot(result, type = "scree"), NA)
})

test_that("plot.sqi_result handles biplot type", {
  result <- create_test_result()

  # Should not throw an error
  expect_error(plot(result, type = "biplot"), NA)
})

test_that("plot.sqi_result validates input object", {
  # Test with non-sqi_result object
  expect_error(plot.sqi_result(list(a = 1, b = 2)),
               "x must be an sqi_result object")

  # Test with NULL
  expect_error(plot.sqi_result(NULL),
               "x must be an sqi_result object")
})

test_that("plot.sqi_result validates plot type", {
  result <- create_test_result()

  # Test with invalid type
  expect_error(plot(result, type = "invalid"),
               "'arg' should be one of")
})

test_that("plot.sqi_result returns NULL invisibly", {
  result <- create_test_result()

  # Check return value
  ret <- plot(result, type = "distribution")
  expect_null(ret)
})

test_that("plot.sqi_result works with minimal data", {
  # Create minimal dataset
  set.seed(456)
  data <- data.frame(
    prop1 = rnorm(10, 50, 5),
    prop2 = rnorm(10, 30, 3),
    prop3 = rnorm(10, 20, 2)
  )

  result <- compute_sqi_df(data)

  # All plot types should work
  expect_error(plot(result, type = "distribution"), NA)
  expect_error(plot(result, type = "indicators"), NA)
  expect_error(plot(result, type = "weights"), NA)
  expect_error(plot(result, type = "scree"), NA)
  expect_error(plot(result, type = "biplot"), NA)
})

test_that("plot_sqi_report creates multi-panel layout", {
  result <- create_test_result()

  # Should not throw an error
  expect_error(plot_sqi_report(result), NA)
})

test_that("plot_sqi_report validates input object", {
  # Test with non-sqi_result object
  expect_error(plot_sqi_report(list(a = 1, b = 2)),
               "sqi_result must be an sqi_result object")

  # Test with NULL
  expect_error(plot_sqi_report(NULL),
               "sqi_result must be an sqi_result object")
})

test_that("plot_sqi_report returns NULL invisibly", {
  result <- create_test_result()

  # Check return value
  ret <- plot_sqi_report(result)
  expect_null(ret)
})

test_that("plot_sqi_report resets graphics parameters", {
  result <- create_test_result()

  # Save original par settings
  original_mfrow <- par("mfrow")

  # Create report
  plot_sqi_report(result)

  # Check that mfrow is reset
  current_mfrow <- par("mfrow")
  expect_equal(current_mfrow, original_mfrow)
})

test_that("plot_sqi_report works with minimal data", {
  # Create minimal dataset
  set.seed(789)
  data <- data.frame(
    prop1 = rnorm(10, 50, 5),
    prop2 = rnorm(10, 30, 3),
    prop3 = rnorm(10, 20, 2)
  )

  result <- compute_sqi_df(data)

  # Should not throw an error
  expect_error(plot_sqi_report(result), NA)
})

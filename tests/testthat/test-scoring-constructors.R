# Tests for scoring constructor functions

test_that("higher_better creates correct structure", {
  rule <- higher_better()

  # Check class structure
  expect_s3_class(rule, "scoring_rule")
  expect_s3_class(rule, "higher_better")

  # Check type
  expect_equal(rule$type, "higher")

  # Check default NULL values
  expect_null(rule$min_val)
  expect_null(rule$max_val)
})

test_that("higher_better accepts custom min/max values", {
  rule <- higher_better(min_value = 0, max_value = 10)

  # Check that custom values are stored
  expect_equal(rule$min_val, 0)
  expect_equal(rule$max_val, 10)
})

test_that("lower_better creates correct structure", {
  rule <- lower_better()

  # Check class structure
  expect_s3_class(rule, "scoring_rule")
  expect_s3_class(rule, "lower_better")

  # Check type
  expect_equal(rule$type, "lower")

  # Check default NULL values
  expect_null(rule$min_val)
  expect_null(rule$max_val)
})

test_that("lower_better accepts custom min/max values", {
  rule <- lower_better(min_value = 1.0, max_value = 1.8)

  # Check that custom values are stored
  expect_equal(rule$min_val, 1.0)
  expect_equal(rule$max_val, 1.8)
})

test_that("optimum_range creates correct structure", {
  rule <- optimum_range(optimal = 7, tolerance = 1.5)

  # Check class structure
  expect_s3_class(rule, "scoring_rule")
  expect_s3_class(rule, "optimum_range")

  # Check type
  expect_equal(rule$type, "optimum")

  # Check parameters
  expect_equal(rule$optimum, 7)
  expect_equal(rule$tol, 1.5)
  expect_equal(rule$penalty, "linear")
})

test_that("optimum_range accepts custom penalty", {
  rule <- optimum_range(optimal = 7, tolerance = 1.5, penalty = "quadratic")

  # Check penalty is stored
  expect_equal(rule$penalty, "quadratic")
})

test_that("optimum_range rejects non-positive tolerance", {
  # Zero tolerance
  expect_error(optimum_range(optimal = 7, tolerance = 0),
               "tolerance must be a positive number")

  # Negative tolerance
  expect_error(optimum_range(optimal = 7, tolerance = -1),
               "tolerance must be a positive number")

  # Non-numeric tolerance
  expect_error(optimum_range(optimal = 7, tolerance = "invalid"),
               "tolerance must be a positive number")

  # Vector tolerance
  expect_error(optimum_range(optimal = 7, tolerance = c(1, 2)),
               "tolerance must be a positive number")
})

test_that("optimum_range validates penalty parameter", {
  expect_error(optimum_range(optimal = 7, tolerance = 1, penalty = "invalid"),
               "penalty must be 'linear' or 'quadratic'")
})

test_that("threshold_scoring creates correct structure", {
  rule <- threshold_scoring(
    thresholds = c(0, 10, 20, 30),
    scores = c(0, 0.5, 1.0, 1.0)
  )

  # Check class structure
  expect_s3_class(rule, "scoring_rule")
  expect_s3_class(rule, "threshold_scoring")

  # Check type
  expect_equal(rule$type, "threshold")

  # Check parameters
  expect_equal(rule$thresholds, c(0, 10, 20, 30))
  expect_equal(rule$scores, c(0, 0.5, 1.0, 1.0))
})

test_that("threshold_scoring validates equal lengths", {
  # Scores vector too short
  expect_error(
    threshold_scoring(
      thresholds = c(0, 10, 20, 30),
      scores = c(0, 0.5, 1.0)
    ),
    "thresholds and scores must have equal length"
  )

  # Thresholds vector too short
  expect_error(
    threshold_scoring(
      thresholds = c(0, 10, 20),
      scores = c(0, 0.5, 1.0, 1.0)
    ),
    "thresholds and scores must have equal length"
  )
})

test_that("threshold_scoring validates numeric inputs", {
  # Non-numeric thresholds
  expect_error(
    threshold_scoring(
      thresholds = c("a", "b", "c"),
      scores = c(0, 0.5, 1.0)
    ),
    "thresholds and scores must be numeric vectors"
  )

  # Non-numeric scores
  expect_error(
    threshold_scoring(
      thresholds = c(0, 10, 20),
      scores = c("low", "medium", "high")
    ),
    "thresholds and scores must be numeric vectors"
  )
})

test_that("print.scoring_rule works for higher_better", {
  rule <- higher_better(min_value = 0, max_value = 10)

  # Capture output
  output <- capture.output(print(rule))

  # Check that output contains expected information
  expect_true(any(grepl("higher_better", output)))
  expect_true(any(grepl("Higher values are better", output)))
  expect_true(any(grepl("Min value: 0", output)))
  expect_true(any(grepl("Max value: 10", output)))
})

test_that("print.scoring_rule works for lower_better", {
  rule <- lower_better(min_value = 1.0, max_value = 1.8)

  # Capture output
  output <- capture.output(print(rule))

  # Check that output contains expected information
  expect_true(any(grepl("lower_better", output)))
  expect_true(any(grepl("Lower values are better", output)))
  expect_true(any(grepl("Min value: 1", output)))
  expect_true(any(grepl("Max value: 1.8", output)))
})

test_that("print.scoring_rule works for optimum_range", {
  rule <- optimum_range(optimal = 7, tolerance = 1.5, penalty = "quadratic")

  # Capture output
  output <- capture.output(print(rule))

  # Check that output contains expected information
  expect_true(any(grepl("optimum_range", output)))
  expect_true(any(grepl("Optimum range", output)))
  expect_true(any(grepl("Optimal value: 7", output)))
  expect_true(any(grepl("Tolerance: 1.5", output)))
  expect_true(any(grepl("Penalty: quadratic", output)))
})

test_that("print.scoring_rule works for threshold_scoring", {
  rule <- threshold_scoring(
    thresholds = c(0, 10, 20),
    scores = c(0, 0.5, 1.0)
  )

  # Capture output
  output <- capture.output(print(rule))

  # Check that output contains expected information
  expect_true(any(grepl("threshold_scoring", output)))
  expect_true(any(grepl("Threshold-based scoring", output)))
  expect_true(any(grepl("Thresholds:", output)))
  expect_true(any(grepl("Scores:", output)))
})

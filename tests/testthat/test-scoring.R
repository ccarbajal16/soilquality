# Tests for scoring functions

test_that("score_higher_better normalizes to [0,1]", {
  # Test basic normalization
  x <- c(1, 2, 3, 4, 5)
  result <- score_higher_better(x)

  # Check range
  expect_true(all(result >= 0 & result <= 1))

  # Check min and max
  expect_equal(min(result), 0)
  expect_equal(max(result), 1)

  # Check monotonicity (higher values get higher scores)
  expect_true(all(diff(result) >= 0))
})

test_that("score_higher_better handles custom min/max", {
  x <- c(2, 3, 4)
  result <- score_higher_better(x, min_val = 1, max_val = 5)

  # Check that values are normalized to custom range
  expect_equal(result[1], 0.25)  # (2-1)/(5-1) = 0.25
  expect_equal(result[2], 0.50)  # (3-1)/(5-1) = 0.50
  expect_equal(result[3], 0.75)  # (4-1)/(5-1) = 0.75
})

test_that("score_higher_better handles min=max edge case", {
  x <- c(5, 5, 5, 5)
  result <- score_higher_better(x)

  # All values should be 1 when min equals max
  expect_equal(result, rep(1, 4))
})

test_that("score_higher_better handles NA values", {
  x <- c(1, 2, NA, 4, 5)
  result <- score_higher_better(x)

  # Check that NA is preserved
  expect_true(is.na(result[3]))

  # Check that other values are scored correctly
  expect_false(is.na(result[1]))
  expect_false(is.na(result[5]))
})

test_that("score_lower_better normalizes to [0,1]", {
  # Test basic normalization
  x <- c(1, 2, 3, 4, 5)
  result <- score_lower_better(x)

  # Check range
  expect_true(all(result >= 0 & result <= 1))

  # Check min and max (inverted)
  expect_equal(max(result), 1)  # Lowest value gets highest score
  expect_equal(min(result), 0)  # Highest value gets lowest score

  # Check monotonicity (lower values get higher scores)
  expect_true(all(diff(result) <= 0))
})

test_that("score_lower_better handles custom min/max", {
  x <- c(2, 3, 4)
  result <- score_lower_better(x, min_val = 1, max_val = 5)

  # Check that values are normalized to custom range (inverted)
  expect_equal(result[1], 0.75)  # (5-2)/(5-1) = 0.75
  expect_equal(result[2], 0.50)  # (5-3)/(5-1) = 0.50
  expect_equal(result[3], 0.25)  # (5-4)/(5-1) = 0.25
})

test_that("score_lower_better handles min=max edge case", {
  x <- c(5, 5, 5, 5)
  result <- score_lower_better(x)

  # All values should be 1 when min equals max
  expect_equal(result, rep(1, 4))
})

test_that("score_lower_better handles NA values", {
  x <- c(1, 2, NA, 4, 5)
  result <- score_lower_better(x)

  # Check that NA is preserved
  expect_true(is.na(result[3]))

  # Check that other values are scored correctly
  expect_false(is.na(result[1]))
  expect_false(is.na(result[5]))
})

test_that("score_optimum normalizes to [0,1] with linear penalty", {
  # Test with optimum in the middle
  x <- c(5, 6, 7, 8, 9)
  result <- score_optimum(x, optimum = 7, tol = 2, penalty = "linear")

  # Check range
  expect_true(all(result >= 0 & result <= 1))

  # Check that optimum gets score of 1
  expect_equal(result[3], 1)

  # Check that values at tolerance distance get score of 0
  result2 <- score_optimum(c(5, 7, 9), optimum = 7, tol = 2, penalty = "linear")
  expect_equal(result2[1], 0)  # 7-2 = 5
  expect_equal(result2[2], 1)  # optimum
  expect_equal(result2[3], 0)  # 7+2 = 9
})

test_that("score_optimum handles quadratic penalty", {
  x <- c(6, 7, 8)
  result <- score_optimum(x, optimum = 7, tol = 2, penalty = "quadratic")

  # Check range
  expect_true(all(result >= 0 & result <= 1))

  # Check that optimum gets score of 1
  expect_equal(result[2], 1)

  # Quadratic penalty should be less severe near optimum
  linear <- score_optimum(x, optimum = 7, tol = 2, penalty = "linear")
  expect_true(result[1] > linear[1])  # Quadratic is more forgiving
})

test_that("score_optimum handles values beyond tolerance", {
  x <- c(3, 5, 7, 9, 11)
  result <- score_optimum(x, optimum = 7, tol = 2, penalty = "linear")

  # Values beyond tolerance should be capped at 0
  expect_equal(result[1], 0)  # 3 is 4 units away, beyond tol=2
  expect_equal(result[5], 0)  # 11 is 4 units away, beyond tol=2
})

test_that("score_optimum handles NA values", {
  x <- c(5, NA, 7, 9)
  result <- score_optimum(x, optimum = 7, tol = 2, penalty = "linear")

  # Check that NA is preserved
  expect_true(is.na(result[2]))

  # Check that other values are scored correctly
  expect_false(is.na(result[1]))
  expect_false(is.na(result[3]))
})

test_that("score_optimum validates penalty parameter", {
  x <- c(5, 6, 7)
  expect_error(score_optimum(x, optimum = 7, tol = 2, penalty = "invalid"),
               "penalty must be 'linear' or 'quadratic'")
})

test_that("score_threshold normalizes to [0,1]", {
  # Test basic threshold scoring
  x <- c(5, 10, 15, 20, 25, 30, 35)
  thresholds <- c(0, 10, 20, 30)
  scores <- c(0, 0.5, 1.0, 1.0)

  result <- score_threshold(x, thresholds, scores)

  # Check range
  expect_true(all(result >= 0 & result <= 1))

  # Check specific threshold points
  expect_equal(result[2], 0.5)   # x=10 -> score=0.5
  expect_equal(result[4], 1.0)   # x=20 -> score=1.0
  expect_equal(result[6], 1.0)   # x=30 -> score=1.0
})

test_that("score_threshold interpolates between thresholds", {
  x <- c(5, 15, 25)
  thresholds <- c(0, 10, 20, 30)
  scores <- c(0, 0.5, 1.0, 1.0)

  result <- score_threshold(x, thresholds, scores)

  # x=5 is halfway between 0 and 10, so score should be 0.25
  expect_equal(result[1], 0.25, tolerance = 1e-10)

  # x=15 is halfway between 10 and 20, so score should be 0.75
  expect_equal(result[2], 0.75, tolerance = 1e-10)

  # x=25 is halfway between 20 and 30, so score should be 1.0
  expect_equal(result[3], 1.0, tolerance = 1e-10)
})

test_that("score_threshold validates input lengths", {
  x <- c(5, 10, 15)
  thresholds <- c(0, 10, 20)
  scores <- c(0, 0.5)  # Wrong length

  expect_error(score_threshold(x, thresholds, scores),
               "thresholds and scores must have the same length")
})

test_that("score_threshold handles NA values", {
  x <- c(5, NA, 15, 25)
  thresholds <- c(0, 10, 20, 30)
  scores <- c(0, 0.5, 1.0, 1.0)

  result <- score_threshold(x, thresholds, scores)

  # Check that NA is preserved
  expect_true(is.na(result[2]))

  # Check that other values are scored correctly
  expect_false(is.na(result[1]))
  expect_false(is.na(result[3]))
})

test_that("score_indicators applies correct scoring functions", {
  # Create test data
  data <- data.frame(
    ID = c("S1", "S2", "S3", "S4", "S5"),
    OM = c(1.5, 2.0, 2.5, 3.0, 3.5),
    pH = c(5.5, 6.0, 6.5, 7.0, 7.5),
    BD = c(1.2, 1.3, 1.4, 1.5, 1.6)
  )

  # Define scoring directions
  directions <- list(
    OM = list(type = "higher"),
    pH = list(type = "optimum", optimum = 7, tol = 1.5, penalty = "linear"),
    BD = list(type = "lower")
  )

  # Score indicators
  result <- score_indicators(data, c("OM", "pH", "BD"), directions)

  # Check that original columns are preserved
  expect_true(all(c("ID", "OM", "pH", "BD") %in% names(result)))

  # Check that scored columns are added
  expect_true("OM_scored" %in% names(result))
  expect_true("pH_scored" %in% names(result))
  expect_true("BD_scored" %in% names(result))

  # Check that all scored values are in [0,1]
  expect_true(all(result$OM_scored >= 0 & result$OM_scored <= 1))
  expect_true(all(result$pH_scored >= 0 & result$pH_scored <= 1))
  expect_true(all(result$BD_scored >= 0 & result$BD_scored <= 1))

  # Check that OM (higher is better) increases
  expect_true(all(diff(result$OM_scored) >= 0))

  # Check that BD (lower is better) decreases
  expect_true(all(diff(result$BD_scored) <= 0))

  # Check that pH optimum (7.0) gets highest score
  expect_equal(which.max(result$pH_scored), 4)
})

test_that("score_indicators validates MDS variables exist", {
  data <- data.frame(
    ID = c("S1", "S2"),
    OM = c(1.5, 2.0)
  )

  directions <- list(
    OM = list(type = "higher"),
    pH = list(type = "higher")  # pH doesn't exist
  )

  expect_error(score_indicators(data, c("OM", "pH"), directions),
               "MDS variables not found in data: pH")
})

test_that("score_indicators validates direction specification", {
  data <- data.frame(
    ID = c("S1", "S2"),
    OM = c(1.5, 2.0)
  )

  directions <- list()  # No direction for OM

  expect_error(score_indicators(data, c("OM"), directions),
               "No scoring direction specified for indicator: OM")
})

test_that("score_indicators validates scoring type", {
  data <- data.frame(
    ID = c("S1", "S2"),
    OM = c(1.5, 2.0)
  )

  directions <- list(
    OM = list(type = "invalid_type")
  )

  expect_error(score_indicators(data, c("OM"), directions),
               "Invalid scoring type 'invalid_type' for indicator: OM")
})

test_that("score_indicators validates optimum parameters", {
  data <- data.frame(
    ID = c("S1", "S2"),
    pH = c(6.5, 7.0)
  )

  # Missing optimum parameter
  directions <- list(
    pH = list(type = "optimum", tol = 1.5)
  )

  expect_error(score_indicators(data, c("pH"), directions),
               "optimum and tol required for type 'optimum' for indicator: pH")
})

test_that("score_indicators validates threshold parameters", {
  data <- data.frame(
    ID = c("S1", "S2"),
    P = c(10, 20)
  )

  # Missing thresholds parameter
  directions <- list(
    P = list(type = "threshold", scores = c(0, 1))
  )

  expect_error(score_indicators(data, c("P"), directions),
               "thresholds and scores required for type 'threshold'")
})

test_that("score_indicators handles threshold scoring", {
  data <- data.frame(
    ID = c("S1", "S2", "S3", "S4"),
    P = c(5, 15, 25, 35)
  )

  directions <- list(
    P = list(
      type = "threshold",
      thresholds = c(0, 10, 20, 30),
      scores = c(0, 0.5, 1.0, 1.0)
    )
  )

  result <- score_indicators(data, c("P"), directions)

  # Check that scored column exists
  expect_true("P_scored" %in% names(result))

  # Check that values are in [0,1]
  expect_true(all(result$P_scored >= 0 & result$P_scored <= 1))
})

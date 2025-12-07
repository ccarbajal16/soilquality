# Tests for AHP weighting functions

test_that("ahp_weights returns correct structure", {
  # Create test pairwise matrix
  pairwise <- matrix(c(
    1,   3,   5,
    1/3, 1,   2,
    1/5, 1/2, 1
  ), nrow = 3, byrow = TRUE)
  
  result <- ahp_weights(pairwise, indicators = c("pH", "OM", "P"))
  
  # Check that result is a list
  expect_type(result, "list")
  
  # Check that all expected components are present
  expect_true("weights" %in% names(result))
  expect_true("CR" %in% names(result))
  expect_true("lambda_max" %in% names(result))
  
  # Check types of components
  expect_type(result$weights, "double")
  expect_type(result$CR, "double")
  expect_type(result$lambda_max, "double")
  
  # Check that weights have names
  expect_equal(names(result$weights), c("pH", "OM", "P"))
})


test_that("ahp_weights produces weights summing to 1", {
  # Create test pairwise matrix
  pairwise <- matrix(c(
    1,   3,   5,
    1/3, 1,   2,
    1/5, 1/2, 1
  ), nrow = 3, byrow = TRUE)
  
  result <- ahp_weights(pairwise)
  
  # Weights should sum to 1 (within numerical tolerance)
  expect_equal(sum(result$weights), 1, tolerance = 1e-10)
  
  # All weights should be positive
  expect_true(all(result$weights > 0))
  
  # All weights should be less than or equal to 1
  expect_true(all(result$weights <= 1))
})


test_that("ahp_weights CR calculation is accurate", {
  # Create a perfectly consistent matrix (derived from weights)
  # If weights are [0.6, 0.3, 0.1], pairwise should be w_i/w_j
  weights_true <- c(0.6, 0.3, 0.1)
  n <- length(weights_true)
  
  pairwise_consistent <- matrix(0, nrow = n, ncol = n)
  for (i in 1:n) {
    for (j in 1:n) {
      pairwise_consistent[i, j] <- weights_true[i] / weights_true[j]
    }
  }
  
  result <- ahp_weights(pairwise_consistent)
  
  # CR should be very close to 0 for perfectly consistent matrix
  expect_lt(result$CR, 0.01)
  
  # Lambda_max should be very close to n for consistent matrix
  expect_equal(result$lambda_max, n, tolerance = 0.01)
})


test_that("ahp_weights warns when CR exceeds 0.1", {
  # Create a highly inconsistent matrix
  # This matrix has strong violations of transitivity
  pairwise_inconsistent <- matrix(c(
    1, 9, 1/9,
    1/9, 1, 1/9,
    9, 9, 1
  ), nrow = 3, byrow = TRUE)
  
  # Should produce a warning about high CR
  expect_warning(ahp_weights(pairwise_inconsistent),
                 "Consistency Ratio.*exceeds 0.1")
})


test_that("ahp_weights validates matrix is square", {
  # Non-square matrix
  pairwise <- matrix(c(1, 2, 3, 4, 5, 6), nrow = 2, ncol = 3)
  
  expect_error(ahp_weights(pairwise),
               "Pairwise matrix must be square")
})


test_that("ahp_weights validates diagonal values", {
  # Matrix with incorrect diagonal
  pairwise <- matrix(c(
    2, 3, 5,
    1/3, 1, 2,
    1/5, 1/2, 1
  ), nrow = 3, byrow = TRUE)
  
  expect_error(ahp_weights(pairwise),
               "Diagonal values must be 1")
})


test_that("ahp_weights validates reciprocal property", {
  # Matrix that is not reciprocal
  pairwise <- matrix(c(
    1, 3, 5,
    1/2, 1, 2,  # Should be 1/3, not 1/2
    1/5, 1/2, 1
  ), nrow = 3, byrow = TRUE)
  
  expect_error(ahp_weights(pairwise),
               "Matrix must be reciprocal")
})


test_that("ahp_weights handles minimum size matrix", {
  # 2x2 matrix
  pairwise <- matrix(c(
    1, 3,
    1/3, 1
  ), nrow = 2, byrow = TRUE)
  
  result <- ahp_weights(pairwise, indicators = c("A", "B"))
  
  expect_equal(sum(result$weights), 1, tolerance = 1e-10)
  expect_equal(length(result$weights), 2)
})


test_that("ahp_weights handles larger matrices", {
  # 5x5 matrix
  pairwise <- matrix(c(
    1,   2,   3,   4,   5,
    1/2, 1,   2,   3,   4,
    1/3, 1/2, 1,   2,   3,
    1/4, 1/3, 1/2, 1,   2,
    1/5, 1/4, 1/3, 1/2, 1
  ), nrow = 5, byrow = TRUE)
  
  result <- ahp_weights(pairwise)
  
  expect_equal(sum(result$weights), 1, tolerance = 1e-10)
  expect_equal(length(result$weights), 5)
  expect_type(result$CR, "double")
})


test_that("ahp_weights uses row names when indicators not provided", {
  # Matrix with row names
  pairwise <- matrix(c(
    1,   3,   5,
    1/3, 1,   2,
    1/5, 1/2, 1
  ), nrow = 3, byrow = TRUE)
  rownames(pairwise) <- c("Ind1", "Ind2", "Ind3")
  
  result <- ahp_weights(pairwise)
  
  expect_equal(names(result$weights), c("Ind1", "Ind2", "Ind3"))
})


test_that("ahp_weights generates default names when none provided", {
  # Matrix without row names or indicators
  pairwise <- matrix(c(
    1,   3,   5,
    1/3, 1,   2,
    1/5, 1/2, 1
  ), nrow = 3, byrow = TRUE)
  
  result <- ahp_weights(pairwise)
  
  # Should generate default names
  expect_true(all(grepl("^Indicator[0-9]+$", names(result$weights))))
  expect_equal(length(result$weights), 3)
})


test_that("ratio_to_saaty returns correct structure", {
  ratios <- c(5, 3, 1)
  
  result <- ratio_to_saaty(ratios)
  
  # Should be a matrix
  expect_true(is.matrix(result))
  
  # Should be square
  expect_equal(nrow(result), ncol(result))
  expect_equal(nrow(result), length(ratios))
  
  # Diagonal should be 1
  expect_true(all(abs(diag(result) - 1) < 1e-10))
})


test_that("ratio_to_saaty conversion is correct", {
  ratios <- c(6, 3, 2)
  
  result <- ratio_to_saaty(ratios)
  
  # Check specific pairwise comparisons
  # ratio[1]/ratio[2] = 6/3 = 2
  expect_equal(result[1, 2], 2, tolerance = 1e-10)
  
  # ratio[2]/ratio[1] = 3/6 = 0.5
  expect_equal(result[2, 1], 0.5, tolerance = 1e-10)
  
  # ratio[1]/ratio[3] = 6/2 = 3
  expect_equal(result[1, 3], 3, tolerance = 1e-10)
  
  # ratio[3]/ratio[2] = 2/3 = 0.667
  expect_equal(result[3, 2], 2/3, tolerance = 1e-10)
})


test_that("ratio_to_saaty produces reciprocal matrix", {
  ratios <- c(5, 3, 1)
  
  result <- ratio_to_saaty(ratios)
  
  # Check reciprocal property for all elements
  for (i in seq_len(nrow(result))) {
    for (j in seq_len(ncol(result))) {
      expect_equal(result[i, j] * result[j, i], 1, tolerance = 1e-10)
    }
  }
})


test_that("ratio_to_saaty validates input", {
  # Non-numeric input
  expect_error(ratio_to_saaty(c("a", "b", "c")),
               "ratios must be a numeric vector")
  
  # Negative values
  expect_error(ratio_to_saaty(c(5, -3, 1)),
               "All ratios must be positive")
  
  # Zero values
  expect_error(ratio_to_saaty(c(5, 0, 1)),
               "All ratios must be positive")
  
  # Too few elements
  expect_error(ratio_to_saaty(c(5)),
               "ratios must have at least 2 elements")
})


test_that("ratio_to_saaty preserves names", {
  ratios <- c(pH = 5, OM = 3, P = 1)
  
  result <- ratio_to_saaty(ratios)
  
  expect_equal(rownames(result), c("pH", "OM", "P"))
  expect_equal(colnames(result), c("pH", "OM", "P"))
})


test_that("create_ahp_matrix works in matrix mode", {
  pairwise <- matrix(c(
    1,   3,   5,
    1/3, 1,   2,
    1/5, 1/2, 1
  ), nrow = 3, byrow = TRUE)
  
  result <- create_ahp_matrix(
    indicators = c("pH", "OM", "P"),
    mode = "matrix",
    pairwise = pairwise
  )
  
  # Check class
  expect_s3_class(result, "ahp_matrix")
  
  # Check structure
  expect_true("indicators" %in% names(result))
  expect_true("matrix" %in% names(result))
  expect_true("weights" %in% names(result))
  expect_true("CR" %in% names(result))
  expect_true("lambda_max" %in% names(result))
  
  # Check values
  expect_equal(result$indicators, c("pH", "OM", "P"))
  expect_equal(sum(result$weights), 1, tolerance = 1e-10)
})


test_that("create_ahp_matrix validates matrix mode inputs", {
  # Missing pairwise matrix
  expect_error(
    create_ahp_matrix(c("A", "B"), mode = "matrix"),
    "pairwise matrix must be provided when mode = 'matrix'"
  )
  
  # Wrong dimensions
  pairwise <- matrix(c(1, 2, 1/2, 1), nrow = 2)
  expect_error(
    create_ahp_matrix(c("A", "B", "C"), mode = "matrix",
                     pairwise = pairwise),
    "pairwise matrix dimensions must match number of indicators"
  )
})


test_that("create_ahp_matrix validates indicators", {
  # Non-character indicators
  expect_error(
    create_ahp_matrix(c(1, 2, 3)),
    "indicators must be a character vector"
  )
  
  # Too few indicators
  expect_error(
    create_ahp_matrix(c("A")),
    "At least 2 indicators are required"
  )
})


test_that("create_ahp_matrix sets matrix row and column names", {
  pairwise <- matrix(c(
    1,   3,
    1/3, 1
  ), nrow = 2, byrow = TRUE)
  
  result <- create_ahp_matrix(
    indicators = c("Ind1", "Ind2"),
    mode = "matrix",
    pairwise = pairwise
  )
  
  expect_equal(rownames(result$matrix), c("Ind1", "Ind2"))
  expect_equal(colnames(result$matrix), c("Ind1", "Ind2"))
})


test_that("print.ahp_matrix displays output without error", {
  pairwise <- matrix(c(
    1,   3,   5,
    1/3, 1,   2,
    1/5, 1/2, 1
  ), nrow = 3, byrow = TRUE)
  
  ahp_obj <- create_ahp_matrix(
    indicators = c("pH", "OM", "P"),
    mode = "matrix",
    pairwise = pairwise
  )
  
  # Should not error
  expect_output(print(ahp_obj), "AHP Pairwise Comparison Matrix")
  expect_output(print(ahp_obj), "Indicator Weights")
  expect_output(print(ahp_obj), "Consistency Information")
  expect_output(print(ahp_obj), "Lambda Max")
  expect_output(print(ahp_obj), "Consistency Ratio")
})


test_that("print.ahp_matrix shows consistency status", {
  # Consistent matrix
  pairwise_good <- matrix(c(
    1,   3,   5,
    1/3, 1,   5/3,
    1/5, 3/5, 1
  ), nrow = 3, byrow = TRUE)
  
  ahp_good <- create_ahp_matrix(
    indicators = c("A", "B", "C"),
    mode = "matrix",
    pairwise = pairwise_good
  )
  
  # Should show acceptable status
  output_good <- capture.output(print(ahp_good))
  expect_true(any(grepl("Acceptable", output_good)))
  
  # Highly inconsistent matrix
  pairwise_bad <- matrix(c(
    1, 9, 1/9,
    1/9, 1, 1/9,
    9, 9, 1
  ), nrow = 3, byrow = TRUE)
  
  ahp_bad <- suppressWarnings(create_ahp_matrix(
    indicators = c("A", "B", "C"),
    mode = "matrix",
    pairwise = pairwise_bad
  ))
  
  # Should show inconsistent status
  output_bad <- capture.output(print(ahp_bad))
  expect_true(any(grepl("Inconsistent", output_bad)))
})


test_that("ahp_matrix object structure is complete", {
  pairwise <- matrix(c(
    1,   2,
    1/2, 1
  ), nrow = 2, byrow = TRUE)
  
  result <- create_ahp_matrix(
    indicators = c("A", "B"),
    mode = "matrix",
    pairwise = pairwise
  )
  
  # Check all required components
  expect_equal(length(result$indicators), 2)
  expect_true(is.matrix(result$matrix))
  expect_equal(dim(result$matrix), c(2, 2))
  expect_equal(length(result$weights), 2)
  expect_true(is.numeric(result$CR))
  expect_true(is.numeric(result$lambda_max))
  expect_equal(names(result$weights), c("A", "B"))
})

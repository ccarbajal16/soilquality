# Tests for reference-soil standardisation

test_that("the reference itself scores exactly 1", {
  # The defining property in all three directions.
  expect_equal(standardize_to_reference(4.2, reference = 4.2), 1)
  expect_equal(standardize_to_reference(1.2, reference = 1.2,
                                        direction = "lower"), 1)
  expect_equal(standardize_to_reference(6.5, reference = 6.5,
                                        direction = "optimum",
                                        tolerance = 1.5), 1)
})

test_that("higher-is-better falls toward 0 with degradation", {
  scores <- standardize_to_reference(c(4.2, 2.1, 0), reference = 4.2)

  expect_equal(scores, c(1, 0.5, 0))
  expect_false(is.unsorted(rev(scores)))
})

test_that("lower-is-better inverts, because the reference holds the minimum", {
  # Bulk density: the undisturbed soil is the least compacted, so a higher
  # value must score worse.
  scores <- standardize_to_reference(c(1.2, 1.5, 1.8), reference = 1.2,
                                     direction = "lower")

  expect_equal(scores[1], 1)
  expect_true(all(diff(scores) < 0))
  expect_equal(scores[2], 1.2 / 1.5)
})

test_that("optimum uses distance from the optimum, not a monotone scale", {
  # Both sides of the optimum must be penalised. A monotone scale would rank
  # pH 8.0 above pH 6.5, which is exactly the error Kuzyakov warns against.
  scores <- standardize_to_reference(c(5.0, 6.5, 8.0), reference = 6.5,
                                     direction = "optimum", tolerance = 1.5)

  expect_equal(scores[2], 1)
  expect_lt(scores[1], scores[2])
  expect_lt(scores[3], scores[2])

  # Symmetric distance gives a symmetric score.
  expect_equal(
    standardize_to_reference(5.5, reference = 6.5, direction = "optimum",
                             tolerance = 1.5),
    standardize_to_reference(7.5, reference = 6.5, direction = "optimum",
                             tolerance = 1.5)
  )
})

test_that("a sample beating the reference is capped and reported", {
  # Not an error, but worth knowing: it usually means the reference is not the
  # least disturbed soil available.
  expect_warning(
    standardize_to_reference(c(4.2, 6.0), reference = 4.2),
    "scored above the reference"
  )

  capped <- suppressWarnings(
    standardize_to_reference(c(4.2, 6.0), reference = 4.2)
  )
  expect_equal(capped, c(1, 1))

  raw <- standardize_to_reference(c(4.2, 6.0), reference = 4.2, clamp = FALSE)
  expect_equal(raw, c(1, 6.0 / 4.2))
})

test_that("clamped scores stay within [0,1]", {
  scores <- standardize_to_reference(c(3.0, 6.5, 10.0), reference = 6.5,
                                     direction = "optimum", tolerance = 1.5)

  expect_true(all(scores >= 0 & scores <= 1))
})

test_that("NA propagates without contaminating other scores", {
  scores <- standardize_to_reference(c(4.2, NA, 2.1), reference = 4.2)

  expect_true(is.na(scores[2]))
  expect_equal(scores[c(1, 3)], c(1, 0.5))
})

test_that("standardize_to_reference validates its arguments", {
  expect_error(standardize_to_reference("a", reference = 1), "x must be numeric")
  expect_error(standardize_to_reference(1, reference = c(1, 2)),
               "single non-missing numeric")
  expect_error(standardize_to_reference(1, reference = 0), "strictly positive")
  expect_error(standardize_to_reference(c(-1, 2), reference = 1),
               "negative values")
  expect_error(
    standardize_to_reference(c(0, 2), reference = 1, direction = "lower"),
    "zero or negative"
  )
  expect_error(
    standardize_to_reference(1, reference = 6.5, direction = "optimum"),
    "tolerance must be a single positive number"
  )
})

test_that("a negative reference is allowed for the optimum direction", {
  # An optimum is a location, not a magnitude, so it need not be positive.
  expect_equal(
    standardize_to_reference(-5, reference = -5, direction = "optimum",
                             tolerance = 2),
    1
  )
})


# ---- the constructor --------------------------------------------------------

test_that("reference_scoring builds a well-formed rule", {
  rule <- reference_scoring(reference = 4.2)

  expect_s3_class(rule, "scoring_rule")
  expect_s3_class(rule, "reference_scoring")
  expect_identical(rule$type, "reference")
  expect_identical(rule$direction, "higher")
  expect_equal(rule$reference, 4.2)
  expect_true(rule$clamp)
})

test_that("reference_scoring validates its arguments", {
  expect_error(reference_scoring(reference = "a"), "single non-missing numeric")
  expect_error(reference_scoring(reference = 0), "strictly positive")
  expect_error(reference_scoring(reference = 6.5, direction = "optimum"),
               "tolerance must be a single positive number")
  expect_error(reference_scoring(reference = 1, direction = "sideways"))
})

test_that("print.scoring_rule handles reference rules", {
  expect_output(print(reference_scoring(reference = 4.2)),
                "Standardised against a reference soil")
  expect_output(print(reference_scoring(reference = 1.2, direction = "lower")),
                "Lower values are better")
  expect_output(
    print(reference_scoring(reference = 6.5, direction = "optimum",
                            tolerance = 1.5)),
    "Distance from the optimum"
  )
})


# ---- wiring into scoring ----------------------------------------------------

test_that("score_indicators accepts the reference type", {
  data <- data.frame(OM = c(2.1, 3.0, 4.2), BD = c(1.2, 1.5, 1.8))

  directions <- list(
    OM = list(type = "reference", reference = 4.2, direction = "higher"),
    BD = list(type = "reference", reference = 1.2, direction = "lower")
  )

  result <- score_indicators(data, c("OM", "BD"), directions)

  expect_equal(result$OM_scored, standardize_to_reference(data$OM, 4.2))
  expect_equal(result$BD_scored,
               standardize_to_reference(data$BD, 1.2, direction = "lower"))
})

test_that("score_indicators requires a reference for the reference type", {
  data <- data.frame(OM = c(2.1, 3.0))

  expect_error(
    score_indicators(data, "OM", list(OM = list(type = "reference"))),
    "reference required"
  )
})

test_that("reference rules flow through compute_sqi_properties", {
  rules <- list(
    OM = reference_scoring(reference = 5.5),
    BD = reference_scoring(reference = 1.0, direction = "lower"),
    pH = reference_scoring(reference = 6.5, direction = "optimum",
                           tolerance = 2)
  )

  result <- suppressWarnings(compute_sqi_properties(
    soil_structured, properties = names(rules), id_column = "SampleID",
    scoring_rules = rules
  ))

  expect_s3_class(result, "sqi_result")
  expect_false(anyNA(result$results$SQI))
  expect_true(all(result$results$SQI >= 0 & result$results$SQI <= 1))
})

test_that("reference scoring is not the same as sample-relative scoring", {
  # The entire point: sample-relative forces the best site to about 1, and
  # reference-relative does not.
  props <- c("OM", "N", "CEC")

  sample_relative <- compute_sqi_properties(
    soil_structured, properties = props, id_column = "SampleID",
    scoring_rules = lapply(props, function(p) higher_better()) |>
      stats::setNames(props)
  )

  generous_reference <- list(
    OM = reference_scoring(reference = 12),
    N = reference_scoring(reference = 1),
    CEC = reference_scoring(reference = 60)
  )
  referenced <- compute_sqi_properties(
    soil_structured, properties = props, id_column = "SampleID",
    scoring_rules = generous_reference
  )

  # Against a far-off reference nothing comes close to 1, whereas the
  # sample-relative index has to reach it.
  expect_gt(max(sample_relative$results$SQI), 0.9)
  expect_lt(max(referenced$results$SQI), 0.5)
})


# ---- sensitivity and resistance ---------------------------------------------

test_that("sensitivity_resistance classifies relative to carbon", {
  degraded  <- c(SOC = 1.0, fast = 0.3, slow = 0.9, same = 0.5)
  reference <- c(SOC = 2.0, fast = 1.0, slow = 1.0, same = 1.0)

  out <- sensitivity_resistance(degraded, reference)

  # SOC halved. `same` also halved -> proportional. `fast` fell further ->
  # sensitive. `slow` barely moved -> resistant.
  expect_identical(out$class[out$indicator == "same"], "proportional")
  expect_identical(out$class[out$indicator == "fast"], "sensitive")
  expect_identical(out$class[out$indicator == "slow"], "resistant")
  expect_identical(out$class[out$indicator == "SOC"], "proportional")
})

test_that("the carbon indicator has a ratio of exactly 1", {
  degraded  <- c(SOC = 1.1, OM = 1.9, BD = 1.55)
  reference <- c(SOC = 2.0, OM = 3.4, BD = 1.25)

  out <- sensitivity_resistance(degraded, reference)

  expect_equal(out$ratio[out$indicator == "SOC"], 1)
})

test_that("results are ordered from most sensitive to most resistant", {
  degraded  <- c(SOC = 1.0, a = 0.2, b = 0.6, c = 1.4)
  reference <- c(SOC = 2.0, a = 1.0, b = 1.0, c = 1.0)

  out <- sensitivity_resistance(degraded, reference)

  expect_false(is.unsorted(out$ratio))
  expect_identical(out$indicator[1], "a")
})

test_that("the tolerance band widens the proportional class", {
  degraded  <- c(SOC = 1.0, near = 0.55)
  reference <- c(SOC = 2.0, near = 1.0)

  narrow <- sensitivity_resistance(degraded, reference, tolerance = 0.01)
  wide <- sensitivity_resistance(degraded, reference, tolerance = 0.5)

  expect_identical(narrow$class[narrow$indicator == "near"], "resistant")
  expect_identical(wide$class[wide$indicator == "near"], "proportional")
})

test_that("sensitivity_resistance accepts one-row data frames", {
  degraded <- data.frame(SOC = 1.0, OM = 1.7)
  reference <- data.frame(SOC = 2.0, OM = 3.4)

  out <- sensitivity_resistance(degraded, reference)

  expect_equal(nrow(out), 2)
  expect_setequal(out$indicator, c("SOC", "OM"))
})

test_that("sensitivity_resistance validates its inputs", {
  d <- c(SOC = 1.0, OM = 1.7)
  r <- c(SOC = 2.0, OM = 3.4)

  expect_error(sensitivity_resistance(d, r[1]), "missing these indicators")
  expect_error(sensitivity_resistance(d, r, carbon = "TOC"),
               "is not among the indicators")
  expect_error(sensitivity_resistance(unname(d), r), "named numeric vector")
  expect_error(
    sensitivity_resistance(d, c(SOC = 0, OM = 3.4)),
    "contains zero values"
  )
  expect_error(
    sensitivity_resistance(c(SOC = 0, OM = 1.7), r),
    "is zero or missing"
  )
  expect_error(
    sensitivity_resistance(data.frame(SOC = c(1, 2), OM = c(1, 2)), r),
    "exactly one row"
  )
})

test_that("indicators degrading together do not separate, and that is reported", {
  # Kuzyakov's Calcic Chernozem case: everything moves at carbon's rate, so
  # nothing is classified as sensitive or resistant. That is a fact about the
  # soil, not a failure of the analysis.
  degraded  <- c(SOC = 1.0, a = 0.5, b = 0.5, c = 0.5)
  reference <- c(SOC = 2.0, a = 1.0, b = 1.0, c = 1.0)

  out <- sensitivity_resistance(degraded, reference)

  expect_true(all(out$class == "proportional"))
  expect_equal(out$ratio, rep(1, 4))
})

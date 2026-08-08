# Tests for non-linear (sigmoidal) scoring
#
# Formula under test:  S = 1 / (1 + (x/x0)^b)
#   direction = "higher" -> exponent -b
#   direction = "lower"  -> exponent +b

test_that("score_sigmoid is monotonically increasing for direction = 'higher'", {
  x <- c(1, 2, 3, 4, 5)
  scores <- score_sigmoid(x, direction = "higher", x0 = 3)

  expect_true(all(diff(scores) > 0))
})

test_that("score_sigmoid is monotonically decreasing for direction = 'lower'", {
  x <- c(1, 2, 3, 4, 5)
  scores <- score_sigmoid(x, direction = "lower", x0 = 3)

  expect_true(all(diff(scores) < 0))
})

test_that("score_sigmoid returns exactly 0.5 at the reference value", {
  # This is the defining property of x0 and holds for both directions,
  # because (x0/x0)^b == 1 regardless of the sign of the exponent.
  expect_equal(score_sigmoid(2.5, direction = "higher", x0 = 2.5), 0.5)
  expect_equal(score_sigmoid(2.5, direction = "lower", x0 = 2.5), 0.5)

  # Also true for any b.
  expect_equal(score_sigmoid(7, direction = "higher", x0 = 7, b = 0.5), 0.5)
  expect_equal(score_sigmoid(7, direction = "lower", x0 = 7, b = 20), 0.5)
})

test_that("score_sigmoid approaches its asymptotes", {
  # direction = "higher": S -> 1 as x >> x0, S -> 0 as x -> 0
  expect_gt(score_sigmoid(1e6, direction = "higher", x0 = 1), 0.999)
  expect_equal(score_sigmoid(0, direction = "higher", x0 = 1), 0)

  # direction = "lower": the mirror image
  expect_lt(score_sigmoid(1e6, direction = "lower", x0 = 1), 0.001)
  expect_equal(score_sigmoid(0, direction = "lower", x0 = 1), 1)
})

test_that("score_sigmoid directions are exact mirror images", {
  x <- c(0.5, 1, 2, 4, 8)

  higher <- score_sigmoid(x, direction = "higher", x0 = 2)
  lower  <- score_sigmoid(x, direction = "lower",  x0 = 2)

  # 1/(1+r^-b) + 1/(1+r^b) == 1 for any r > 0
  expect_equal(higher + lower, rep(1, length(x)))
})

test_that("score_sigmoid output is always in [0,1]", {
  set.seed(42)
  x <- abs(rnorm(200, mean = 5, sd = 3))

  for (dir in c("higher", "lower")) {
    for (bb in c(0.5, 2.5, 10)) {
      scores <- score_sigmoid(x, direction = dir, b = bb)
      expect_true(all(scores >= 0 & scores <= 1),
                  info = paste(dir, bb))
    }
  }
})

test_that("score_sigmoid defaults x0 to the sample mean", {
  x <- c(1, 2, 3, 4, 5)

  expect_equal(
    score_sigmoid(x),
    score_sigmoid(x, x0 = mean(x))
  )

  # And therefore the mean itself scores 0.5.
  expect_equal(score_sigmoid(x)[3], 0.5)
})

test_that("score_sigmoid defaults to direction = 'higher' and b = 2.5", {
  x <- c(1, 2, 3, 4, 5)

  expect_equal(
    score_sigmoid(x),
    score_sigmoid(x, direction = "higher", b = 2.5)
  )
})

test_that("larger b produces a sharper transition around x0", {
  # Away from x0, a larger b pushes the score further toward its asymptote.
  above <- 4
  x0 <- 2

  flat  <- score_sigmoid(above, direction = "higher", x0 = x0, b = 1)
  sharp <- score_sigmoid(above, direction = "higher", x0 = x0, b = 10)

  expect_gt(sharp, flat)

  # But both still cross exactly 0.5 at x0.
  expect_equal(score_sigmoid(x0, x0 = x0, b = 1), 0.5)
  expect_equal(score_sigmoid(x0, x0 = x0, b = 10), 0.5)
})

test_that("score_sigmoid propagates NA without contaminating other scores", {
  x <- c(1, 2, NA, 4, 5)
  scores <- score_sigmoid(x, x0 = 3)

  expect_true(is.na(scores[3]))
  expect_false(anyNA(scores[-3]))

  # The default x0 is computed with na.rm, so an NA does not blank everything.
  scores_default <- score_sigmoid(x)
  expect_equal(sum(is.na(scores_default)), 1)
})

test_that("score_sigmoid rejects negative values rather than returning NaN", {
  # A negative base with a fractional exponent is NaN in real arithmetic.
  # Silently returning NaN scores would be the worst outcome here.
  expect_error(
    score_sigmoid(c(-1, 2, 3), x0 = 2),
    "negative values"
  )
})

test_that("score_sigmoid rejects a non-positive reference value", {
  expect_error(score_sigmoid(c(1, 2, 3), x0 = 0), "strictly positive")
  expect_error(score_sigmoid(c(1, 2, 3), x0 = -5), "strictly positive")
})

test_that("score_sigmoid validates b", {
  expect_error(score_sigmoid(c(1, 2, 3), b = 0), "positive")
  expect_error(score_sigmoid(c(1, 2, 3), b = -2.5), "positive")
  expect_error(score_sigmoid(c(1, 2, 3), b = c(1, 2)), "single positive")
})

test_that("score_sigmoid validates x", {
  expect_error(score_sigmoid("a"), "x must be numeric")
  expect_error(score_sigmoid(c(NA_real_, NA_real_)), "all values in x are NA")
})

test_that("score_sigmoid rejects an unknown direction", {
  expect_error(score_sigmoid(c(1, 2, 3), direction = "sideways"))
})


# ---- constructor ------------------------------------------------------------

test_that("sigmoid_scoring builds a well-formed scoring_rule", {
  rule <- sigmoid_scoring()

  expect_s3_class(rule, "scoring_rule")
  expect_s3_class(rule, "sigmoid_scoring")
  expect_identical(rule$type, "sigmoid")
  expect_identical(rule$direction, "higher")
  expect_null(rule$x0)
  expect_equal(rule$b, 2.5)
})

test_that("sigmoid_scoring carries its arguments through", {
  rule <- sigmoid_scoring(direction = "lower", x0 = 1.4, b = 4)

  expect_identical(rule$direction, "lower")
  expect_equal(rule$x0, 1.4)
  expect_equal(rule$b, 4)
})

test_that("sigmoid_scoring validates its arguments", {
  expect_error(sigmoid_scoring(b = 0), "positive")
  expect_error(sigmoid_scoring(x0 = 0), "strictly positive")
  expect_error(sigmoid_scoring(x0 = "a"), "numeric")
  expect_error(sigmoid_scoring(direction = "sideways"))
})

test_that("print.scoring_rule handles sigmoid rules", {
  expect_output(print(sigmoid_scoring()), "sigmoidal")
  expect_output(print(sigmoid_scoring()), "mean of the indicator")
  expect_output(print(sigmoid_scoring(direction = "lower", x0 = 1.4)), "Lower values")
})


# ---- wiring into score_indicators() ----------------------------------------

test_that("score_indicators accepts the sigmoid type", {
  data <- data.frame(OM = c(1, 2, 3, 4, 5), BD = c(1.2, 1.3, 1.4, 1.5, 1.6))

  directions <- list(
    OM = list(type = "sigmoid", direction = "higher", x0 = 3, b = 2.5),
    BD = list(type = "sigmoid", direction = "lower", x0 = 1.4, b = 2.5)
  )

  result <- score_indicators(data, c("OM", "BD"), directions)

  expect_true(all(c("OM_scored", "BD_scored") %in% names(result)))
  expect_equal(result$OM_scored, score_sigmoid(data$OM, "higher", x0 = 3))
  expect_equal(result$BD_scored, score_sigmoid(data$BD, "lower", x0 = 1.4))
})

test_that("score_indicators applies sigmoid defaults when fields are omitted", {
  data <- data.frame(OM = c(1, 2, 3, 4, 5))

  # Only `type` given: direction defaults to "higher", b to 2.5,
  # x0 to the indicator mean.
  result <- score_indicators(data, "OM", list(OM = list(type = "sigmoid")))

  expect_equal(result$OM_scored, score_sigmoid(data$OM))
  expect_equal(result$OM_scored[3], 0.5)
})

test_that("adding the sigmoid branch left the existing branches untouched", {
  data <- data.frame(
    OM = c(1, 2, 3, 4, 5),
    BD = c(1.2, 1.3, 1.4, 1.5, 1.6),
    pH = c(5.5, 6.0, 7.0, 7.5, 8.0)
  )

  directions <- list(
    OM = list(type = "higher"),
    BD = list(type = "lower"),
    pH = list(type = "optimum", optimum = 7, tol = 1.5)
  )

  result <- score_indicators(data, c("OM", "BD", "pH"), directions)

  expect_equal(result$OM_scored, score_higher_better(data$OM))
  expect_equal(result$BD_scored, score_lower_better(data$BD))
  expect_equal(result$pH_scored, score_optimum(data$pH, optimum = 7, tol = 1.5))
})

test_that("score_indicators still rejects unknown scoring types", {
  data <- data.frame(OM = c(1, 2, 3))

  expect_error(
    score_indicators(data, "OM", list(OM = list(type = "logistic"))),
    "Invalid scoring type"
  )
})


# ---- standard_scoring_rules(scoring = "sigmoid") ----------------------------

test_that("standard_scoring_rules defaults to linear, unchanged", {
  expect_equal(
    standard_scoring_rules("basic"),
    standard_scoring_rules("basic", scoring = "linear")
  )

  rules <- standard_scoring_rules("basic")
  expect_s3_class(rules$OM, "higher_better")
})

test_that("standard_scoring_rules converts monotonic rules to sigmoid", {
  rules <- standard_scoring_rules(c("OM", "BD", "EC", "K"), scoring = "sigmoid")

  expect_s3_class(rules$OM, "sigmoid_scoring")
  expect_s3_class(rules$K,  "sigmoid_scoring")
  expect_identical(rules$OM$direction, "higher")

  # BD and EC are lower-is-better and must keep that direction.
  expect_s3_class(rules$BD, "sigmoid_scoring")
  expect_identical(rules$BD$direction, "lower")
  expect_identical(rules$EC$direction, "lower")
})

test_that("standard_scoring_rules leaves pH as an optimum rule under sigmoid", {
  # The sigmoidal curve is monotonic and has no optimum form, so there is
  # nothing to convert pH to. A "sigmoid" rule set is a mixed set by design.
  rules <- standard_scoring_rules(c("pH", "OM"), scoring = "sigmoid")

  expect_s3_class(rules$pH, "optimum_range")
  expect_s3_class(rules$OM, "sigmoid_scoring")
})

test_that("standard_scoring_rules passes b through to the sigmoid rules", {
  rules <- standard_scoring_rules(c("OM", "BD"), scoring = "sigmoid", b = 6)

  expect_equal(rules$OM$b, 6)
  expect_equal(rules$BD$b, 6)
})

test_that("standard_scoring_rules preserves names under sigmoid conversion", {
  props <- c("pH", "OM", "N", "P", "K", "BD", "EC")
  rules <- standard_scoring_rules(props, scoring = "sigmoid")

  expect_identical(names(rules), props)
  expect_length(rules, length(props))
})


# ---- end-to-end through compute_sqi_properties() ---------------------------

test_that("sigmoid rules flow through compute_sqi_properties", {
  props <- c("pH", "OM", "N", "P", "K", "CEC", "BD")

  result <- compute_sqi_properties(
    soil_data,
    properties    = props,
    id_column     = "SampleID",
    scoring_rules = standard_scoring_rules(props, scoring = "sigmoid")
  )

  expect_s3_class(result, "sqi_result")
  expect_false(anyNA(result$results$SQI))
  expect_true(all(result$results$SQI >= 0 & result$results$SQI <= 1))
})

test_that("linear and sigmoid scoring give different SQI values", {
  # If these came out identical, the sigmoid route would not be wired in.
  props <- c("pH", "OM", "N", "P", "K", "CEC", "BD")

  linear <- compute_sqi_properties(
    soil_data, properties = props, id_column = "SampleID",
    scoring_rules = standard_scoring_rules(props, scoring = "linear")
  )
  sigmoid <- compute_sqi_properties(
    soil_data, properties = props, id_column = "SampleID",
    scoring_rules = standard_scoring_rules(props, scoring = "sigmoid")
  )

  expect_false(isTRUE(all.equal(linear$results$SQI, sigmoid$results$SQI)))

  # The MDS is selected before scoring, so it must be identical.
  expect_identical(linear$mds, sigmoid$mds)
})

# Golden-output regression baseline
#
# PURPOSE
# The rest of the suite tests structure: that components exist, that weights sum
# to 1, that results are reproducible within a single session. None of it pins
# actual numbers. A change to MDS selection or to the aggregation step can move
# every SQI value in the package and still leave those tests green.
#
# This file pins the numeric output of the default pipeline against the shipped
# `soil_data` dataset, as computed by version 1.0.0. Every later change must
# leave these values untouched unless the change is a deliberate, documented
# break -- in which case update the constants here in the same commit and say so
# in NEWS.md.
#
# Baseline captured: R 4.5.3, package commit bc1838e.

baseline_properties <- c("pH", "OM", "N", "P", "K", "CEC", "BD", "Sand", "Clay", "EC")

baseline_result <- function() {
  compute_sqi_properties(
    soil_data,
    properties    = baseline_properties,
    id_column     = "SampleID",
    scoring_rules = standard_scoring_rules(baseline_properties)
  )
}

test_that("baseline: default pipeline selects the same MDS from soil_data", {
  result <- baseline_result()

  # Selection is order-sensitive: one indicator per retained PC, in PC order.
  expect_identical(result$mds, c("BD", "P", "K", "OM", "pH", "EC", "N"))

  # Sand, Clay and CEC are deliberately absent -- they are not the top-loading
  # variable on any PC above var_threshold. If a change adds them, that is the
  # "within 10 % of maximum loading" rule taking effect (plan task 7.1) and it
  # must be opt-in, not a moved default.
  expect_false(any(c("Sand", "Clay", "CEC") %in% result$mds))
})

test_that("baseline: PCA variance decomposition is unchanged", {
  result <- baseline_result()

  expect_equal(
    unname(round(result$var_exp[1:5], 7)),
    c(0.1841037, 0.1429610, 0.1268549, 0.1080581, 0.1002731),
    tolerance = 1e-7
  )

  # Variance explained must remain a proper decomposition.
  expect_equal(sum(result$var_exp), 1, tolerance = 1e-10)
})

test_that("baseline: equal weighting is applied when no pairwise matrix is given", {
  result <- baseline_result()

  expect_equal(
    unname(result$weights),
    rep(1 / 7, 7),
    tolerance = 1e-10
  )
  expect_identical(names(result$weights), result$mds)
  expect_equal(result$CR, 0, tolerance = 1e-10)
})

test_that("baseline: SQI values are numerically unchanged", {
  result <- baseline_result()
  sqi <- result$results$SQI

  expect_length(sqi, nrow(soil_data))
  expect_false(anyNA(sqi))

  expect_equal(
    round(head(sqi, 6), 7),
    c(0.6857017, 0.3576031, 0.3823868, 0.5542549, 0.5133467, 0.3551346),
    tolerance = 1e-7
  )

  expect_equal(
    round(c(mean(sqi), sd(sqi), min(sqi), max(sqi)), 7),
    c(0.4737929, 0.0778799, 0.3551346, 0.6955874),
    tolerance = 1e-7
  )
})

test_that("baseline: SQI stays within the unit interval", {
  sqi <- baseline_result()$results$SQI

  # A weighted mean of [0,1] scores with weights summing to 1 cannot leave [0,1].
  # Any aggregation method added later must preserve this or document why not.
  expect_true(all(sqi >= 0 & sqi <= 1))
})

test_that("baseline: every MDS indicator gets a scored column in [0,1]", {
  result <- baseline_result()

  scored_cols <- paste0(result$mds, "_scored")
  expect_true(all(scored_cols %in% names(result$results)))

  for (col in scored_cols) {
    scores <- result$results[[col]]
    expect_false(anyNA(scores), info = col)
    expect_true(all(scores >= 0 & scores <= 1), info = col)
  }
})

test_that("baseline: the wrapper and the engine agree", {
  # compute_sqi_properties() is a thin wrapper over compute_sqi_df(). New
  # aggregation routes must be wired into the engine, so this equivalence has to
  # keep holding -- if it breaks, the wrapper grew behaviour the engine lacks.
  via_wrapper <- compute_sqi_properties(
    soil_data,
    properties = baseline_properties,
    id_column  = "SampleID"
  )
  via_engine <- compute_sqi_df(
    soil_data[, c("SampleID", baseline_properties)],
    id_column = "SampleID"
  )

  expect_identical(via_wrapper$mds, via_engine$mds)
  expect_equal(via_wrapper$weights, via_engine$weights, tolerance = 1e-10)
  expect_equal(via_wrapper$results$SQI, via_engine$results$SQI, tolerance = 1e-10)
})

# Tests for area-based aggregation
#
# Formula under test (Kuzyakov et al. 2020, eq. 2):
#   A = 0.5 * sum(s^2) * sin(2*pi / n)
# Used as a ratio A_sample / A_reference when a reference soil is supplied.

test_that("sqi_area matches the published formula", {
  s <- c(0.8, 0.6, 0.7, 0.9, 0.5)
  expected <- 0.5 * sum(s^2) * sin(2 * pi / length(s))

  expect_equal(sqi_area(s), expected)
})

test_that("sqi_area is invariant to indicator order", {
  # This is the entire point of using the square form rather than the true
  # polygon area sum(s_i * s_{i+1}), which would depend on the arbitrary
  # order of indicators around the diagram.
  s <- c(0.8, 0.6, 0.7, 0.9, 0.5)

  expect_equal(sqi_area(s), sqi_area(rev(s)))

  set.seed(1)
  for (i in 1:20) {
    expect_equal(sqi_area(s), sqi_area(sample(s)))
  }
})

test_that("sqi_area is maximised by all-perfect scores", {
  n <- 6
  perfect <- rep(1, n)

  expect_equal(sqi_area(perfect), 0.5 * n * sin(2 * pi / n))

  # Any degradation strictly reduces the area.
  set.seed(7)
  for (i in 1:20) {
    degraded <- runif(n, 0, 1)
    expect_lt(sqi_area(degraded), sqi_area(perfect))
  }
})

test_that("sqi_area returns zero for all-zero scores", {
  expect_equal(sqi_area(rep(0, 5)), 0)
})

test_that("sqi_area ratio of a vector with itself is exactly 1", {
  s <- c(0.8, 0.6, 0.7, 0.9, 0.5)

  expect_equal(sqi_area(s, reference = s), 1)
})

test_that("sqi_area ratio is below 1 for a uniformly degraded vector", {
  reference <- rep(1, 5)

  expect_lt(sqi_area(rep(0.7, 5), reference = reference), 1)
  expect_lt(sqi_area(c(0.8, 0.6, 0.7, 0.9, 0.5), reference = reference), 1)

  # Against an all-1.0 reference the ratio reduces to mean(s^2).
  s <- c(0.8, 0.6, 0.7, 0.9, 0.5)
  expect_equal(sqi_area(s, reference = rep(1, 5)), mean(s^2))
})

test_that("sqi_area ratio is above 1 when the sample beats the reference", {
  expect_gt(sqi_area(rep(0.9, 5), reference = rep(0.5, 5)), 1)
})

test_that("sqi_area ratio cancels the n-dependence of the absolute area", {
  # Absolute areas for different n are not comparable...
  expect_false(isTRUE(all.equal(sqi_area(rep(0.5, 4)), sqi_area(rep(0.5, 8)))))

  # ...but the ratio against an equally-sized reference is.
  ratio_4 <- sqi_area(rep(0.5, 4), reference = rep(1, 4))
  ratio_8 <- sqi_area(rep(0.5, 8), reference = rep(1, 8))

  expect_equal(ratio_4, ratio_8)
})

test_that("sqi_area warns when sample and reference have different lengths", {
  expect_warning(
    sqi_area(rep(0.5, 5), reference = rep(1, 7)),
    "different geometries"
  )
})

test_that("sqi_area rejects fewer than three indicators", {
  expect_error(sqi_area(c(0.5, 0.6)), "at least 3 scores")
  expect_error(sqi_area(0.5), "at least 3 scores")
})

test_that("sqi_area rejects negative scores", {
  expect_error(sqi_area(c(0.5, -0.1, 0.7)), "negative scores")
  expect_error(
    sqi_area(c(0.5, 0.6, 0.7), reference = c(1, -1, 1)),
    "negative scores"
  )
})

test_that("sqi_area handles NA deliberately, not silently", {
  s <- c(0.8, 0.6, NA, 0.9, 0.5)

  # Default refuses: dropping an indicator changes n and therefore the area.
  expect_error(sqi_area(s), "na.rm = TRUE")

  # Opt in and it drops, with n reduced accordingly.
  expect_equal(sqi_area(s, na.rm = TRUE), sqi_area(c(0.8, 0.6, 0.9, 0.5)))
})

test_that("sqi_area rejects a zero-area reference", {
  expect_error(
    sqi_area(c(0.5, 0.6, 0.7), reference = rep(0, 3)),
    "reference area is zero"
  )
})

test_that("sqi_area validates types", {
  expect_error(sqi_area("a"), "must be a numeric vector")
  expect_error(sqi_area(c(0.5, 0.6, 0.7), reference = "a"), "must be a numeric vector")
})


# ---- wiring into compute_sqi_df() ------------------------------------------

test_that("compute_sqi_df defaults to the weighted method, unchanged", {
  props <- c("pH", "OM", "N", "P", "K", "CEC", "BD")
  df <- soil_data[, c("SampleID", props)]

  default  <- compute_sqi_df(df, id_column = "SampleID")
  explicit <- compute_sqi_df(df, id_column = "SampleID", method = "weighted")

  expect_equal(default$results$SQI, explicit$results$SQI)
  expect_identical(default$method, "weighted")
})

test_that("compute_sqi_df computes the area method per sample", {
  props <- c("pH", "OM", "N", "P", "K", "CEC", "BD")
  df <- soil_data[, c("SampleID", props)]

  result <- compute_sqi_df(df, id_column = "SampleID", method = "area")

  expect_identical(result$method, "area")
  expect_length(result$results$SQI, nrow(soil_data))
  expect_false(anyNA(result$results$SQI))

  # Recompute the first sample by hand from its scored columns.
  scored_cols <- paste0(result$mds, "_scored")
  row1 <- as.numeric(result$results[1, scored_cols])
  expect_equal(result$results$SQI[1], sqi_area(row1))
})

test_that("compute_sqi_df area method ignores weights", {
  props <- c("pH", "OM", "N", "P", "K", "CEC", "BD")
  df <- soil_data[, c("SampleID", props)]

  equal_w <- compute_sqi_df(df, id_column = "SampleID", method = "area")

  # Weights are still reported for comparison against the weighted route,
  # but they must not enter the area calculation.
  expect_true("weights" %in% names(equal_w))
  expect_equal(unname(equal_w$weights), rep(1 / length(equal_w$mds),
                                            length(equal_w$mds)))
})

test_that("compute_sqi_df area method accepts a named reference vector", {
  props <- c("pH", "OM", "N", "P", "K", "CEC", "BD")
  df <- soil_data[, c("SampleID", props)]

  absolute <- compute_sqi_df(df, id_column = "SampleID", method = "area")

  reference <- setNames(rep(1, length(absolute$mds)), absolute$mds)
  ratio <- compute_sqi_df(df, id_column = "SampleID", method = "area",
                          reference = reference)

  # Against an all-1.0 reference the ratio is the absolute area divided by
  # the maximum attainable area for that n.
  n <- length(absolute$mds)
  max_area <- 0.5 * n * sin(2 * pi / n)
  expect_equal(ratio$results$SQI, absolute$results$SQI / max_area)

  # And a ratio against a perfect reference cannot exceed 1.
  expect_true(all(ratio$results$SQI <= 1))
})

test_that("compute_sqi_df matches the reference to the MDS by name, not position", {
  props <- c("pH", "OM", "N", "P", "K", "CEC", "BD")
  df <- soil_data[, c("SampleID", props)]

  mds <- compute_sqi_df(df, id_column = "SampleID", method = "area")$mds

  reference <- setNames(seq(0.5, 1, length.out = length(mds)), mds)
  shuffled  <- reference[rev(names(reference))]

  in_order <- compute_sqi_df(df, id_column = "SampleID", method = "area",
                             reference = reference)
  shuffled_order <- compute_sqi_df(df, id_column = "SampleID", method = "area",
                                   reference = shuffled)

  expect_equal(in_order$results$SQI, shuffled_order$results$SQI)
})

test_that("compute_sqi_df rejects an unnamed or incomplete reference", {
  props <- c("pH", "OM", "N", "P", "K", "CEC", "BD")
  df <- soil_data[, c("SampleID", props)]

  expect_error(
    compute_sqi_df(df, id_column = "SampleID", method = "area",
                   reference = rep(1, 7)),
    "must be a named numeric vector"
  )

  expect_error(
    compute_sqi_df(df, id_column = "SampleID", method = "area",
                   reference = c(pH = 1, OM = 1)),
    "missing values for these selected MDS"
  )
})

test_that("compute_sqi_df warns when reference is given without the area method", {
  props <- c("pH", "OM", "N", "P", "K", "CEC", "BD")
  df <- soil_data[, c("SampleID", props)]

  expect_warning(
    compute_sqi_df(df, id_column = "SampleID", reference = c(pH = 1)),
    "only used when method"
  )
})

test_that("compute_sqi_df rejects an unknown method", {
  props <- c("pH", "OM", "N", "P")
  df <- soil_data[, c("SampleID", props)]

  expect_error(compute_sqi_df(df, id_column = "SampleID", method = "geometric"))
})

test_that("the area method requires at least three MDS indicators", {
  # Two indicators cannot describe a polygon; the error must say so rather
  # than producing a meaningless number.
  set.seed(11)
  df <- data.frame(
    SampleID = paste0("S", 1:20),
    A = rnorm(20, 10, 2),
    B = rnorm(20, 5, 1)
  )

  expect_error(
    compute_sqi_df(df, id_column = "SampleID", method = "area"),
    "at least 3 MDS indicators"
  )
})


# ---- the method flows through both wrappers --------------------------------

test_that("compute_sqi_properties forwards method to the engine", {
  props <- c("pH", "OM", "N", "P", "K", "CEC", "BD")

  via_wrapper <- compute_sqi_properties(
    soil_data, properties = props, id_column = "SampleID", method = "area"
  )
  via_engine <- compute_sqi_df(
    soil_data[, c("SampleID", props)], id_column = "SampleID", method = "area"
  )

  expect_identical(via_wrapper$method, "area")
  expect_equal(via_wrapper$results$SQI, via_engine$results$SQI)
})

test_that("weighted and area aggregation give different indices", {
  # If these agreed, the area route would not be wired in.
  props <- c("pH", "OM", "N", "P", "K", "CEC", "BD")

  weighted <- compute_sqi_properties(soil_data, properties = props,
                                     id_column = "SampleID", method = "weighted")
  area <- compute_sqi_properties(soil_data, properties = props,
                                 id_column = "SampleID", method = "area")

  expect_false(isTRUE(all.equal(weighted$results$SQI, area$results$SQI)))

  # Selection and scoring happen before aggregation, so the MDS is identical.
  expect_identical(weighted$mds, area$mds)
})

# Tests for SQI validation and recipe comparison

baseline_props <- c("pH", "OM", "N", "P", "K", "CEC", "BD")

example_result <- function() {
  compute_sqi_properties(soil_data, properties = baseline_props,
                         id_column = "SampleID")
}

# The default recipe on soil_data legitimately trips the middle-band warning:
# its SQI spans 0.36-0.70, so every sample lands between the 0.2 and 0.8
# boundaries. That is the diagnostic doing its job, and it is asserted
# explicitly further down. Tests that are about something else silence it
# rather than asserting on incidental noise.
validate_quietly <- function(...) suppressWarnings(sqi_validate(...))


# ---- the distribution diagnostic -------------------------------------------

test_that("bands are cut on the index value scale, not the empirical CDF", {
  # This is the whole point of the diagnostic. Cutting ecdf(x)(x) into equal
  # bands returns n/5 in every band for ANY index, so it could never show the
  # contrast Maaz (2023) reported. These two indices must NOT look alike.
  set.seed(1)
  compressed <- runif(100, 0.45, 0.55)   # calls everything "medium"
  spread     <- runif(100, 0.05, 0.95)   # discriminates

  v_compressed <- suppressWarnings(sqi_validate(compressed))
  v_spread     <- sqi_validate(spread)

  expect_equal(v_compressed$distribution$count, c(0L, 0L, 100L, 0L, 0L))
  expect_equal(v_compressed$middle_band_share, 1)

  # The spread index must put samples in the extreme bands.
  expect_gt(v_spread$distribution$count[1], 0)
  expect_gt(v_spread$distribution$count[5], 0)
  expect_lt(v_spread$middle_band_share, 1)
})

test_that("distribution counts and proportions are consistent", {
  v <- validate_quietly(example_result())

  expect_equal(sum(v$distribution$count), v$n)
  expect_equal(sum(v$distribution$proportion), 1)
  expect_true(all(v$distribution$proportion >= 0))
})

test_that("the five conventional soil-health categories are named", {
  v <- validate_quietly(example_result())

  expect_identical(
    v$distribution$band,
    c("very low", "low", "medium", "high", "very high")
  )
})

test_that("the package's own default recipe trips the diagnostic on soil_data", {
  # A substantive finding, not a mechanical assertion. The default pipeline
  # (PCA-MDS, equal weights, linear scoring, weighted additive) applied to the
  # shipped example data produces an SQI spanning roughly 0.36-0.70, so every
  # single sample lands in the middle bands. This is precisely the pathology
  # Maaz (2023) identified: the index declines to call any sample clearly good
  # or clearly bad. It is pinned here so that a future change to the default
  # route is noticed if it alters this.
  expect_warning(sqi_validate(example_result()), "100% of samples")

  v <- validate_quietly(example_result())

  expect_equal(v$middle_band_share, 1)
  expect_equal(v$distribution$count[1], 0L)   # very low: empty
  expect_equal(v$distribution$count[5], 0L)   # very high: empty
})

test_that("middle_band_share excludes only the two extreme bands", {
  v <- sqi_validate(c(0.1, 0.3, 0.5, 0.7, 0.9))

  # One sample per band: 3 of 5 are in the middle three bands.
  expect_equal(v$distribution$count, rep(1L, 5))
  expect_equal(v$middle_band_share, 3 / 5)
})

test_that("sqi_validate warns above the middle-band threshold", {
  compressed <- rep(c(0.48, 0.52), 25)

  expect_warning(sqi_validate(compressed), "middle bands")
  expect_warning(sqi_validate(compressed), "cannot inform a decision")

  # And stays silent when the index discriminates.
  expect_no_warning(sqi_validate(c(rep(0.1, 40), rep(0.9, 40), 0.5)))
})

test_that("the middle-band warning can be disabled but still reported", {
  compressed <- rep(c(0.48, 0.52), 25)

  v <- expect_no_warning(
    sqi_validate(compressed, middle_band_threshold = NA)
  )

  expect_equal(v$middle_band_share, 1)
})

test_that("custom bands are honoured and labelled", {
  v <- sqi_validate(c(0.1, 0.5, 0.9), bands = c(0, 0.5, 1))

  expect_equal(nrow(v$distribution), 2)
  expect_identical(v$distribution$band, c("0-0.5", "0.5-1"))
})

test_that("values outside the bands are excluded with a warning", {
  # An absolute area index is not on a [0,1] scale.
  # NOTE: expect_warning() returns the condition, not the value, so the value
  # has to be captured separately.
  expect_warning(sqi_validate(c(0.2, 0.5, 0.8, 3.4, 7.1)), "fall outside")

  v <- suppressWarnings(sqi_validate(c(0.2, 0.5, 0.8, 3.4, 7.1)))

  expect_equal(v$out_of_bands, 2)
  expect_equal(sum(v$distribution$count), 3)
})


# ---- sensitivity index ------------------------------------------------------

test_that("sensitivity index is max/min", {
  v <- validate_quietly(c(0.2, 0.4, 0.6, 0.8))

  expect_equal(v$sensitivity, 0.8 / 0.2)
})

test_that("sensitivity index handles a zero minimum", {
  expect_warning(sqi_validate(c(0, 0.5, 0.9)), "sensitivity index")

  v <- suppressWarnings(sqi_validate(c(0, 0.5, 0.9)))
  expect_equal(v$sensitivity, Inf)
})

test_that("range reports min, max, mean and sd", {
  x <- c(0.2, 0.4, 0.6, 0.8)
  v <- validate_quietly(x)

  expect_equal(v$range[["min"]], 0.2)
  expect_equal(v$range[["max"]], 0.8)
  expect_equal(v$range[["mean"]], mean(x))
  expect_equal(v$range[["sd"]], sd(x))
})


# ---- fidelity to the total data set ----------------------------------------

test_that("select = 'none' builds a total-data-set index", {
  df <- soil_data[, c("SampleID", baseline_props)]

  tds <- compute_sqi_df(df, id_column = "SampleID", select = "none")

  # Every numeric indicator is retained, not a PCA-selected subset.
  expect_setequal(tds$mds, baseline_props)
  expect_length(tds$mds, length(baseline_props))

  # And the PCA selection is strictly smaller here.
  mds <- compute_sqi_df(df, id_column = "SampleID")
  expect_lt(length(mds$mds), length(tds$mds))
})

test_that("select defaults to pca, unchanged", {
  df <- soil_data[, c("SampleID", baseline_props)]

  default  <- compute_sqi_df(df, id_column = "SampleID")
  explicit <- compute_sqi_df(df, id_column = "SampleID", select = "pca")

  expect_identical(default$mds, explicit$mds)
  expect_equal(default$results$SQI, explicit$results$SQI)
})

test_that("fidelity reports the R-squared of the MDS on the TDS index", {
  df <- soil_data[, c("SampleID", baseline_props)]
  mds <- compute_sqi_df(df, id_column = "SampleID")
  tds <- compute_sqi_df(df, id_column = "SampleID", select = "none")

  v <- validate_quietly(mds, tds = tds)

  expect_false(is.null(v$fidelity))
  expect_true(v$fidelity$r_squared >= 0 && v$fidelity$r_squared <= 1)
  expect_equal(v$fidelity$n, nrow(soil_data))

  # Cross-check against a plain regression.
  fit <- lm(mds$results$SQI ~ tds$results$SQI)
  expect_equal(v$fidelity$r_squared, summary(fit)$r.squared)
})

test_that("fidelity of an index against itself is exactly 1", {
  x <- example_result()

  v <- validate_quietly(x, tds = x)
  expect_equal(v$fidelity$r_squared, 1)
})

test_that("fidelity requires matching lengths", {
  expect_error(
    sqi_validate(c(0.2, 0.5, 0.8), tds = c(0.1, 0.2)),
    "computed over the same samples"
  )
})

test_that("fidelity is absent when no tds is supplied", {
  expect_null(validate_quietly(example_result())$fidelity)
})


# ---- external criterion -----------------------------------------------------

test_that("external criterion reports the correlation and p-value", {
  set.seed(3)
  sqi <- runif(30, 0.2, 0.9)
  yield <- 2 * sqi + rnorm(30, 0, 0.05)

  v <- validate_quietly(sqi, external = yield)

  expect_false(is.null(v$external))
  expect_gt(v$external$estimate, 0.9)
  expect_lt(v$external$p_value, 0.001)
  expect_identical(v$external$method, "pearson")
  expect_equal(v$external$n, 30)
})

test_that("external criterion honours the requested method", {
  set.seed(4)
  sqi <- runif(30, 0.2, 0.9)
  yield <- rank(sqi) + rnorm(30, 0, 0.1)

  v <- validate_quietly(sqi, external = yield, external_method = "spearman")

  expect_identical(v$external$method, "spearman")
  expect_gt(v$external$estimate, 0.95)
})

test_that("external criterion validates its input", {
  expect_error(sqi_validate(c(0.2, 0.5, 0.8), external = c(1, 2)),
               "same samples")
  expect_error(sqi_validate(c(0.2, 0.5, 0.8), external = c("a", "b", "c")),
               "must be a numeric vector")
})

test_that("external criterion is absent when not supplied", {
  expect_null(validate_quietly(example_result())$external)
})


# ---- input handling ---------------------------------------------------------

test_that("sqi_validate accepts an sqi_result or a bare numeric vector", {
  result <- example_result()

  from_object <- validate_quietly(result)
  from_vector <- validate_quietly(result$results$SQI)

  expect_equal(from_object$distribution, from_vector$distribution)
  expect_equal(from_object$sensitivity, from_vector$sensitivity)
})

test_that("sqi_validate rejects unusable input", {
  expect_error(sqi_validate("a"), "must be an sqi_result object or a numeric")
  expect_error(sqi_validate(list(1, 2)), "must be an sqi_result object")
  expect_error(sqi_validate(0.5), "At least 2 non-missing")
})

test_that("sqi_validate drops NA values from the index", {
  v <- validate_quietly(c(0.2, NA, 0.5, 0.8, NA))

  expect_equal(v$n, 3)
  expect_equal(sum(v$distribution$count), 3)
})

test_that("sqi_validate validates the bands argument", {
  expect_error(sqi_validate(c(0.2, 0.5), bands = c(0, 1)), "at least 3")
  expect_error(sqi_validate(c(0.2, 0.5), bands = c(1, 0.5, 0)), "increasing")
})

test_that("print.sqi_validation surfaces the distribution first", {
  v <- validate_quietly(example_result())
  out <- capture.output(print(v))

  # The distribution must appear before the sensitivity index.
  dist_line <- grep("Distribution across decision categories", out)
  sens_line <- grep("Sensitivity index", out)

  expect_length(dist_line, 1)
  expect_length(sens_line, 1)
  expect_lt(dist_line, sens_line)
})

test_that("print.sqi_validation flags an index that does not discriminate", {
  v <- suppressWarnings(sqi_validate(rep(c(0.48, 0.52), 25)))
  out <- capture.output(print(v))

  expect_true(any(grepl("WARNING", out)))
  expect_true(any(grepl("cannot inform a decision", out)))
})


# ---- sqi_stability ------------------------------------------------------------

test_that("sqi_stability reports Spearman rho for every pair", {
  linear <- compute_sqi_properties(
    soil_data, properties = baseline_props, id_column = "SampleID",
    scoring_rules = standard_scoring_rules(baseline_props, scoring = "linear")
  )
  sigmoid <- compute_sqi_properties(
    soil_data, properties = baseline_props, id_column = "SampleID",
    scoring_rules = standard_scoring_rules(baseline_props, scoring = "sigmoid")
  )

  cmp <- sqi_stability(linear = linear, sigmoid = sigmoid)

  expect_equal(nrow(cmp$pairs), 1)
  expect_identical(cmp$pairs$a, "linear")
  expect_identical(cmp$pairs$b, "sigmoid")
  expect_true(cmp$pairs$spearman >= -1 && cmp$pairs$spearman <= 1)
  expect_equal(cmp$n, nrow(soil_data))
})

test_that("sqi_stability enumerates all pairs of three indices", {
  a <- c(0.1, 0.5, 0.9)
  b <- c(0.2, 0.4, 0.8)
  c_ <- c(0.9, 0.5, 0.1)

  cmp <- sqi_stability(a = a, b = b, c = c_)

  expect_equal(nrow(cmp$pairs), 3)
  expect_setequal(paste(cmp$pairs$a, cmp$pairs$b), c("a b", "a c", "b c"))
})

test_that("sqi_stability detects a perfectly preserved ranking", {
  a <- c(0.1, 0.5, 0.9)
  b <- c(0.2, 0.6, 0.95)   # same order, different values

  cmp <- sqi_stability(a = a, b = b)

  expect_equal(cmp$pairs$spearman, 1)
  expect_true(cmp$pairs$top_preserved)
  expect_true(cmp$pairs$bottom_preserved)
  expect_true(cmp$stable)
})

test_that("sqi_stability flags a reversed ranking", {
  a <- c(0.1, 0.5, 0.9)
  b <- rev(a)

  cmp <- sqi_stability(a = a, b = b)

  expect_equal(cmp$pairs$spearman, -1)
  expect_false(cmp$pairs$top_preserved)
  expect_false(cmp$pairs$bottom_preserved)
  expect_false(cmp$stable)
})

test_that("sqi_stability flags a changed extreme despite high rank correlation", {
  # The case the docs warn about: rho is high, but the top sample moved.
  a <- c(0.90, 0.89, 0.5, 0.3, 0.1)
  b <- c(0.89, 0.90, 0.5, 0.3, 0.1)

  cmp <- sqi_stability(a = a, b = b)

  expect_gt(cmp$pairs$spearman, 0.8)
  expect_false(cmp$pairs$top_preserved)
  expect_true(cmp$pairs$bottom_preserved)
  expect_false(cmp$stable)
})

test_that("sqi_stability labels unnamed inputs", {
  cmp <- sqi_stability(c(0.1, 0.5, 0.9), c(0.2, 0.4, 0.8))

  expect_identical(cmp$pairs$a, "index_1")
  expect_identical(cmp$pairs$b, "index_2")
})

test_that("sqi_stability accepts an explicit labels argument", {
  cmp <- sqi_stability(c(0.1, 0.5, 0.9), c(0.2, 0.4, 0.8),
                     labels = c("weighted", "area"))

  expect_identical(cmp$pairs$a, "weighted")
  expect_identical(cmp$pairs$b, "area")
})

test_that("sqi_stability validates its input", {
  expect_error(sqi_stability(c(0.1, 0.5, 0.9)), "at least 2 indices")
  expect_error(
    sqi_stability(a = c(0.1, 0.5, 0.9), b = c(0.1, 0.5)),
    "same samples"
  )
  expect_error(
    sqi_stability(c(0.1, 0.5), c(0.2, 0.4), labels = c("only_one")),
    "labels has 1 entries"
  )
})

test_that("sqi_stability mixes sqi_result objects and numeric vectors", {
  result <- example_result()

  cmp <- sqi_stability(object = result, vector = result$results$SQI)

  expect_equal(cmp$pairs$spearman, 1)
  expect_true(cmp$stable)
})

test_that("print.sqi_stability reports stability", {
  stable <- sqi_stability(a = c(0.1, 0.5, 0.9), b = c(0.2, 0.6, 0.95))
  unstable <- sqi_stability(a = c(0.1, 0.5, 0.9), b = c(0.9, 0.5, 0.1))

  expect_true(any(grepl("Both extremes are preserved",
                        capture.output(print(stable)))))
  expect_true(any(grepl("disagrees on the best or worst",
                        capture.output(print(unstable)))))
})


# ---- weighted vs area, end to end -------------------------------------------

test_that("sqi_stability works across aggregation methods", {
  weighted <- compute_sqi_properties(soil_data, properties = baseline_props,
                                     id_column = "SampleID", method = "weighted")
  area <- compute_sqi_properties(soil_data, properties = baseline_props,
                                 id_column = "SampleID", method = "area")

  cmp <- sqi_stability(weighted = weighted, area = area)

  expect_equal(cmp$n, nrow(soil_data))
  expect_false(is.na(cmp$pairs$spearman))
})


# ---- plot -------------------------------------------------------------------

test_that("plot_sqi_validation returns the validation object invisibly", {
  pdf(NULL)
  on.exit(dev.off())

  v <- validate_quietly(example_result())
  ret <- plot_sqi_validation(v)

  expect_s3_class(ret, "sqi_validation")
  expect_equal(ret$distribution, v$distribution)
})

test_that("plot_sqi_validation accepts an sqi_result directly", {
  pdf(NULL)
  on.exit(dev.off())

  ret <- suppressWarnings(plot_sqi_validation(example_result()))

  expect_s3_class(ret, "sqi_validation")
})

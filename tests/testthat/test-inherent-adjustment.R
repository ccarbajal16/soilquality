# Tests for the inherent-property adjustment
#
# The dataset was built with a known injected truth, so these assert against
# the numbers the generator used rather than against whatever came out.

adj_indicators <- c("OM", "CEC", "pH", "P", "BD")
adj_inherent <- ~ soil_type * land_use_history

p_of <- function(response, predictor, data) {
  stats::anova(
    stats::lm(stats::reformulate(predictor, response), data = data)
  )[["Pr(>F)"]][1]
}


# ---- the two-sided property -------------------------------------------------

test_that("adjustment removes the inherent effect", {
  result <- adjust_inherent(soil_inherent, adj_indicators, adj_inherent)

  for (v in c("CEC", "pH")) {
    expect_lt(p_of(v, "soil_type", soil_inherent), 1e-20, label = v)
    expect_gt(p_of(v, "soil_type", result$data), 0.99, label = v)
  }
})

test_that("adjustment PRESERVES the management effect", {
  # The half that matters. An adjustment removing both would be useless.
  result <- adjust_inherent(soil_inherent, adj_indicators, adj_inherent)

  for (v in c("OM", "P", "BD")) {
    expect_lt(p_of(v, "management", result$data), 0.01, label = v)
  }
})

test_that("adjustment sharpens the management signal it preserves", {
  # Removing the inherited variation takes noise out of the comparison, so the
  # management contrast gets stronger rather than merely surviving.
  result <- adjust_inherent(soil_inherent, adj_indicators, adj_inherent)

  for (v in c("OM", "CEC")) {
    expect_lt(p_of(v, "management", result$data),
              p_of(v, "management", soil_inherent),
              label = v)
  }
})


# ---- what the adjustment cost -----------------------------------------------

test_that("r_squared reports the share that was inheritance", {
  result <- adjust_inherent(soil_inherent, adj_indicators, adj_inherent)

  expect_length(result$r_squared, length(adj_indicators))
  expect_setequal(names(result$r_squared), adj_indicators)
  expect_true(all(result$r_squared >= 0 & result$r_squared <= 1))
})

test_that("r_squared separates inherited indicators from managed ones", {
  result <- adjust_inherent(soil_inherent, adj_indicators, adj_inherent)

  # Parent material sets these.
  expect_gt(result$r_squared[["pH"]], 0.8)
  expect_gt(result$r_squared[["CEC"]], 0.8)

  # Management sets these, so there is little inheritance to remove.
  expect_lt(result$r_squared[["P"]], 0.5)
  expect_lt(result$r_squared[["BD"]], 0.5)
})

test_that("r_squared matches the model it came from", {
  result <- adjust_inherent(soil_inherent, adj_indicators, adj_inherent)

  for (v in adj_indicators) {
    expect_equal(result$r_squared[[v]],
                 summary(result$models[[v]])$r.squared,
                 tolerance = 1e-12, info = v)
  }
})

test_that("a saturated indicator is flagged", {
  # Clay is almost entirely parent material, so almost nothing survives.
  expect_warning(
    adjust_inherent(soil_inherent, "Clay", adj_inherent,
                    warn_r_squared = 0.9),
    "largely noise"
  )

  expect_no_warning(
    adjust_inherent(soil_inherent, "Clay", adj_inherent,
                    warn_r_squared = NA)
  )
})


# ---- the adjusted values behave --------------------------------------------

test_that("the scale is preserved so scoring functions still behave", {
  result <- adjust_inherent(soil_inherent, adj_indicators, adj_inherent)

  for (v in adj_indicators) {
    # Recentred on the indicator's own mean.
    expect_equal(mean(result$data[[v]]), mean(soil_inherent[[v]]),
                 tolerance = 1e-10, info = v)
    # And the spread must shrink, since variation was removed.
    expect_lt(stats::sd(result$data[[v]]), stats::sd(soil_inherent[[v]]),
              label = v)
  }
})

test_that("columns that were not adjusted are untouched", {
  result <- adjust_inherent(soil_inherent, c("OM", "CEC"), adj_inherent)

  untouched <- setdiff(names(soil_inherent), c("OM", "CEC"))
  for (v in untouched) {
    expect_identical(result$data[[v]], soil_inherent[[v]], info = v)
  }
})

test_that("row order and shape are preserved", {
  result <- adjust_inherent(soil_inherent, adj_indicators, adj_inherent)

  expect_equal(nrow(result$data), nrow(soil_inherent))
  expect_identical(names(result$data), names(soil_inherent))
  expect_identical(result$data$SampleID, soil_inherent$SampleID)
})

test_that("NA values stay aligned to their rows", {
  # na.exclude keeps the residual vector full length; without it the rows
  # would silently shift.
  d <- soil_inherent
  d$OM[c(3, 17, 90)] <- NA

  result <- adjust_inherent(d, "OM", adj_inherent)

  expect_equal(nrow(result$data), nrow(d))
  expect_true(all(is.na(result$data$OM[c(3, 17, 90)])))
  expect_false(anyNA(result$data$OM[-c(3, 17, 90)]))
})


# ---- method = "none" --------------------------------------------------------

test_that("method = 'none' returns the data untouched", {
  result <- adjust_inherent(soil_inherent, adj_indicators, adj_inherent,
                            method = "none")

  expect_identical(result$data, soil_inherent)
  expect_identical(result$method, "none")
  expect_null(result$models)
  expect_true(all(is.na(result$r_squared)))
})

test_that("method = 'none' does not require the inherent formula", {
  expect_no_error(
    adjust_inherent(soil_inherent, adj_indicators, method = "none")
  )
})


# ---- validation -------------------------------------------------------------

test_that("adjust_inherent validates its input", {
  expect_error(adjust_inherent("a", "OM", adj_inherent), "must be a data frame")
  expect_error(adjust_inherent(soil_inherent, character(0), adj_inherent),
               "non-empty character")
  expect_error(adjust_inherent(soil_inherent, "NotAColumn", adj_inherent),
               "not found in data")
  expect_error(adjust_inherent(soil_inherent, "soil_type", adj_inherent),
               "not numeric")
  expect_error(adjust_inherent(soil_inherent, "OM", ~ not_a_factor),
               "Inherent factors not found")
  expect_error(adjust_inherent(soil_inherent, "OM", "soil_type"),
               "one-sided formula")
})

test_that("an indicator cannot be its own inherent factor", {
  expect_error(
    adjust_inherent(soil_inherent, c("OM", "Clay"), ~ soil_type + Clay),
    "both an indicator and an inherent factor"
  )
})


# ---- print ------------------------------------------------------------------

test_that("print reports what each indicator inherited", {
  result <- adjust_inherent(soil_inherent, adj_indicators, adj_inherent)
  out <- capture.output(print(result))

  expect_true(any(grepl("inheritance, not management", out)))
  for (v in adj_indicators) {
    expect_true(any(grepl(v, out, fixed = TRUE)), info = v)
  }
})

test_that("print says plainly when nothing was done", {
  result <- adjust_inherent(soil_inherent, adj_indicators, method = "none")
  out <- capture.output(print(result))

  expect_true(any(grepl("returned untouched", out)))
})


# ---- wiring into the pipeline -----------------------------------------------

test_that("compute_sqi_df does not adjust by default", {
  props <- c("SampleID", "OM", "CEC", "pH", "P", "N", "K", "BD")

  result <- compute_sqi_df(soil_inherent[, props], id_column = "SampleID")

  expect_null(result$adjustment)
})

test_that("compute_sqi_df adjusts before selection and scoring", {
  adjusted <- suppressWarnings(compute_sqi_df(
    soil_inherent[, c("SampleID", "soil_type", "land_use_history",
                      "OM", "CEC", "pH", "P", "N", "K", "BD")],
    id_column = "SampleID",
    inherent = ~ soil_type * land_use_history
  ))

  expect_s3_class(adjusted$adjustment, "inherent_adjustment")
  expect_false(anyNA(adjusted$results$SQI))

  # The adjustment must reach the index: an unadjusted run differs.
  plain <- compute_sqi_df(
    soil_inherent[, c("SampleID", "OM", "CEC", "pH", "P", "N", "K", "BD")],
    id_column = "SampleID"
  )

  expect_false(isTRUE(all.equal(adjusted$results$SQI, plain$results$SQI)))
})

test_that("the inherent factors are not adjusted as if they were indicators", {
  adjusted <- suppressWarnings(compute_sqi_df(
    soil_inherent[, c("SampleID", "soil_type", "land_use_history",
                      "OM", "CEC", "pH")],
    id_column = "SampleID",
    inherent = ~ soil_type * land_use_history
  ))

  expect_false(any(c("soil_type", "land_use_history") %in%
                     adjusted$adjustment$indicators))
})

test_that("an adjusted index carries less inherent signal", {
  # The point of the whole exercise, measured on the index rather than on a
  # single indicator: parent material should explain the adjusted index far
  # less than it explains the unadjusted one.
  cols <- c("SampleID", "soil_type", "land_use_history", "OM", "CEC", "pH",
            "P", "N", "K", "BD")

  plain <- compute_sqi_df(soil_inherent[, setdiff(cols, c("soil_type",
                                                          "land_use_history"))],
                          id_column = "SampleID")
  adjusted <- suppressWarnings(compute_sqi_df(
    soil_inherent[, cols], id_column = "SampleID",
    inherent = ~ soil_type * land_use_history
  ))

  r2_plain <- summary(
    stats::lm(plain$results$SQI ~ soil_inherent$soil_type)
  )$r.squared
  r2_adjusted <- summary(
    stats::lm(adjusted$results$SQI ~ soil_inherent$soil_type)
  )$r.squared

  expect_lt(r2_adjusted, r2_plain)
})

test_that("compute_sqi_df rejects a non-formula inherent argument", {
  expect_error(
    compute_sqi_df(soil_inherent[, c("SampleID", "OM", "CEC", "pH")],
                   id_column = "SampleID", inherent = "soil_type"),
    "one-sided formula"
  )
})

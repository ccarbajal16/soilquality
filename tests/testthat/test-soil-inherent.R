# Tests for the soil_inherent example dataset
#
# This dataset exists so that an inherent-property adjustment can be built,
# tested and demonstrated. The assertions therefore check the PROPERTIES that
# make it fit for that job, not just its shape -- a regenerated dataset that
# silently lost the separation between inherent and manageable variation would
# still look right and be useless.

inherent_factors <- c("soil_type", "land_use_history")

p_for <- function(response, predictor, data = soil_inherent) {
  fit <- stats::lm(stats::reformulate(predictor, response), data = data)
  stats::anova(fit)[["Pr(>F)"]][1]
}

adjusted <- function(indicator) {
  fit <- stats::lm(
    stats::reformulate("soil_type * land_use_history", indicator),
    data = soil_inherent
  )
  stats::residuals(fit) + mean(soil_inherent[[indicator]])
}


# ---- shape ------------------------------------------------------------------

test_that("soil_inherent has the documented shape", {
  expect_s3_class(soil_inherent, "data.frame")
  expect_equal(nrow(soil_inherent), 180)
  expect_equal(ncol(soil_inherent), 16)
  expect_false(anyNA(soil_inherent))

  expect_true(all(c("SampleID", "PlotID", "soil_type", "land_use_history",
                    "management") %in% names(soil_inherent)))
})

test_that("the design factors are factors with the documented levels", {
  expect_s3_class(soil_inherent$soil_type, "factor")
  expect_s3_class(soil_inherent$land_use_history, "factor")
  expect_s3_class(soil_inherent$management, "factor")

  expect_identical(levels(soil_inherent$soil_type),
                   c("Acrisol", "Cambisol", "Fluvisol"))
  expect_identical(levels(soil_inherent$land_use_history),
                   c("primary_forest", "secondary_forest", "long_pasture"))
  expect_identical(levels(soil_inherent$management),
                   c("conventional", "improved"))
})

test_that("the design is balanced and nested five samples per plot", {
  expect_equal(length(unique(soil_inherent$PlotID)), 36)
  expect_true(all(table(soil_inherent$PlotID) == 5))

  # Every soil type x history x management cell is present.
  cells <- table(soil_inherent$soil_type, soil_inherent$land_use_history,
                 soil_inherent$management)
  expect_true(all(cells > 0))
})

test_that("a plot has exactly one level of each design factor", {
  # A plot that straddled two soil types would make the nesting meaningless.
  for (f in c("soil_type", "land_use_history", "management")) {
    per_plot <- tapply(as.character(soil_inherent[[f]]),
                       soil_inherent$PlotID,
                       function(v) length(unique(v)))
    expect_true(all(per_plot == 1), info = f)
  }
})

test_that("texture is compositional and values stay plausible", {
  total <- soil_inherent$Sand + soil_inherent$Silt + soil_inherent$Clay
  expect_true(all(abs(total - 100) < 1e-8))

  expect_true(all(soil_inherent$pH >= 3.5 & soil_inherent$pH <= 8))
  expect_true(all(soil_inherent$BD >= 0.9 & soil_inherent$BD <= 1.9))
  expect_true(all(soil_inherent$OM > 0))
  expect_true(all(soil_inherent$CEC > 0))
})


# ---- the inherent effect is really there ------------------------------------

test_that("parent material drives clay, exchange capacity and reaction", {
  for (v in c("Clay", "CEC", "pH")) {
    expect_lt(p_for(v, "soil_type"), 1e-20, label = v)
  }
})

test_that("land-use history drives the carbon baseline", {
  expect_lt(p_for("OM", "land_use_history"), 1e-10)
  expect_lt(p_for("SOC", "land_use_history"), 1e-10)
})


# ---- the manageable effect is really there ----------------------------------

test_that("current management moves organic matter, phosphorus and density", {
  for (v in c("OM", "P", "BD")) {
    expect_lt(p_for(v, "management"), 0.01, label = v)
  }
})

test_that("management does not masquerade as parent material", {
  # OM is generated from history and management, not soil type. If soil type
  # explained it, the separation the dataset exists for would be broken.
  expect_gt(p_for("OM", "soil_type"), 0.05)
})


# ---- the two-sided property the dataset exists for --------------------------

test_that("adjusting for inherent factors removes the soil-type effect", {
  for (v in c("CEC", "pH", "Clay")) {
    expect_lt(p_for(v, "soil_type"), 1e-20, label = paste(v, "before"))
    expect_gt(
      stats::anova(stats::lm(adjusted(v) ~ soil_inherent$soil_type))[["Pr(>F)"]][1],
      0.99,
      label = paste(v, "after")
    )
  }
})

test_that("adjusting SHARPENS the management signal rather than erasing it", {
  # The whole argument for doing this. An adjustment that removed both
  # effects would be useless; here the inherent variation was masking the
  # management difference, and taking it out makes the signal stronger.
  for (v in c("OM", "CEC")) {
    before <- p_for(v, "management")
    after <- stats::anova(
      stats::lm(adjusted(v) ~ soil_inherent$management)
    )[["Pr(>F)"]][1]

    expect_lt(after, before, label = v)
    expect_lt(after, 0.001, label = paste(v, "after"))
  }
})

test_that("the inherent model separates inherited from managed indicators", {
  r2 <- function(v) {
    summary(stats::lm(
      stats::reformulate("soil_type * land_use_history", v),
      data = soil_inherent
    ))$r.squared
  }

  # Mostly inheritance.
  expect_gt(r2("Clay"), 0.8)
  expect_gt(r2("pH"), 0.8)
  expect_gt(r2("CEC"), 0.8)

  # Mostly management, and therefore little to adjust away.
  expect_lt(r2("P"), 0.5)
  expect_lt(r2("BD"), 0.5)
})


# ---- the nesting is real ----------------------------------------------------

test_that("intraclass correlation is high, as Maaz found in the field", {
  # Maaz et al. (2023) reported ICC above 0.75 for every indicator: samples
  # within a plot are not independent, which invalidates ordinary standard
  # errors. The dataset reproduces that on purpose.
  icc <- function(v) {
    a <- stats::anova(stats::lm(
      stats::reformulate("PlotID", v), data = soil_inherent
    ))
    ms_between <- a[["Mean Sq"]][1]
    ms_within <- a[["Mean Sq"]][2]
    var_between <- max((ms_between - ms_within) / 5, 0)
    var_between / (var_between + ms_within)
  }

  for (v in c("Clay", "CEC", "pH", "OM", "P")) {
    expect_gt(icc(v), 0.75, label = v)
  }
})


# ---- it still works with the rest of the package ----------------------------

test_that("the numeric indicators feed the existing pipeline", {
  props <- c("pH", "OM", "N", "P", "K", "CEC", "BD")

  result <- compute_sqi_properties(soil_inherent, properties = props,
                                   id_column = "SampleID")

  expect_s3_class(result, "sqi_result")
  expect_length(result$results$SQI, nrow(soil_inherent))
  expect_false(anyNA(result$results$SQI))
})

test_that("the design factors do not leak into indicator selection", {
  # They are factors, so the numeric-column detection must skip them. A
  # soil_type that reached the MDS would be a real bug.
  result <- compute_sqi_properties(soil_inherent, id_column = "SampleID")

  expect_false(any(c("soil_type", "land_use_history", "management", "PlotID")
                   %in% result$mds))
})

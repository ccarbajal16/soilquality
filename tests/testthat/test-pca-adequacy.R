# Tests for PCA adequacy testing (KMO and Bartlett)

adequacy_props <- c("pH", "OM", "N", "P", "K", "CEC", "BD")


test_that("pca_adequacy returns the documented shape", {
  result <- pca_adequacy(soil_structured[, adequacy_props])

  expect_s3_class(result, "pca_adequacy")
  for (nm in c("kmo", "msa", "kmo_interpretation", "bartlett", "n", "p")) {
    expect_true(nm %in% names(result), info = nm)
  }

  expect_equal(result$n, nrow(soil_structured))
  expect_equal(result$p, length(adequacy_props))
})

test_that("KMO lies in [0,1] and carries a per-variable measure", {
  result <- pca_adequacy(soil_structured[, adequacy_props])

  expect_gte(result$kmo, 0)
  expect_lte(result$kmo, 1)

  expect_length(result$msa, length(adequacy_props))
  expect_setequal(names(result$msa), adequacy_props)
  expect_true(all(result$msa >= 0 & result$msa <= 1))
})

test_that("Bartlett rejects sphericity on structured data", {
  result <- pca_adequacy(soil_structured[, adequacy_props])

  expect_gt(result$bartlett$statistic, 0)
  expect_equal(result$bartlett$df,
               length(adequacy_props) * (length(adequacy_props) - 1) / 2)
  expect_lt(result$bartlett$p_value, 0.001)
})

test_that("Bartlett does not reject on uncorrelated data", {
  # If the indicators are mutually uncorrelated there is nothing to factor,
  # and that is exactly what the test should say.
  set.seed(11)
  noise <- as.data.frame(matrix(rnorm(200 * 5), ncol = 5))

  result <- pca_adequacy(noise)

  expect_gt(result$bartlett$p_value, 0.05)
})

test_that("the Bartlett statistic matches the formula computed by hand", {
  x <- as.matrix(soil_structured[, adequacy_props])
  n <- nrow(x)
  p <- ncol(x)
  R <- cor(x)

  expected <- -(n - 1 - (2 * p + 5) / 6) * log(det(R))

  expect_equal(pca_adequacy(x)$bartlett$statistic, expected,
               tolerance = 1e-10)
})

test_that("KMO matches the anti-image formula computed by hand", {
  x <- as.matrix(soil_structured[, adequacy_props])
  R <- cor(x)
  R_inv <- solve(R)

  d <- sqrt(diag(R_inv))
  partial <- -R_inv / outer(d, d)
  diag(partial) <- 0
  R_off <- R
  diag(R_off) <- 0

  expected <- sum(R_off^2) / (sum(R_off^2) + sum(partial^2))

  expect_equal(pca_adequacy(x)$kmo, expected, tolerance = 1e-10)
})

test_that("Kaiser's labels map to the right bands", {
  result <- pca_adequacy(soil_structured[, adequacy_props])

  expect_type(result$kmo_interpretation, "character")

  labels <- vapply(c(0.4, 0.55, 0.65, 0.75, 0.85, 0.95),
                   soilquality:::.kmo_label, character(1))
  expect_identical(
    labels,
    c("unacceptable", "miserable", "mediocre", "middling", "meritorious",
      "marvellous")
  )
})


# ---- singular matrices ------------------------------------------------------

test_that("compositional texture makes KMO undefined, and it says so", {
  # Sand + Silt + Clay = 100 exactly, so the correlation matrix is singular.
  # This is a property of compositional data, not a bug.
  result <- pca_adequacy(
    soil_structured[, c("Sand", "Silt", "Clay", "pH", "OM")]
  )

  expect_true(is.na(result$kmo))
  expect_match(result$kmo_message, "singular")
  expect_match(result$kmo_message, "collinear")
})

test_that("a singular matrix does not error and still reports what it can", {
  result <- pca_adequacy(
    soil_structured[, c("Sand", "Silt", "Clay", "pH", "OM")]
  )

  expect_s3_class(result, "pca_adequacy")
  expect_equal(result$p, 5)
  expect_equal(result$bartlett$df, 10)
})

test_that("near-duplicate indicators are named in the message", {
  # OM and SOC correlate at 0.99 by construction.
  result <- pca_adequacy(
    soil_structured[, c("Sand", "Silt", "Clay", "OM", "SOC")]
  )

  expect_match(result$kmo_message, "OM/SOC")
})


# ---- validation -------------------------------------------------------------

test_that("pca_adequacy validates its input", {
  expect_error(pca_adequacy("a"), "data frame or matrix")
  expect_error(pca_adequacy(data.frame(a = letters[1:5])),
               "at least one numeric column")
  expect_error(pca_adequacy(data.frame(a = 1:5)), "At least 2 numeric")
  expect_error(pca_adequacy(data.frame(a = 1:2, b = 3:4)),
               "At least 3 complete observations")
})

test_that("print.pca_adequacy reports both statistics", {
  out <- capture.output(print(pca_adequacy(soil_structured[, adequacy_props])))

  expect_true(any(grepl("Kaiser-Meyer-Olkin", out)))
  expect_true(any(grepl("Bartlett", out)))
})

test_that("print.pca_adequacy explains an uncomputable KMO", {
  result <- pca_adequacy(
    soil_structured[, c("Sand", "Silt", "Clay", "pH", "OM")]
  )
  out <- capture.output(print(result))

  expect_true(any(grepl("not computable", out)))
})


# ---- wiring into pca_select_mds ---------------------------------------------

test_that("pca_select_mds reports adequacy by default", {
  result <- pca_select_mds(standardize_numeric(
    soil_structured[, adequacy_props]
  ))

  expect_s3_class(result$adequacy, "pca_adequacy")
})

test_that("adequacy = 'ignore' skips the computation", {
  result <- pca_select_mds(
    standardize_numeric(soil_structured[, adequacy_props]),
    adequacy = "ignore"
  )

  expect_null(result$adequacy)
})

test_that("adequacy reporting does not change the selection", {
  d <- standardize_numeric(soil_structured[, adequacy_props])

  expect_identical(
    pca_select_mds(d, adequacy = "report")$mds,
    pca_select_mds(d, adequacy = "ignore")$mds
  )
})

test_that("adequacy = 'warn' fires on data with nothing to factor", {
  set.seed(12)
  noise <- as.data.frame(matrix(rnorm(200 * 5), ncol = 5))
  names(noise) <- paste0("V", 1:5)
  std_noise <- standardize_numeric(noise)

  # Both checks fail on pure noise, and each raises its own warning.
  # expect_warning() consumes only the first, so they are asserted separately.
  warnings_raised <- character(0)
  withCallingHandlers(
    pca_select_mds(std_noise, adequacy = "warn"),
    warning = function(w) {
      warnings_raised <<- c(warnings_raised, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )

  expect_true(any(grepl("KMO", warnings_raised)))
  expect_true(any(grepl("sphericity", warnings_raised)))
})

test_that("adequacy = 'warn' stays quiet on structured data", {
  expect_no_warning(
    pca_select_mds(standardize_numeric(soil_structured[, adequacy_props]),
                   adequacy = "warn")
  )
})

test_that("a singular matrix does not break pca_select_mds", {
  # The default route must survive compositional data, since texture fractions
  # are a standard part of a soil data set.
  d <- standardize_numeric(soil_structured[, c("Sand", "Silt", "Clay", "pH",
                                               "OM", "N")])

  result <- pca_select_mds(d)

  expect_type(result$mds, "character")
  expect_true(is.na(result$adequacy$kmo))
})

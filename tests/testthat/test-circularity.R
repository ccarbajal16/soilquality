# Tests for the circularity guard
#
# Most assertions use an explicit component list rather than whatever PCA
# happens to select, so they do not move when the selection does. The
# sqi_result path is exercised separately, and deliberately reads $mds rather
# than assuming its contents.

circ_props <- c("pH", "OM", "N", "P", "K", "CEC", "BD")

circ_index <- function() {
  compute_sqi_properties(soil_structured, properties = circ_props,
                         id_column = "SampleID")
}

built_from <- c("OM", "N", "CEC")


# ---- the core refusal -------------------------------------------------------

test_that("predictors outside the index pass", {
  result <- check_circularity(built_from, ~ Sand + Clay)

  expect_s3_class(result, "sqi_circularity")
  expect_false(result$circular)
  expect_identical(result$mode, "explanation")
  expect_length(result$shared, 0)
})

test_that("a predictor that is an index component is refused", {
  expect_error(check_circularity(built_from, ~ OM + Sand),
               "Circular model refused")
  expect_error(check_circularity(built_from, ~ OM + Sand), "ARE components")
  expect_error(check_circularity(built_from, ~ OM + Sand), "OM")
})

test_that("the refusal explains why, not just that", {
  msg <- tryCatch(check_circularity(built_from, ~ OM),
                  error = conditionMessage)

  expect_match(msg, "weighted sum of its components")
  expect_match(msg, "arithmetic, not evidence")
  expect_match(msg, "allow_components = TRUE")
})

test_that("allow_components permits it and labels it a decomposition", {
  result <- check_circularity(built_from, ~ OM + Sand,
                              allow_components = TRUE)

  expect_true(result$circular)
  expect_identical(result$mode, "decomposition")
  expect_setequal(result$shared, "OM")
})

test_that("every shared predictor is named, not just the first", {
  result <- check_circularity(built_from, ~ OM + N + CEC + Sand,
                              allow_components = TRUE)

  expect_setequal(result$shared, c("OM", "N", "CEC"))
})


# ---- renaming is not laundering ---------------------------------------------

test_that("a renamed component is caught by correlation", {
  # SOC is OM divided by 1.724, so they correlate at 0.99 in soil_structured.
  # Name matching alone would wave this straight through.
  expect_error(
    check_circularity(built_from, ~ SOC, data = soil_structured),
    "under another name"
  )
})

test_that("the proxy report names every component a predictor stands in for", {
  result <- check_circularity(built_from, ~ SOC, data = soil_structured,
                              allow_components = TRUE)

  # SOC proxies for TWO of these components, not one: it is OM / 1.724, and it
  # tracks N through the C:N ratio at rho 0.96. Reporting only the first would
  # understate how entangled the predictor is.
  expect_equal(nrow(result$proxies), 2)
  expect_true(all(result$proxies$predictor == "SOC"))
  expect_setequal(result$proxies$component, c("OM", "N"))
  expect_true(all(abs(result$proxies$correlation) > 0.9))
})

test_that("without data, a renamed component slips through", {
  # Documented behaviour, asserted so the limitation stays explicit: the check
  # is name-only unless `data` is supplied.
  result <- check_circularity(built_from, ~ SOC)

  expect_false(result$circular)
  expect_false(result$checked_numerically)
})

test_that("r_max controls how strict the proxy detection is", {
  lenient <- check_circularity(built_from, ~ SOC, data = soil_structured,
                               r_max = 0.999)
  expect_false(lenient$circular)

  strict <- check_circularity(built_from, ~ SOC, data = soil_structured,
                              r_max = 0.5, allow_components = TRUE)
  expect_true(strict$circular)
})

test_that("an unrelated predictor is not flagged as a proxy", {
  result <- check_circularity(built_from, ~ Sand, data = soil_structured)

  expect_false(result$circular)
  expect_equal(nrow(result$proxies), 0)
})


# ---- input handling ---------------------------------------------------------

test_that("the index side accepts an sqi_result or a character vector", {
  index <- circ_index()

  from_object <- check_circularity(index, ~ Sand)
  from_names <- check_circularity(index$mds, ~ Sand)

  expect_identical(from_object$components, from_names$components)
  expect_identical(from_object$components, index$mds)
})

test_that("an sqi_result's own components are refused as predictors", {
  # Reads $mds rather than assuming what PCA picked.
  index <- circ_index()

  expect_error(
    check_circularity(index, index$mds[1]),
    "Circular model refused"
  )
})

test_that("predictors accept a formula, a character vector or a data frame", {
  by_formula <- check_circularity(built_from, ~ Sand + Clay)
  by_vector <- check_circularity(built_from, c("Sand", "Clay"))
  by_frame <- check_circularity(built_from, soil_structured[, c("Sand", "Clay")])

  expect_identical(by_formula$predictors, by_vector$predictors)
  expect_identical(by_formula$predictors, by_frame$predictors)
})

test_that("check_circularity validates its input", {
  expect_error(check_circularity(42, ~ Sand), "must be an sqi_result object")
  expect_error(check_circularity(built_from, 42), "must be a character vector")
  expect_error(check_circularity(built_from, ~ Sand, r_max = 1.5),
               "r_max must be")
  expect_error(check_circularity(built_from, ~ Sand, data = "a"),
               "data must be a data frame")
})

test_that("a data frame missing the columns does not error", {
  # The numeric check is best-effort: absent columns are skipped, not fatal.
  result <- check_circularity(built_from, ~ Sand,
                              data = soil_structured[, c("Sand", "Clay")])

  expect_false(result$circular)
})


# ---- print ------------------------------------------------------------------

test_that("print reports a clean check plainly", {
  out <- capture.output(print(check_circularity(built_from, ~ Sand)))

  expect_true(any(grepl("No overlap", out)))
})

test_that("print refuses to let a decomposition be read as a fit", {
  result <- check_circularity(built_from, ~ OM, allow_components = TRUE)
  out <- capture.output(print(result))

  expect_true(any(grepl("DECOMPOSITION", out)))
  expect_true(any(grepl("DO NOT REPORT THE R-SQUARED", out)))
})

test_that("print says when the check was names-only", {
  out <- capture.output(print(check_circularity(built_from, ~ Sand)))

  expect_true(any(grepl("names only", out)))
})


# ---- the same trap inside sqi_validate() ------------------------------------

test_that("an external criterion that is an index component warns", {
  index <- circ_index()
  component <- index$mds[1]

  expect_warning(
    sqi_validate(index, external = soil_structured[[component]],
                 middle_band_threshold = NA),
    "nearly identical to an indicator"
  )
})

test_that("a genuinely external criterion does not warn", {
  index <- circ_index()

  set.seed(5)
  yield <- rnorm(nrow(soil_structured))

  expect_no_warning(
    sqi_validate(index, external = yield, middle_band_threshold = NA)
  )
})

test_that("the external check names the offending indicator and its rho", {
  index <- circ_index()
  component <- index$mds[1]

  msg <- tryCatch(
    sqi_validate(index, external = soil_structured[[component]],
                 middle_band_threshold = NA),
    warning = conditionMessage
  )

  expect_match(msg, component)
  expect_match(msg, "rho =")
  expect_match(msg, "arithmetic, not agreement")
})

test_that("external_r_max = NA disables the check", {
  index <- circ_index()
  component <- index$mds[1]

  expect_no_warning(
    sqi_validate(index, external = soil_structured[[component]],
                 external_r_max = NA, middle_band_threshold = NA)
  )
})

test_that("the external check still produces the correlation it was asked for", {
  index <- circ_index()

  result <- suppressWarnings(
    sqi_validate(index, external = soil_structured[[index$mds[1]]],
                 middle_band_threshold = NA)
  )

  expect_false(is.null(result$external))
  expect_equal(result$external$n, nrow(soil_structured))
})

test_that("a bare numeric index skips the external check without erroring", {
  # Nothing to compare against when there is no sqi_result behind it.
  set.seed(6)
  sqi <- runif(30, 0.2, 0.9)

  expect_no_warning(
    sqi_validate(sqi, external = rnorm(30), middle_band_threshold = NA)
  )
})

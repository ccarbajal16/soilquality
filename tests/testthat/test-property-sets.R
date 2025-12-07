# Tests for property sets and standard scoring rules

test_that("soil_property_sets contains all expected sets", {
  # Check that all expected property sets exist
  expected_sets <- c("basic", "standard", "comprehensive",
                     "physical", "chemical", "fertility")

  expect_true(all(expected_sets %in% names(soil_property_sets)))
})

test_that("soil_property_sets basic set has correct properties", {
  basic <- soil_property_sets$basic

  # Check length
  expect_equal(length(basic), 4)

  # Check expected properties
  expect_true(all(c("pH", "OM", "P", "K") %in% basic))
})

test_that("soil_property_sets standard set has correct properties", {
  standard <- soil_property_sets$standard

  # Check length
  expect_equal(length(standard), 9)

  # Check expected properties
  expected <- c("Sand", "Silt", "Clay", "pH", "OM", "N", "P", "K", "CEC")
  expect_true(all(expected %in% standard))
})

test_that("soil_property_sets comprehensive set has correct properties", {
  comprehensive <- soil_property_sets$comprehensive

  # Check length
  expect_equal(length(comprehensive), 15)

  # Check that it includes all standard properties plus extras
  standard <- soil_property_sets$standard
  expect_true(all(standard %in% comprehensive))

  # Check for additional properties
  extras <- c("BD", "EC", "Ca", "Mg", "Na", "S")
  expect_true(all(extras %in% comprehensive))
})

test_that("soil_property_sets physical set has correct properties", {
  physical <- soil_property_sets$physical

  # Check length
  expect_equal(length(physical), 4)

  # Check expected properties
  expected <- c("Sand", "Silt", "Clay", "BD")
  expect_true(all(expected %in% physical))
})

test_that("soil_property_sets chemical set has correct properties", {
  chemical <- soil_property_sets$chemical

  # Check length
  expect_equal(length(chemical), 7)

  # Check expected properties
  expected <- c("pH", "EC", "CEC", "Ca", "Mg", "K", "Na")
  expect_true(all(expected %in% chemical))
})

test_that("soil_property_sets fertility set has correct properties", {
  fertility <- soil_property_sets$fertility

  # Check length
  expect_equal(length(fertility), 8)

  # Check expected properties
  expected <- c("OM", "N", "P", "K", "Ca", "Mg", "S", "CEC")
  expect_true(all(expected %in% fertility))
})

test_that("standard_scoring_rules accepts property set names", {
  # Test with basic set
  rules <- standard_scoring_rules("basic")

  # Check that rules were created for all properties
  expect_equal(length(rules), 4)
  expect_equal(names(rules), soil_property_sets$basic)

  # Check that all rules are scoring_rule objects
  expect_true(all(sapply(rules, inherits, "scoring_rule")))
})

test_that("standard_scoring_rules accepts custom property vectors", {
  custom_props <- c("pH", "BD", "OM", "CustomProp")
  rules <- standard_scoring_rules(custom_props)

  # Check that rules were created for all properties
  expect_equal(length(rules), 4)
  expect_equal(names(rules), custom_props)

  # Check that all rules are scoring_rule objects
  expect_true(all(sapply(rules, inherits, "scoring_rule")))
})

test_that("standard_scoring_rules assigns optimum_range for pH", {
  rules <- standard_scoring_rules(c("pH", "pH_water", "soil_pH"))

  # Check that pH gets optimum_range rule
  expect_s3_class(rules$pH, "optimum_range")
  expect_equal(rules$pH$optimum, 7)
  expect_equal(rules$pH$tol, 1)

  # Check case-insensitive matching
  expect_s3_class(rules$pH_water, "optimum_range")
  expect_s3_class(rules$soil_pH, "optimum_range")
})

test_that("standard_scoring_rules assigns lower_better for EC", {
  rules <- standard_scoring_rules(c("EC", "electrical_conductivity", "EC_dS"))

  # Check that EC gets lower_better rule
  expect_s3_class(rules$EC, "lower_better")
  expect_s3_class(rules$electrical_conductivity, "lower_better")
  expect_s3_class(rules$EC_dS, "lower_better")
})

test_that("standard_scoring_rules assigns lower_better for BD", {
  rules <- standard_scoring_rules(c("BD", "bulk_density", "BD_gcm3"))

  # Check that BD gets lower_better rule
  expect_s3_class(rules$BD, "lower_better")
  expect_s3_class(rules$bulk_density, "lower_better")
  expect_s3_class(rules$BD_gcm3, "lower_better")
})

test_that("standard_scoring_rules assigns higher_better for OM", {
  rules <- standard_scoring_rules(c("OM", "SOC", "organic_matter", "organic_carbon"))

  # Check that organic matter properties get higher_better rule
  expect_s3_class(rules$OM, "higher_better")
  expect_s3_class(rules$SOC, "higher_better")
  expect_s3_class(rules$organic_matter, "higher_better")
  expect_s3_class(rules$organic_carbon, "higher_better")
})

test_that("standard_scoring_rules assigns higher_better for nutrients", {
  rules <- standard_scoring_rules(c("N", "nitrogen", "total_N",
                                    "P", "phosphorus", "available_P",
                                    "K", "potassium", "exchangeable_K"))

  # Check that nutrient properties get higher_better rule
  expect_s3_class(rules$N, "higher_better")
  expect_s3_class(rules$nitrogen, "higher_better")
  expect_s3_class(rules$total_N, "higher_better")

  expect_s3_class(rules$P, "higher_better")
  expect_s3_class(rules$phosphorus, "higher_better")
  expect_s3_class(rules$available_P, "higher_better")

  expect_s3_class(rules$K, "higher_better")
  expect_s3_class(rules$potassium, "higher_better")
  expect_s3_class(rules$exchangeable_K, "higher_better")
})

test_that("standard_scoring_rules assigns higher_better for CEC and cations", {
  rules <- standard_scoring_rules(c("CEC", "Ca", "calcium",
                                    "Mg", "magnesium"))

  # Check that CEC and cation properties get higher_better rule
  expect_s3_class(rules$CEC, "higher_better")
  expect_s3_class(rules$Ca, "higher_better")
  expect_s3_class(rules$calcium, "higher_better")
  expect_s3_class(rules$Mg, "higher_better")
  expect_s3_class(rules$magnesium, "higher_better")
})

test_that("standard_scoring_rules assigns higher_better as default", {
  rules <- standard_scoring_rules(c("Sand", "Silt", "Clay", "CustomProperty"))

  # Check that unmatched properties get higher_better rule (default)
  expect_s3_class(rules$Sand, "higher_better")
  expect_s3_class(rules$Silt, "higher_better")
  expect_s3_class(rules$Clay, "higher_better")
  expect_s3_class(rules$CustomProperty, "higher_better")
})

test_that("standard_scoring_rules is case-insensitive", {
  rules <- standard_scoring_rules(c("ph", "PH", "Ph", "bd", "BD", "Bd"))

  # Check that all variations are recognized
  expect_s3_class(rules$ph, "optimum_range")
  expect_s3_class(rules$PH, "optimum_range")
  expect_s3_class(rules$Ph, "optimum_range")

  expect_s3_class(rules$bd, "lower_better")
  expect_s3_class(rules$BD, "lower_better")
  expect_s3_class(rules$Bd, "lower_better")
})

test_that("standard_scoring_rules works with all pre-defined property sets", {
  # Test each property set
  for (set_name in names(soil_property_sets)) {
    rules <- standard_scoring_rules(set_name)

    # Check that rules were created for all properties in the set
    expect_equal(length(rules), length(soil_property_sets[[set_name]]))
    expect_equal(names(rules), soil_property_sets[[set_name]])

    # Check that all rules are scoring_rule objects
    expect_true(all(sapply(rules, inherits, "scoring_rule")))
  }
})

test_that("standard_scoring_rules validates input", {
  # Empty vector
  expect_error(standard_scoring_rules(character(0)),
               "properties must be a character vector or a property set name")

  # Non-character input
  expect_error(standard_scoring_rules(123),
               "properties must be a character vector or a property set name")

  # NULL input
  expect_error(standard_scoring_rules(NULL),
               "properties must be a character vector or a property set name")
})

test_that("standard_scoring_rules handles edge cases in pattern matching", {
  # Properties that might cause false matches
  rules <- standard_scoring_rules(c("Phosphate", "Potash", "Capacity",
                                    "Organic", "Nitrogen_total"))

  # Check that partial matches work correctly
  expect_s3_class(rules$Phosphate, "higher_better")  # Contains "phosph"
  expect_s3_class(rules$Potash, "higher_better")     # Contains "potass"
  expect_s3_class(rules$Capacity, "higher_better")   # Default (not CEC)
  expect_s3_class(rules$Organic, "higher_better")    # Contains "organic"
  expect_s3_class(rules$Nitrogen_total, "higher_better")  # Contains "nitrogen"
})

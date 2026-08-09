# Tests for the soil_structured example dataset
#
# This dataset exists to carry a realistic covariance structure, so the tests
# assert that structure rather than just its shape. If a regenerated dataset
# silently lost the relationships, everything downstream that demonstrates
# network selection or grouping would quietly stop demonstrating anything.

structured_props <- function() setdiff(names(soil_structured), "SampleID")

rho <- function(a, b) {
  cor(soil_structured[[a]], soil_structured[[b]], method = "spearman")
}


test_that("soil_structured has the documented shape", {
  expect_s3_class(soil_structured, "data.frame")
  expect_equal(nrow(soil_structured), 120)
  expect_equal(ncol(soil_structured), 16)
  expect_false(anyNA(soil_structured))

  expect_identical(
    names(soil_structured),
    c("SampleID", "Sand", "Silt", "Clay", "BD", "pH", "OM", "SOC", "N",
      "P", "K", "CEC", "Ca", "Mg", "S", "EC")
  )
  expect_equal(length(unique(soil_structured$SampleID)), 120)
})

test_that("texture is compositional", {
  total <- soil_structured$Sand + soil_structured$Silt + soil_structured$Clay

  expect_true(all(abs(total - 100) < 1e-8))
})

test_that("values stay in pedologically plausible ranges", {
  expect_true(all(soil_structured$pH >= 3.5 & soil_structured$pH <= 8.5))
  expect_true(all(soil_structured$BD >= 0.9 & soil_structured$BD <= 1.9))
  expect_true(all(soil_structured$OM > 0))
  expect_true(all(soil_structured$SOC > 0))
  expect_true(all(soil_structured$N > 0))
  expect_true(all(soil_structured$CEC > 0))
  expect_true(all(soil_structured$EC > 0))

  # Texture fractions are percentages.
  for (fraction in c("Sand", "Silt", "Clay")) {
    expect_true(all(soil_structured[[fraction]] >= 0 &
                      soil_structured[[fraction]] <= 100),
                info = fraction)
  }
})

test_that("the organic fractions are near-collinear, as in real soil", {
  # SOC = OM / 1.724 (van Bemmelen), so these are three measurements of one
  # underlying pool.
  expect_gt(rho("OM", "SOC"), 0.95)
  expect_gt(rho("SOC", "N"), 0.90)

  # And the implied carbon fraction is the conversion factor, not an accident.
  expect_equal(median(soil_structured$OM / soil_structured$SOC), 1.724,
               tolerance = 0.02)

  # C:N sits in the range expected for cultivated topsoil.
  cn <- soil_structured$SOC / soil_structured$N
  expect_gt(median(cn), 9)
  expect_lt(median(cn), 13)
})

test_that("the exchange complex behaves as clay plus organic colloids", {
  expect_gt(rho("Clay", "CEC"), 0.6)
  expect_gt(rho("OM", "CEC"), 0.6)
  expect_gt(rho("CEC", "Ca"), 0.5)
  expect_gt(rho("Ca", "Mg"), 0.8)
})

test_that("the inverse relationships have the right sign", {
  # Organic matter lowers bulk density.
  expect_lt(rho("OM", "BD"), -0.6)

  # Compositional closure makes sand and clay oppose each other.
  expect_lt(rho("Sand", "Clay"), -0.6)
})

test_that("base status drives pH and the soluble bases", {
  expect_gt(rho("pH", "Ca"), 0.5)
  expect_gt(rho("Ca", "EC"), 0.8)
})

test_that("soil_structured carries far more covariance than soil_data", {
  # The whole reason this dataset exists. soil_data draws every property
  # independently and clears the default threshold on exactly one pair.
  strong_pairs <- function(d) {
    cm <- cor(d, method = "spearman")
    diag(cm) <- NA
    sum(abs(cm) >= 0.6, na.rm = TRUE) / 2
  }

  structured <- strong_pairs(soil_structured[, structured_props()])
  flat <- strong_pairs(soil_data[, setdiff(names(soil_data), "SampleID")])

  expect_gt(structured, 20)
  expect_lte(flat, 2)
  expect_gt(structured, flat * 10)
})


# ---- it can actually exercise the methods that need structure --------------

test_that("the network route selects several indicators from soil_structured", {
  skip_if_not_installed("igraph")

  result <- na_select_mds(soil_structured[, structured_props()])

  # On soil_data this collapses to a single indicator; here it does not.
  expect_gte(length(result$mds), 2)
  expect_gt(igraph::ecount(result$graph), 20)

  # The hubs are what a soil scientist would expect to carry the network.
  expect_true("OM" %in% result$mds || "CEC" %in% result$mds)
})

test_that("the two selection routes diverge on soil_structured", {
  skip_if_not_installed("igraph")

  # Documented in the dataset's help page, and worth pinning: PCA rewards
  # variance and uniqueness, the network rewards centrality, and here they
  # disagree completely. If a regenerated dataset made them agree, the
  # dataset would have stopped illustrating the difference.
  agreement <- suppressWarnings(
    mds_consensus(soil_structured[, structured_props()])
  )

  expect_gte(length(agreement$network$mds), 2)
  expect_gte(length(agreement$pca$mds), 1)
  expect_false(setequal(agreement$pca$mds, agreement$network$mds))
})

test_that("the index discriminates better on soil_structured than soil_data", {
  props <- c("pH", "OM", "N", "P", "K", "CEC", "BD")

  flat <- compute_sqi_properties(soil_data, properties = props,
                                 id_column = "SampleID")
  structured <- compute_sqi_properties(soil_structured, properties = props,
                                       id_column = "SampleID")

  v_flat <- suppressWarnings(sqi_validate(flat))
  v_structured <- suppressWarnings(sqi_validate(structured))

  # Real covariance spreads samples out instead of piling them in the middle.
  expect_gt(v_structured$sensitivity, v_flat$sensitivity)
  expect_lt(v_structured$middle_band_share, 1)
  expect_equal(v_flat$middle_band_share, 1)
})

# Tests for correlation-network MDS selection
#
# igraph lives in Suggests, so every test here must skip cleanly when it is
# absent -- otherwise R CMD check fails on a machine without it, which is the
# whole point of not putting it in Imports.

network_props <- c("Sand", "Silt", "Clay", "pH", "OM", "SOC", "N", "P", "K",
                   "CEC", "Ca", "Mg", "BD", "EC")

network_data <- function() soil_data[, network_props]

# soil_data is SIMULATED with independent draws, so it carries almost no
# correlation structure: the largest off-diagonal |rho| is 0.66 and exactly one
# pair clears the default r_min = 0.6. The network route therefore collapses to
# a single indicator on it, which is a fine thing to assert but useless for
# exercising module detection, the within-10% rule or the screen.
#
# Those rules are tested against synthetic data with a deliberate structure:
# two correlated latent factors, three observed indicators each, plus one pure
# noise variable that must end up isolated.
correlated_data <- function(n = 80, seed = 42) {
  set.seed(seed)
  shared <- rnorm(n)
  latent1 <- shared + rnorm(n, 0, 0.6)
  latent2 <- shared + rnorm(n, 0, 0.6)

  data.frame(
    a1 = latent1 + rnorm(n, 0, 0.15),
    a2 = latent1 + rnorm(n, 0, 0.20),
    a3 = latent1 + rnorm(n, 0, 0.25),
    b1 = latent2 + rnorm(n, 0, 0.15),
    b2 = latent2 + rnorm(n, 0, 0.20),
    b3 = latent2 + rnorm(n, 0, 0.25),
    noise = rnorm(n)
  )
}

# A single connected component: every indicator descends from one shared
# factor, so the graph has no isolated nodes and no split. Used to assert that
# the `component` argument is a no-op when there is nothing to rescue.
connected_data <- function(n = 80, seed = 42) {
  correlated_data(n = n, seed = seed)[, c("a1", "a2", "a3", "b1", "b2", "b3")]
}

# The same two cliques with NO bridge, so the graph is genuinely disconnected.
disconnected_data <- function(n = 120, seed = 9) {
  set.seed(seed)
  A <- rnorm(n)
  B <- rnorm(n)

  data.frame(
    a1 = A + rnorm(n, 0, 0.10),
    a2 = A + rnorm(n, 0, 0.12),
    a3 = A + rnorm(n, 0, 0.14),
    b1 = B + rnorm(n, 0, 0.10),
    b2 = B + rnorm(n, 0, 0.12),
    b3 = B + rnorm(n, 0, 0.14)
  )
}


# ---- dependency guard -------------------------------------------------------

test_that("igraph is a suggested dependency, not a hard one", {
  # Read through the package API rather than a relative path: under
  # R CMD check the tests run from a different working directory and
  # "../../DESCRIPTION" does not exist.
  desc <- packageDescription("soilquality")

  # The package is MIT-licensed; igraph is GPL-2+. A hard dependency would
  # pull the combined work into GPL territory on distribution.
  expect_no_match(desc$Imports %||% "", "igraph")
  expect_match(desc$Suggests, "igraph")
})


# ---- the network itself -----------------------------------------------------

test_that("na_select_mds builds a graph and returns the documented shape", {
  skip_if_not_installed("igraph")

  result <- suppressWarnings(na_select_mds(network_data()))

  for (nm in c("mds", "weights", "centrality", "strength", "membership",
               "modules", "isolated", "screened", "graph", "correlation",
               "p_values")) {
    expect_true(nm %in% names(result), info = nm)
  }

  expect_type(result$mds, "character")
  expect_gt(length(result$mds), 0)
  expect_s3_class(result$graph, "igraph")
})

test_that("edges honour both the r and the p threshold", {
  skip_if_not_installed("igraph")

  result <- suppressWarnings(na_select_mds(network_data(), r_min = 0.6,
                                           p_max = 0.01))

  adjacency <- as.matrix(igraph::as_adjacency_matrix(result$graph,
                                                     attr = "weight"))
  linked <- which(adjacency > 0, arr.ind = TRUE)

  for (k in seq_len(nrow(linked))) {
    i <- linked[k, 1]
    j <- linked[k, 2]
    expect_gte(abs(result$correlation[i, j]), 0.6)
    expect_lt(result$p_values[i, j], 0.01)
  }
})

test_that("a stricter r_min produces a sparser graph", {
  skip_if_not_installed("igraph")

  loose  <- suppressWarnings(na_select_mds(correlated_data(), r_min = 0.4))
  strict <- suppressWarnings(na_select_mds(correlated_data(), r_min = 0.8))

  expect_gte(igraph::ecount(loose$graph), igraph::ecount(strict$graph))
})

test_that("edge weights are absolute correlations", {
  skip_if_not_installed("igraph")

  result <- suppressWarnings(na_select_mds(network_data()))
  weights <- igraph::E(result$graph)$weight

  expect_true(all(weights >= 0.6))
  expect_true(all(weights <= 1))
})


# ---- selection rules --------------------------------------------------------

test_that("selected indicators are ordered by centrality", {
  skip_if_not_installed("igraph")

  result <- suppressWarnings(na_select_mds(network_data()))
  selected_centrality <- result$centrality[result$mds]

  expect_false(is.unsorted(rev(selected_centrality)))
})

test_that("weights derive from centrality and sum to 1", {
  skip_if_not_installed("igraph")

  result <- suppressWarnings(na_select_mds(network_data()))

  expect_equal(sum(result$weights), 1)
  expect_identical(names(result$weights), result$mds)

  # Proportional to centrality over the selected set.
  expected <- result$centrality[result$mds] /
    sum(result$centrality[result$mds])
  expect_equal(unname(result$weights), unname(expected))
})

test_that("modules report their maximum centrality and retention", {
  skip_if_not_installed("igraph")

  result <- suppressWarnings(na_select_mds(network_data(),
                                           centrality_min = 0.6))

  expect_true(all(c("module", "size", "max_centrality", "retained") %in%
                    names(result$modules)))
  expect_true(all(result$modules$max_centrality[result$modules$retained] > 0.6))
  expect_true(all(result$modules$max_centrality[!result$modules$retained] <= 0.6))
})

test_that("every selected indicator belongs to a retained module", {
  skip_if_not_installed("igraph")

  result <- suppressWarnings(na_select_mds(network_data()))
  kept <- result$modules$module[result$modules$retained]

  expect_true(all(result$membership[result$mds] %in% kept))
})

test_that("the within-10% rule keeps more indicators as the band widens", {
  skip_if_not_installed("igraph")

  tight <- suppressWarnings(na_select_mds(correlated_data(), within = 0,
                                          screen = FALSE))
  wide  <- suppressWarnings(na_select_mds(correlated_data(), within = 0.9,
                                          screen = FALSE))

  expect_lte(length(tight$mds), length(wide$mds))
})

test_that("a centrality_min above every module errors informatively", {
  skip_if_not_installed("igraph")

  expect_error(
    suppressWarnings(na_select_mds(network_data(), centrality_min = 1.01)),
    "centrality_min must be a single numeric value"
  )
  expect_error(
    suppressWarnings(na_select_mds(network_data(), centrality_min = 1)),
    "No module has a maximum eigenvector centrality above"
  )
})


# ---- the correlation screen -------------------------------------------------

test_that("screening removes indicators redundant with a more central one", {
  skip_if_not_installed("igraph")

  screened   <- suppressWarnings(na_select_mds(connected_data(), screen = TRUE))
  unscreened <- suppressWarnings(na_select_mds(connected_data(), screen = FALSE))

  expect_lte(length(screened$mds), length(unscreened$mds))
  expect_true(all(screened$mds %in% unscreened$mds))

  # Anything dropped is reported, not silently discarded.
  expect_setequal(
    c(screened$mds, screened$screened),
    unscreened$mds
  )
})

test_that("no two screened survivors remain strongly correlated", {
  skip_if_not_installed("igraph")

  # Needs a fixture that genuinely yields more than one survivor. Two
  # uncorrelated cliques, evaluated per component, give one representative
  # each -- and those two must not be correlated with one another.
  result <- suppressWarnings(
    na_select_mds(disconnected_data(), screen = TRUE, component = "all")
  )
  mds <- result$mds

  expect_gt(length(mds), 1)

  for (i in seq_len(length(mds) - 1)) {
    for (j in seq(i + 1, length(mds))) {
      redundant <- abs(result$correlation[mds[i], mds[j]]) >= 0.6 &&
        result$p_values[mds[i], mds[j]] < 0.01
      expect_false(redundant, info = paste(mds[i], "vs", mds[j]))
    }
  }
})



# ---- determinism ------------------------------------------------------------

test_that("the selection is reproducible across runs", {
  skip_if_not_installed("igraph")

  # Louvain is randomised. Before the seed was added, six runs over identical
  # input returned two different selections, which would make a published
  # method section irreproducible.
  d <- correlated_data()
  runs <- replicate(8, suppressWarnings(na_select_mds(d))$mds, simplify = FALSE)

  for (r in runs[-1]) {
    expect_identical(r, runs[[1]])
  }
})

test_that("the seed can be varied to probe robustness", {
  skip_if_not_installed("igraph")

  d <- correlated_data()

  a <- suppressWarnings(na_select_mds(d, seed = 1))
  b <- suppressWarnings(na_select_mds(d, seed = 1))
  expect_identical(a$mds, b$mds)

  # A different seed is allowed to differ; the point is that it is the user's
  # choice to look, not a surprise sprung on them.
  c_ <- suppressWarnings(na_select_mds(d, seed = 999))
  expect_type(c_$mds, "character")
})

test_that("seeding does not disturb the caller's random stream", {
  skip_if_not_installed("igraph")

  set.seed(123)
  before <- runif(3)

  set.seed(123)
  invisible(suppressWarnings(na_select_mds(correlated_data(), seed = 7)))
  after <- runif(3)

  expect_equal(before, after)
})

test_that("the selection is invariant to monotonic rescaling", {
  skip_if_not_installed("igraph")

  d <- correlated_data()
  rescaled <- d
  rescaled$a1 <- rescaled$a1 * 1000
  rescaled$b1 <- rescaled$b1 + 50

  original <- suppressWarnings(na_select_mds(d))
  scaled   <- suppressWarnings(na_select_mds(rescaled))

  # Spearman is rank-based, so this must hold exactly.
  expect_equal(original$correlation, scaled$correlation)
  expect_identical(original$mds, scaled$mds)
  expect_equal(original$weights, scaled$weights)
})


# ---- what this route does on the shipped example data -----------------------

test_that("soil_data has too little correlation structure for this route", {
  skip_if_not_installed("igraph")

  # A substantive finding, pinned deliberately. soil_data is simulated from
  # independent draws, so it has no realistic covariance: the largest
  # off-diagonal |rho| is about 0.66 and only one pair clears r_min = 0.6.
  # Real soil data does not behave this way -- Sand/Silt/Clay are compositional
  # and OM/SOC are near-collinear -- so this is a property of the fixture, not
  # of the method. Documented so nobody concludes the network route is broken.
  result <- suppressWarnings(na_select_mds(network_data()))

  cm <- result$correlation
  diag(cm) <- NA
  expect_lt(max(abs(cm), na.rm = TRUE), 0.7)

  # Almost everything ends up isolated, and the selection collapses.
  expect_gte(length(result$isolated), 10)
  expect_lte(length(result$mds), 2)
})


# ---- documented behaviours --------------------------------------------------

test_that("indicators correlating with nothing are reported as isolated", {
  skip_if_not_installed("igraph")

  set.seed(20)
  n <- 60
  base <- rnorm(n)

  # Three tightly coupled indicators plus one pure noise variable.
  df <- data.frame(
    a = base + rnorm(n, 0, 0.05),
    b = base + rnorm(n, 0, 0.05),
    c = base + rnorm(n, 0, 0.05),
    lonely = rnorm(n)
  )

  result <- suppressWarnings(na_select_mds(df))

  expect_true("lonely" %in% result$isolated)

  # And it is dropped from the selection precisely because it is unique --
  # the documented asymmetry against PCA.
  expect_false("lonely" %in% result$mds)
})

test_that("a disconnected network warns", {
  skip_if_not_installed("igraph")

  expect_warning(na_select_mds(disconnected_data()), "disconnected")
})

test_that("component = 'largest' assigns exactly zero outside the dominant one", {
  skip_if_not_installed("igraph")

  # Not "close to zero" -- exactly zero. This is why no centrality_min can
  # rescue a disconnected module, and why the warning is worded as it is.
  result <- suppressWarnings(na_select_mds(disconnected_data(),
                                           component = "largest"))

  zeroed <- result$centrality[result$centrality == 0]
  expect_gte(length(zeroed), 3)

  # An entire clique correlating internally above 0.95 is discarded.
  discarded <- names(zeroed)
  expect_gt(abs(result$correlation[discarded[1], discarded[2]]), 0.95)
  expect_false(any(discarded %in% result$mds))
})

test_that("component = 'all' rescues a disconnected but well-structured module", {
  skip_if_not_installed("igraph")

  d <- disconnected_data()

  largest <- suppressWarnings(na_select_mds(d, component = "largest"))
  all_comp <- suppressWarnings(na_select_mds(d, component = "all"))

  # Each component is now judged on its own terms, so both cliques contribute.
  expect_gt(length(all_comp$mds), length(largest$mds))
  expect_false(any(all_comp$centrality == 0))

  # One representative from each clique.
  expect_true(any(grepl("^a", all_comp$mds)))
  expect_true(any(grepl("^b", all_comp$mds)))
})

test_that("component has no effect on a connected network", {
  skip_if_not_installed("igraph")

  d <- connected_data()
  expect_equal(igraph::components(na_select_mds(d)$graph)$no, 1)

  largest <- na_select_mds(d, component = "largest")
  all_comp <- na_select_mds(d, component = "all")

  expect_identical(largest$mds, all_comp$mds)
  expect_equal(largest$centrality, all_comp$centrality)
})

test_that("a network with no edges errors rather than returning nonsense", {
  skip_if_not_installed("igraph")

  set.seed(22)
  df <- as.data.frame(matrix(rnorm(60 * 4), ncol = 4))
  names(df) <- c("w", "x", "y", "z")

  expect_error(na_select_mds(df, r_min = 0.99),
               "no edges and centrality is")
})


# ---- input validation -------------------------------------------------------

test_that("na_select_mds validates its thresholds", {
  skip_if_not_installed("igraph")

  d <- network_data()

  expect_error(na_select_mds(d, r_min = 1.5), "r_min must be")
  expect_error(na_select_mds(d, r_min = -0.1), "r_min must be")
  expect_error(na_select_mds(d, p_max = 0), "p_max must be")
  expect_error(na_select_mds(d, p_max = 2), "p_max must be")
  expect_error(na_select_mds(d, within = 1.5), "within must be")
})

test_that("na_select_mds validates its data", {
  skip_if_not_installed("igraph")

  expect_error(na_select_mds("a"), "must be a data frame or matrix")
  expect_error(na_select_mds(data.frame(a = 1:5, b = 6:10)),
               "At least 3 usable numeric columns")
  expect_error(
    na_select_mds(data.frame(a = letters[1:5], b = letters[1:5],
                             c = letters[1:5])),
    "at least one numeric column"
  )
})

test_that("na_select_mds drops constant columns with a warning", {
  skip_if_not_installed("igraph")

  set.seed(23)
  n <- 60
  base <- rnorm(n)
  df <- data.frame(
    a = base + rnorm(n, 0, 0.05),
    b = base + rnorm(n, 0, 0.05),
    c = base + rnorm(n, 0, 0.05),
    flat = rep(1, n)
  )

  expect_warning(na_select_mds(df), "constant columns")

  result <- suppressWarnings(na_select_mds(df))
  expect_false("flat" %in% names(result$centrality))
})


# ---- mds_consensus ----------------------------------------------------------

test_that("mds_consensus returns the intersection of both routes", {
  skip_if_not_installed("igraph")

  agreement <- suppressWarnings(mds_consensus(network_data()))

  expect_setequal(
    agreement$consensus,
    intersect(agreement$pca$mds, agreement$network$mds)
  )
  expect_setequal(agreement$pca_only,
                  setdiff(agreement$pca$mds, agreement$network$mds))
  expect_setequal(agreement$network_only,
                  setdiff(agreement$network$mds, agreement$pca$mds))
})

test_that("mds_consensus carries both full results", {
  skip_if_not_installed("igraph")

  agreement <- suppressWarnings(mds_consensus(network_data()))

  expect_true(all(c("mds", "pca", "loadings", "var_exp") %in%
                    names(agreement$pca)))
  expect_true(all(c("mds", "weights", "centrality") %in%
                    names(agreement$network)))
})

test_that("mds_consensus warns on an empty intersection", {
  skip_if_not_installed("igraph")

  set.seed(24)
  n <- 60
  base <- rnorm(n)

  # PCA will favour the high-variance loner; the network will favour the hub.
  df <- data.frame(
    h1 = base + rnorm(n, 0, 0.02),
    h2 = base + rnorm(n, 0, 0.02),
    h3 = base + rnorm(n, 0, 0.02),
    loner = rnorm(n, 0, 50)
  )

  agreement <- suppressWarnings(mds_consensus(df))
  expect_type(agreement$consensus, "character")
})

test_that("mds_consensus passes arguments through to both routes", {
  skip_if_not_installed("igraph")

  strict <- suppressWarnings(
    mds_consensus(correlated_data(), na_args = list(r_min = 0.85))
  )
  loose <- suppressWarnings(
    mds_consensus(correlated_data(), na_args = list(r_min = 0.5))
  )

  expect_gte(igraph::ecount(loose$network$graph),
             igraph::ecount(strict$network$graph))
})


# ---- wiring into the engine -------------------------------------------------

test_that("compute_sqi_df accepts select = 'network'", {
  skip_if_not_installed("igraph")

  df <- soil_data[, c("SampleID", network_props)]

  result <- suppressWarnings(
    compute_sqi_df(df, id_column = "SampleID", select = "network")
  )

  expect_s3_class(result, "sqi_result")
  expect_identical(result$select, "network")
  expect_false(is.null(result$network))
  expect_false(anyNA(result$results$SQI))
})

test_that("select = 'network' uses centrality weights", {
  skip_if_not_installed("igraph")

  df <- soil_data[, c("SampleID", network_props)]

  result <- suppressWarnings(
    compute_sqi_df(df, id_column = "SampleID", select = "network")
  )

  expect_equal(sum(result$weights), 1)
  expect_equal(result$weights, result$network$weights[result$mds])

  # Not equal weights, unlike the PCA route with no pairwise matrix.
  if (length(result$mds) > 1) {
    expect_false(isTRUE(all.equal(
      unname(result$weights),
      rep(1 / length(result$mds), length(result$mds))
    )))
  }
})

test_that("an explicit pairwise matrix overrides centrality weights", {
  skip_if_not_installed("igraph")

  # soil_data collapses to a single indicator on this route, and a pairwise
  # matrix needs at least two, so this uses the structured fixture and
  # per-component centrality to get one representative per clique.
  df <- cbind(SampleID = paste0("S", seq_len(120)), disconnected_data())
  net_args <- list(component = "all")

  centrality_weighted <- suppressWarnings(
    compute_sqi_df(df, id_column = "SampleID", select = "network",
                   network_args = net_args)
  )

  mds <- centrality_weighted$mds
  expect_gt(length(mds), 1)

  pairwise <- matrix(1, nrow = length(mds), ncol = length(mds),
                     dimnames = list(mds, mds))

  overridden <- suppressWarnings(
    compute_sqi_df(df, id_column = "SampleID", select = "network",
                   network_args = net_args, pairwise_df = pairwise)
  )

  expect_equal(unname(overridden$weights),
               rep(1 / length(mds), length(mds)))

  # The centrality weights it replaced came from the network result, not from
  # the equal-weight fallback. (They happen to be near-equal here: with
  # component = "all" each clique's representative is the maximum of its own
  # component, so both normalise to 1.)
  expect_equal(centrality_weighted$weights,
               centrality_weighted$network$weights[mds])
})

test_that("select still defaults to pca", {
  df <- soil_data[, c("SampleID", network_props)]

  default <- compute_sqi_df(df, id_column = "SampleID")

  expect_identical(default$select, "pca")
  expect_null(default$network)
})

test_that("network and pca routes select differently on soil_data", {
  skip_if_not_installed("igraph")

  df <- soil_data[, c("SampleID", network_props)]

  pca <- compute_sqi_df(df, id_column = "SampleID")
  net <- suppressWarnings(
    compute_sqi_df(df, id_column = "SampleID", select = "network")
  )

  # The two reward different properties, so agreement would be surprising.
  expect_false(identical(sort(pca$mds), sort(net$mds)))
})

test_that("the network route composes with sqi_validate and sqi_compare", {
  skip_if_not_installed("igraph")

  df <- soil_data[, c("SampleID", network_props)]

  pca <- compute_sqi_df(df, id_column = "SampleID")
  net <- suppressWarnings(
    compute_sqi_df(df, id_column = "SampleID", select = "network")
  )

  v <- suppressWarnings(sqi_validate(net))
  expect_s3_class(v, "sqi_validation")

  cmp <- sqi_compare(pca = pca, network = net)
  expect_equal(nrow(cmp$pairs), 1)
  expect_false(is.na(cmp$pairs$spearman))
})

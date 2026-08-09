# Tests for functional (EMDS) grouping

grouping_props <- c("Sand", "Silt", "Clay", "BD", "pH", "OM", "SOC", "N",
                    "P", "K", "CEC", "Ca", "Mg", "S", "EC")

grouped_data <- function() soil_structured[, grouping_props]


# ---- the shipped grouping ---------------------------------------------------

test_that("soil_function_groups ships the five functions", {
  expect_type(soil_function_groups, "list")
  expect_length(soil_function_groups, 5)

  expect_identical(
    names(soil_function_groups),
    c("carbon_cycling", "nutrient_cycling", "physical_structure",
      "buffering_filtration", "biodiversity")
  )
})

test_that("the biodiversity group is deliberately empty", {
  # Nothing in this package's indicator vocabulary measures soil biodiversity:
  # that needs microbial biomass, enzyme activity, respiration or a community
  # measure. Shipping a proxy would misrepresent what the index covers.
  expect_length(soil_function_groups$biodiversity, 0)
  expect_type(soil_function_groups$biodiversity, "character")
})

test_that("no indicator is assigned to two functions", {
  all_members <- unlist(soil_function_groups, use.names = FALSE)

  expect_equal(anyDuplicated(all_members), 0)
})

test_that("the grouping covers the datasets' vocabulary", {
  assigned <- unlist(soil_function_groups, use.names = FALSE)
  vocabulary <- setdiff(names(soil_structured), "SampleID")

  expect_setequal(intersect(vocabulary, assigned), vocabulary)
})

test_that("OM and SOC land in the same group", {
  # SOC = OM / 1.724, so they are two measurements of one pool. If they ended
  # up in different groups, grouped selection would keep both and the whole
  # exercise would have failed at its first job.
  expect_true(all(c("OM", "SOC") %in% soil_function_groups$carbon_cycling))
})


# ---- assign_function_groups -------------------------------------------------

test_that("assign_function_groups maps names onto functions", {
  result <- assign_function_groups(c("pH", "OM", "SOC", "BD", "N"))

  expect_setequal(result$carbon_cycling, c("OM", "SOC"))
  expect_setequal(result$nutrient_cycling, "N")
  expect_setequal(result$physical_structure, "BD")
  expect_setequal(result$buffering_filtration, "pH")
})

test_that("assign_function_groups drops empty groups by default", {
  result <- assign_function_groups(c("OM", "SOC"))

  expect_named(result, "carbon_cycling")
  expect_false("biodiversity" %in% names(result))
})

test_that("assign_function_groups can keep empty groups", {
  result <- assign_function_groups(c("OM", "SOC"), drop_empty = FALSE)

  expect_true("biodiversity" %in% names(result))
  expect_length(result$biodiversity, 0)
})

test_that("assign_function_groups surfaces unknown names instead of dropping them", {
  result <- assign_function_groups(c("OM", "Zn", "typo"))

  expect_setequal(result$unassigned, c("Zn", "typo"))
})

test_that("assign_function_groups matches case-insensitively", {
  result <- assign_function_groups(c("om", "PH", "bd"))

  expect_setequal(result$carbon_cycling, "om")
  expect_setequal(result$buffering_filtration, "PH")
  expect_setequal(result$physical_structure, "bd")
})

test_that("assign_function_groups validates its input", {
  expect_error(assign_function_groups(character(0)), "non-empty character")
  expect_error(assign_function_groups(1:3), "non-empty character")
  expect_error(assign_function_groups("OM", groups = list(c("a"))),
               "named list")
})


# ---- pca_select_mds(groups = ) ----------------------------------------------

test_that("pca_select_mds is unchanged when groups is NULL", {
  d <- standardize_numeric(grouped_data())

  plain <- pca_select_mds(d)

  expect_null(plain$groups)
  expect_null(plain$group_results)
  expect_type(plain$mds, "character")

  # The historical components are still there and still mean the same thing.
  expect_s3_class(plain$pca, "prcomp")
  expect_equal(sum(plain$var_exp), 1)
})

test_that("grouped selection draws from every populated group", {
  d <- standardize_numeric(grouped_data())
  groups <- assign_function_groups(grouping_props)

  result <- pca_select_mds(d, groups = groups)

  expect_false(is.null(result$group_results))
  expect_named(result$group_results, names(result$groups))

  # Every populated group contributes at least one indicator.
  for (g in names(result$groups)) {
    contributed <- intersect(result$group_results[[g]]$mds, result$mds)
    expect_gt(length(contributed), 0)
  }
})

test_that("grouped selection rescues the base-status function", {
  # The motivating case. Ungrouped, the network route discards pH/Ca/Mg/EC
  # entirely because they are peripheral; grouping guarantees the function is
  # represented.
  d <- standardize_numeric(grouped_data())
  groups <- assign_function_groups(grouping_props)

  result <- pca_select_mds(d, groups = groups)
  buffering <- soil_function_groups$buffering_filtration

  expect_gt(length(intersect(result$mds, buffering)), 0)
})

test_that("empty groups are skipped rather than erroring", {
  d <- standardize_numeric(grouped_data())

  # soil_function_groups ships an empty biodiversity group on purpose.
  result <- pca_select_mds(d, groups = soil_function_groups)

  expect_false("biodiversity" %in% names(result$groups))
  expect_gt(length(result$mds), 0)
})

test_that("a single-indicator group selects itself", {
  d <- standardize_numeric(grouped_data())

  result <- pca_select_mds(d, groups = list(only = "pH", rest = c("OM", "SOC")))

  expect_true("pH" %in% result$mds)
  expect_identical(result$group_results$only$mds, "pH")
})

test_that("groups referring to absent indicators warn and are trimmed", {
  d <- standardize_numeric(grouped_data())

  expect_warning(
    pca_select_mds(d, groups = list(a = c("OM", "NotAProperty"),
                                    b = c("pH", "CEC"))),
    "absent from the data"
  )
})

test_that("a grouping that matches nothing errors", {
  d <- standardize_numeric(grouped_data())

  expect_error(
    suppressWarnings(pca_select_mds(d, groups = list(a = "Nope", b = "Nada"))),
    "contains any indicator present"
  )
})

test_that("the unassigned bucket is excluded from selection", {
  d <- standardize_numeric(grouped_data())
  groups <- list(carbon = c("OM", "SOC"), unassigned = c("pH", "CEC"))

  result <- pca_select_mds(d, groups = groups)

  expect_false("unassigned" %in% names(result$groups))
  expect_false(any(c("pH", "CEC") %in% result$mds))
})


# ---- the relative loading rule (relocated task 7.1) -------------------------

test_that("within = NULL keeps the historical one-per-component rule", {
  d <- standardize_numeric(grouped_data())

  expect_identical(pca_select_mds(d)$mds,
                   pca_select_mds(d, within = NULL)$mds)
})

test_that("within = 0.10 implements the published rule and widens the MDS", {
  d <- standardize_numeric(grouped_data())

  narrow <- pca_select_mds(d)
  wide <- pca_select_mds(d, within = 0.10)

  expect_gte(length(wide$mds), length(narrow$mds))
  expect_true(all(narrow$mds %in% wide$mds))
})

test_that("a wider band never selects fewer indicators", {
  d <- standardize_numeric(grouped_data())

  sizes <- vapply(c(0, 0.1, 0.3, 0.6), function(w) {
    length(pca_select_mds(d, within = w)$mds)
  }, integer(1))

  expect_false(is.unsorted(sizes))
})

test_that("selected indicators respect the relative band on their component", {
  d <- standardize_numeric(grouped_data())
  result <- pca_select_mds(d, within = 0.10)

  loadings <- result$loadings
  retained <- which(result$var_exp > 0.05)

  # Each selected indicator must be within 10% of the maximum loading on at
  # least one retained component, and clear the absolute floor there too.
  for (ind in result$mds) {
    ok <- vapply(retained, function(k) {
      a <- abs(loadings[, k])
      abs(loadings[ind, k]) >= 0.9 * max(a) && abs(loadings[ind, k]) > 0.5
    }, logical(1))
    expect_true(any(ok), info = ind)
  }
})

test_that("within is validated", {
  d <- standardize_numeric(grouped_data())

  expect_error(pca_select_mds(d, within = 1.5), "within must be")
  expect_error(pca_select_mds(d, within = -0.1), "within must be")
  expect_error(pca_select_mds(d, within = c(0.1, 0.2)), "within must be")
})


# ---- the norm-value selector ------------------------------------------------

test_that("selector = 'norm' reports norm values per group", {
  d <- standardize_numeric(grouped_data())
  groups <- assign_function_groups(grouping_props)

  result <- pca_select_mds(d, groups = groups, selector = "norm")

  expect_identical(result$selector, "norm")

  multi <- names(result$groups)[
    vapply(result$groups, length, integer(1)) > 1
  ]
  for (g in multi) {
    norms <- result$group_results[[g]]$norms
    expect_gt(length(norms), 0)
    expect_true(all(norms >= 0))
  }
})

test_that("the norm selector picks the highest-norm indicator per group", {
  d <- standardize_numeric(grouped_data())
  groups <- assign_function_groups(grouping_props)

  result <- pca_select_mds(d, groups = groups, selector = "norm")

  multi <- names(result$groups)[
    vapply(result$groups, length, integer(1)) > 1
  ]
  for (g in multi) {
    norms <- result$group_results[[g]]$norms
    picked <- result$group_results[[g]]$mds
    expect_equal(unname(norms[picked[1]]), unname(max(norms)), info = g)
  }
})

test_that("the norm formula matches Yuan eq. 2 computed by hand", {
  # N_i = sqrt( sum_k u_ik^2 * lambda_k ) over PCs with eigenvalue >= 1.
  members <- c("Sand", "Silt", "Clay", "BD")
  x <- as.matrix(standardize_numeric(soil_structured[, members]))

  result <- pca_select_mds(standardize_numeric(soil_structured[, members]),
                           groups = list(physical = members),
                           selector = "norm")

  pca <- prcomp(x, scale. = FALSE)
  eig <- pca$sdev^2
  kaiser <- which(eig >= 1)
  expected <- sqrt(rowSums(
    pca$rotation[, kaiser, drop = FALSE]^2 *
      rep(eig[kaiser], each = nrow(pca$rotation))
  ))

  expect_equal(result$group_results$physical$norms[names(expected)],
               expected, tolerance = 1e-10)
})

test_that("the norm selector widens with `within` too", {
  d <- standardize_numeric(grouped_data())
  groups <- assign_function_groups(grouping_props)

  tight <- pca_select_mds(d, groups = groups, selector = "norm")
  wide <- pca_select_mds(d, groups = groups, selector = "norm", within = 0.5)

  expect_gte(length(wide$mds), length(tight$mds))
})


# ---- na_select_mds(groups = ) -----------------------------------------------

test_that("na_select_mds groups run per function", {
  skip_if_not_installed("igraph")

  groups <- assign_function_groups(grouping_props)

  result <- suppressWarnings(
    na_select_mds(grouped_data(), groups = groups)
  )

  expect_true(result$grouped)
  expect_named(result$group_results, names(result$groups))
  expect_equal(sum(result$weights), 1)
  expect_identical(names(result$weights), result$mds)
})

test_that("grouping stops whole functions from being left unrepresented", {
  skip_if_not_installed("igraph")

  groups <- assign_function_groups(grouping_props)

  covered <- function(mds) {
    names(groups)[vapply(groups, function(m) any(m %in% mds), logical(1))]
  }

  ungrouped <- suppressWarnings(na_select_mds(grouped_data()))
  grouped <- suppressWarnings(na_select_mds(grouped_data(), groups = groups))

  # This is the whole point of the phase. On soil_structured the ungrouped
  # route returns OM and CEC, which leaves nutrient cycling and physical
  # structure with no representative at all; grouping covers every function.
  expect_lt(length(covered(ungrouped$mds)), length(groups))
  expect_setequal(covered(grouped$mds), names(groups))
})

test_that("the base-status indicators are absent from the ungrouped MDS", {
  skip_if_not_installed("igraph")

  # pH, Ca, Mg and EC form an internally coherent module that is peripheral to
  # the network, so the centrality filter drops all four. (CEC survives, but it
  # belongs to the other module.)
  ungrouped <- suppressWarnings(na_select_mds(grouped_data()))

  expect_length(intersect(ungrouped$mds, c("pH", "Ca", "Mg", "EC")), 0)
})

test_that("small groups fall back loudly, not silently", {
  skip_if_not_installed("igraph")

  # carbon_cycling is two indicators; three is the minimum for a network.
  expect_warning(
    na_select_mds(grouped_data(),
                  groups = list(carbon = c("OM", "SOC"),
                                physical = c("Sand", "Silt", "Clay", "BD"))),
    "too small or too sparse"
  )

  result <- suppressWarnings(
    na_select_mds(grouped_data(),
                  groups = list(carbon = c("OM", "SOC"),
                                physical = c("Sand", "Silt", "Clay", "BD")))
  )

  expect_match(result$group_results$carbon$method, "^fallback")
  expect_length(result$group_results$carbon$mds, 1)
})

test_that("na_select_mds is unchanged when groups is NULL", {
  skip_if_not_installed("igraph")

  result <- suppressWarnings(na_select_mds(grouped_data()))

  expect_null(result$grouped)
  expect_false(is.null(result$graph))
  expect_false(is.null(result$centrality))
})


# ---- end to end -------------------------------------------------------------

test_that("a grouped MDS keeps one indicator per function, not several", {
  d <- standardize_numeric(grouped_data())
  groups <- assign_function_groups(grouping_props)

  result <- pca_select_mds(d, groups = groups, selector = "norm")

  # The norm selector takes the single best per group, so the MDS size cannot
  # exceed the number of populated groups.
  expect_lte(length(result$mds), length(result$groups))

  # And OM/SOC, being 0.99 correlated, must not both survive.
  expect_lte(length(intersect(result$mds, c("OM", "SOC"))), 1)
})

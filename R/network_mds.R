#' Select a Minimum Data Set by correlation-network analysis
#'
#' Selects indicators by their \strong{centrality} in a correlation network,
#' rather than by their contribution to variance as \code{\link{pca_select_mds}}
#' does. The two answer different questions, and the literature reports the
#' network route performing better on several axes.
#'
#' @details
#' \strong{Why this exists.} Yuan and Shi (2026) measured network-analysis
#' selection against PCA on 40 years of tillage data and found it gave better
#' fidelity to the total data set (R-squared 0.63 vs 0.58), higher sensitivity
#' (SI 1.30-2.92 vs 1.14-2.72), and selected \emph{fewer} indicators. It also
#' makes \strong{no normality assumption}, which PCA does.
#'
#' The deeper difference is what each method rewards. PCA favours indicators
#' that carry \strong{variance}; network analysis favours indicators that are
#' \strong{hubs} -- connected to many others. An indicator can be an ecological
#' hub while varying little, and vice versa.
#'
#' \strong{The procedure}, following Yuan and Shi (2026) section 2.3.2:
#' \enumerate{
#'   \item Build a correlation network: nodes are indicators, and an edge is
#'     drawn where Spearman \code{|r| >= r_min} \strong{and} \code{p < p_max}.
#'     Edge weights are \code{|r|}.
#'   \item Detect communities by Louvain/Blondel modularity
#'     (\code{igraph::cluster_louvain}, after Blondel et al. 2008).
#'   \item Keep only modules whose \strong{maximum eigenvector centrality
#'     exceeds \code{centrality_min}}. Yuan presents this as the network
#'     analogue of retaining principal components that explain at least 5\% of
#'     variance.
#'   \item Within each kept module, retain every indicator whose centrality is
#'     within \code{within} of the module maximum, i.e.
#'     \code{centrality >= (1 - within) * max(centrality)}.
#'   \item Break ties by weighted degree (\code{igraph::strength}).
#'   \item Optionally screen out surviving indicators that remain strongly
#'     correlated with a more central one (see \code{screen}).
#'   \item Weights are eigenvector centrality, normalised to sum to 1.
#' }
#'
#' \strong{Two behaviours worth knowing before you rely on this.}
#'
#' \emph{Uncorrelated indicators are dropped.} An indicator that correlates
#' with nothing has no edges, so its centrality is approximately zero and it
#' fails the module filter. PCA would probably retain the same indicator,
#' because a variable that is uncorrelated with everything tends to dominate a
#' principal component of its own. If an indicator carries unique information,
#' this route discards it precisely \emph{because} it is unique. Check
#' \code{$isolated} in the returned object.
#'
#' \emph{Centrality is computed on the whole graph by default, and that erases
#' disconnected components.} Computing it globally is what lets the
#' \code{centrality_min} filter discriminate between modules at all -- within a
#' module's own subgraph the maximum is 1 by normalisation, so the filter would
#' never reject anything.
#'
#' The cost is severe and not merely theoretical. When the network splits into
#' disconnected components, eigenvector centrality drives every node outside
#' the dominant component to \strong{zero, or to a value indistinguishable
#' from it} -- around \eqn{10^{-17}}, depending on the BLAS implementation.
#' A group of three indicators correlating with each other at 0.98 will be
#' discarded in its entirety, and \strong{no usable value of
#' \code{centrality_min} can rescue it}. This was measured during development,
#' not inferred.
#'
#' Yuan's procedure implicitly assumes a connected network. When yours is not,
#' set \code{component = "all"} to compute centrality separately within each
#' connected component, so each sub-network is judged on its own terms. A
#' warning is raised whenever the graph is disconnected, and \code{$modules}
#' reports the maximum centrality per module so the damage is visible.
#'
#' \strong{Louvain is randomised, so this method is not deterministic by
#' nature.} \code{igraph::cluster_louvain} explores node orderings at random,
#' and on data with weak or tied structure it can return different communities
#' -- and therefore a different Minimum Data Set -- from run to run on
#' \emph{identical} input. This was observed during development: six runs over
#' the same matrix returned two different selections.
#'
#' A selection that changes between runs cannot be reproduced from a published
#' method section, so \code{seed} defaults to 1 and the result is stable by
#' default. That stability is a convenience, not evidence: \strong{vary the
#' seed to find out whether your selection is actually robust}. If it moves,
#' the network structure is too weak to support a confident choice, and
#' \code{\link{mds_consensus}} or a larger sample is the honest response.
#'
#' \strong{Correlation is not causation.} A correlation network cannot
#' establish a causal relationship, and shared environmental drivers routinely
#' produce edges between indicators that do not interact at all (Yuan cites
#' Connor et al. 2017 and Deutschmann et al. 2021). Yuan recommends verifying a
#' selected set against random forest importance or a structural equation
#' model. Treat the output as a hypothesis about which indicators matter, not
#' as a finding.
#'
#' @param data A data frame of indicator values. Only numeric columns are used.
#'   Unlike \code{\link{pca_select_mds}}, the data need \strong{not} be
#'   standardised: Spearman correlation is rank-based and invariant to any
#'   monotonic rescaling.
#' @param r_min Minimum absolute Spearman correlation for an edge. Defaults to
#'   0.60.
#' @param p_max Maximum p-value for an edge. Defaults to 0.01.
#' @param centrality_min Minimum module maximum eigenvector centrality for a
#'   module to be retained. Defaults to 0.6.
#' @param within Relative tolerance below the module maximum centrality within
#'   which indicators are retained. Defaults to 0.10, i.e. "within 10 percent".
#' @param screen If \code{TRUE} (the default), drop a retained indicator when
#'   it still correlates at \code{>= r_min} with a retained indicator of higher
#'   centrality \strong{in the same module}. The screen deliberately does not
#'   run across modules: they exist to partition the indicator space so each
#'   contributes a representative, and screening globally would discard those
#'   representatives as redundant with the single most central indicator,
#'   collapsing the partition the module step just built. \strong{Note:}
#'   \code{\link{pca_select_mds}} performs no equivalent screening -- it takes
#'   one indicator per component -- so this is an additional step in this
#'   route, not a mirror of the other one.
#' @param component How to compute eigenvector centrality when the network is
#'   disconnected. \code{"largest"} (the default) computes it over the whole
#'   graph, which is Yuan's literal procedure and drives the centrality of
#'   everything outside the dominant component to zero. \code{"all"} computes it
#'   separately within each connected component, normalised per component, so
#'   that a well-structured but disconnected group of indicators can still be
#'   selected. Has no effect on a connected network.
#' @param groups Optional named list of character vectors assigning indicators
#'   to functional groups, as produced by
#'   \code{\link{assign_function_groups}}. When supplied, the whole procedure
#'   runs \strong{independently inside each group} and the results are
#'   combined, so that every function contributes an indicator instead of one
#'   dominant function crowding the others out.
#'
#'   A group can be too small for a correlation network -- carbon cycling is
#'   two indicators, and three is the minimum for a graph worth clustering.
#'   Such a group falls back to keeping the indicator most strongly correlated
#'   with the rest of its group, which is the same principle degraded to
#'   something computable. \strong{The fallback warns and is recorded per group
#'   in \code{$group_results}}, because it is not the published method.
#'
#'   With \code{groups} supplied the return value carries \code{$mds},
#'   \code{$weights}, \code{$groups}, \code{$group_results} and
#'   \code{$grouped}; the pool-level graph and centrality have no single
#'   meaning across groups and are absent.
#' @param seed Integer seed for the Louvain step, which is \strong{randomised}.
#'   Defaults to 1 so that the same data yields the same Minimum Data Set; see
#'   the note on reproducibility below. The seed is applied in a local scope
#'   and the caller's random number stream is restored on exit. Pass
#'   \code{NULL} to use the ambient stream instead.
#'
#' @return A list with:
#'   \describe{
#'     \item{mds}{Character vector of selected indicators, most central first.
#'       This is the component that is interchangeable with
#'       \code{\link{pca_select_mds}}.}
#'     \item{weights}{Named numeric vector of centrality-derived weights over
#'       the selected set, summing to 1}
#'     \item{centrality}{Named numeric vector of eigenvector centrality for
#'       every indicator}
#'     \item{strength}{Named numeric vector of weighted degree}
#'     \item{membership}{Named integer vector of community membership}
#'     \item{modules}{Data frame of module id, size, maximum centrality and
#'       whether it was retained}
#'     \item{isolated}{Character vector of indicators with no edges}
#'     \item{screened}{Character vector of indicators dropped by the
#'       correlation screen}
#'     \item{graph}{The \code{igraph} object}
#'     \item{correlation}{Spearman correlation matrix}
#'     \item{p_values}{Matrix of correlation p-values}
#'   }
#'   Note that \code{pca}, \code{loadings} and \code{var_exp} have no network
#'   analogue and are absent.
#'
#' @references
#' Yuan, X. and Shi, Y. (2026), section 2.3.2.
#' Blondel, V. D. et al. (2008) -- Louvain community detection.
#'
#' @examples
#' if (requireNamespace("igraph", quietly = TRUE)) {
#'   props <- c("Sand", "Silt", "Clay", "pH", "OM", "SOC", "N", "P", "K",
#'              "CEC", "Ca", "Mg", "BD", "EC")
#'   result <- na_select_mds(soil_data[, props])
#'
#'   result$mds
#'   result$weights
#'
#'   # Indicators that correlate with nothing are dropped by this route
#'   result$isolated
#' }
#'
#' @seealso \code{\link{pca_select_mds}} for the variance-based route;
#'   \code{\link{mds_consensus}} to run both and take the intersection
#'
#' @export
na_select_mds <- function(data,
                          r_min = 0.60,
                          p_max = 0.01,
                          centrality_min = 0.6,
                          within = 0.10,
                          screen = TRUE,
                          component = c("largest", "all"),
                          groups = NULL,
                          seed = 1L) {
  .require_igraph("na_select_mds")
  component <- match.arg(component)

  if (!is.null(groups)) {
    return(.na_select_grouped(
      data = data, groups = groups, r_min = r_min, p_max = p_max,
      centrality_min = centrality_min, within = within, screen = screen,
      component = component, seed = seed
    ))
  }

  # Louvain is randomised. Seed locally and restore the caller's stream so
  # that a reproducible selection does not cost them their RNG state.
  if (!is.null(seed)) {
    if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) {
      old_seed <- get(".Random.seed", envir = globalenv(), inherits = FALSE)
      on.exit(assign(".Random.seed", old_seed, envir = globalenv()),
              add = TRUE)
    } else {
      on.exit(suppressWarnings(
        rm(".Random.seed", envir = globalenv())
      ), add = TRUE)
    }
    set.seed(seed)
  }

  numeric_data <- .network_numeric_data(data)

  if (!is.numeric(r_min) || length(r_min) != 1 || r_min < 0 || r_min > 1) {
    stop("r_min must be a single numeric value between 0 and 1")
  }
  if (!is.numeric(p_max) || length(p_max) != 1 || p_max <= 0 || p_max > 1) {
    stop("p_max must be a single numeric value in (0, 1]")
  }
  if (!is.numeric(centrality_min) || length(centrality_min) != 1 ||
      centrality_min < 0 || centrality_min > 1) {
    stop("centrality_min must be a single numeric value between 0 and 1")
  }
  if (!is.numeric(within) || length(within) != 1 || within < 0 || within > 1) {
    stop("within must be a single numeric value between 0 and 1")
  }

  # ---- 1. Correlation network ----------------------------------------------
  cors <- .spearman_with_p(numeric_data)
  indicators <- colnames(numeric_data)

  adjacency <- (abs(cors$r) >= r_min) & (cors$p < p_max)
  adjacency[is.na(adjacency)] <- FALSE
  diag(adjacency) <- FALSE

  if (!any(adjacency)) {
    stop("No indicator pair meets |r| >= ", r_min, " with p < ", p_max,
         ", so the correlation network has no edges and centrality is ",
         "undefined. Relax r_min or p_max, or use pca_select_mds().")
  }

  weighted_adj <- abs(cors$r) * adjacency
  weighted_adj[is.na(weighted_adj)] <- 0

  g <- igraph::graph_from_adjacency_matrix(
    weighted_adj,
    mode = "undirected",
    weighted = TRUE,
    diag = FALSE
  )

  isolated <- indicators[igraph::degree(g) == 0]

  comp <- igraph::components(g)

  # Only a component with structure of its own is worth warning about. A lone
  # isolated indicator is a component too, but it carries no internal
  # correlation to erase and is already reported in $isolated.
  structured_components <- sum(table(comp$membership) > 1)

  if (structured_components > 1 && component == "largest") {
    warning("The correlation network has ", structured_components,
            " disconnected components of more than one indicator. With ",
            "component = \"largest\", eigenvector centrality is driven to 0 ",
            "for every indicator outside the dominant component, so those ",
            "modules CANNOT pass the centrality_min filter at any threshold ",
            "and will be discarded however strong their internal ",
            "correlation. Pass component = \"all\" to evaluate each ",
            "component on its own terms, and inspect $modules and $isolated.")
  }

  # ---- 2. Communities -------------------------------------------------------
  communities <- igraph::cluster_louvain(g, weights = igraph::E(g)$weight)
  membership <- igraph::membership(communities)
  names(membership) <- indicators

  # ---- 3. Centrality --------------------------------------------------------
  centrality <- if (component == "largest" || comp$no == 1) {
    igraph::eigen_centrality(g, weights = igraph::E(g)$weight)$vector
  } else {
    .componentwise_centrality(g, comp)
  }
  names(centrality) <- indicators

  strength <- igraph::strength(g, weights = igraph::E(g)$weight)
  names(strength) <- indicators

  # ---- 4. Module filter and within-module retention -------------------------
  module_ids <- sort(unique(membership))

  modules <- do.call(rbind, lapply(module_ids, function(m) {
    members <- indicators[membership == m]
    data.frame(
      module = m,
      size = length(members),
      max_centrality = max(centrality[members]),
      retained = max(centrality[members]) > centrality_min,
      stringsAsFactors = FALSE
    )
  }))

  kept_modules <- modules$module[modules$retained]

  if (length(kept_modules) == 0) {
    stop("No module has a maximum eigenvector centrality above ",
         centrality_min, " (the highest was ",
         format(max(modules$max_centrality), digits = 3),
         "). Lower centrality_min, or use pca_select_mds().")
  }

  # ---- 4b/5. Within-module retention and screening ---------------------------
  #
  # The screen runs WITHIN each module, not across the selected set as a whole.
  # Modules exist to partition the indicator space so that each contributes a
  # representative; screening globally would discard those representatives as
  # redundant with the single most central indicator and collapse the partition
  # to one indicator, which is what the module step was meant to prevent.
  screened <- character(0)

  selected <- unlist(lapply(kept_modules, function(m) {
    members <- indicators[membership == m]
    module_centrality <- centrality[members]
    cutoff <- (1 - within) * max(module_centrality)

    retained <- .order_indicators(members[module_centrality >= cutoff],
                                  centrality, strength)

    if (!screen || length(retained) < 2) {
      return(retained)
    }

    accepted <- character(0)

    for (candidate in retained) {
      redundant <- any(vapply(accepted, function(a) {
        !is.na(cors$r[candidate, a]) &&
          abs(cors$r[candidate, a]) >= r_min &&
          !is.na(cors$p[candidate, a]) &&
          cors$p[candidate, a] < p_max
      }, logical(1)))

      if (redundant) {
        screened <<- c(screened, candidate)
      } else {
        accepted <- c(accepted, candidate)
      }
    }

    accepted
  }), use.names = FALSE)

  selected <- .order_indicators(selected, centrality, strength)

  # ---- 6. Weights -----------------------------------------------------------
  #
  # Yuan describes the weight as centrality divided by the sum of centralities
  # *within the module*. Normalising over the selected set instead is a
  # deliberate deviation: the weighted additive index requires weights that sum
  # to 1 overall, and a per-module normalisation would sum to the number of
  # modules.
  selected_centrality <- centrality[selected]

  weights <- if (sum(selected_centrality) > 0) {
    selected_centrality / sum(selected_centrality)
  } else {
    stats::setNames(rep(1 / length(selected), length(selected)), selected)
  }

  list(
    mds = selected,
    weights = weights,
    centrality = centrality,
    strength = strength,
    membership = membership,
    modules = modules,
    isolated = isolated,
    screened = screened,
    graph = g,
    correlation = cors$r,
    p_values = cors$p
  )
}


#' Take the consensus of two Minimum Data Set selection routes
#'
#' Runs both the PCA and the correlation-network selection over the same data
#' and returns the indicators both agree on. This is a cheap and underused
#' robustness check: an indicator selected by two methods that reward
#' different properties -- variance and centrality -- is more likely to matter
#' than one selected by either alone.
#'
#' @details
#' On Yuan and Shi's (2026) 40-year tillage data, soil organic carbon,
#' dissolved organic carbon and soil compaction were selected by \strong{all
#' six} minimum-data-set variants tested.
#'
#' The intersection can legitimately be empty. That is informative, not an
#' error: it means the two routes disagree completely about which indicators
#' carry the signal, which is a reason to look at the data before trusting
#' either.
#'
#' @param data A data frame of indicator values.
#' @param pca_args A named list of arguments passed to
#'   \code{\link{pca_select_mds}}. Note that the PCA route expects
#'   standardised data.
#' @param na_args A named list of arguments passed to
#'   \code{\link{na_select_mds}}.
#' @param standardize If \code{TRUE} (the default), the data are standardised
#'   with \code{\link{standardize_numeric}} before the PCA route, which
#'   requires it. The network route is given the unstandardised data, since
#'   Spearman correlation is invariant to monotonic rescaling and standardising
#'   would make no difference.
#'
#' @return A list with:
#'   \describe{
#'     \item{consensus}{Character vector of indicators selected by both routes}
#'     \item{pca}{The full \code{\link{pca_select_mds}} result}
#'     \item{network}{The full \code{\link{na_select_mds}} result}
#'     \item{pca_only}{Indicators selected only by PCA}
#'     \item{network_only}{Indicators selected only by the network route}
#'   }
#'
#' @examples
#' if (requireNamespace("igraph", quietly = TRUE)) {
#'   props <- c("Sand", "Silt", "Clay", "pH", "OM", "SOC", "N", "P", "K",
#'              "CEC", "Ca", "Mg", "BD", "EC")
#'   agreement <- mds_consensus(soil_data[, props])
#'
#'   agreement$consensus
#'   agreement$pca_only
#'   agreement$network_only
#' }
#'
#' @seealso \code{\link{pca_select_mds}}, \code{\link{na_select_mds}}
#'
#' @export
mds_consensus <- function(data,
                          pca_args = list(),
                          na_args = list(),
                          standardize = TRUE) {
  .require_igraph("mds_consensus")

  numeric_data <- .network_numeric_data(data)

  pca_input <- if (standardize) {
    standardize_numeric(as.data.frame(numeric_data))
  } else {
    as.data.frame(numeric_data)
  }

  pca_result <- do.call(pca_select_mds, c(list(pca_input), pca_args))
  na_result <- do.call(na_select_mds,
                       c(list(as.data.frame(numeric_data)), na_args))

  consensus <- intersect(pca_result$mds, na_result$mds)

  if (length(consensus) == 0) {
    warning("The two selection routes share no indicators. This is not an ",
            "error, but it means variance-based and centrality-based ",
            "selection disagree completely on this data set; inspect both ",
            "results before relying on either.")
  }

  list(
    consensus = consensus,
    pca = pca_result,
    network = na_result,
    pca_only = setdiff(pca_result$mds, na_result$mds),
    network_only = setdiff(na_result$mds, pca_result$mds)
  )
}


# Internal: grouped (EMDS) selection for the network route.
#
# The procedure runs independently inside each functional group, so that every
# function contributes an indicator instead of one dominant function crowding
# the others out of a pool-wide competition.
#
# A group can be too small for a correlation network -- carbon cycling is two
# indicators, and three is the minimum for a graph worth clustering. Rather
# than dropping such a group (losing a whole soil function) or keeping all of
# it (defeating the point, since its members are usually near-collinear), it
# falls back to the same principle degraded to something computable: keep the
# indicator most strongly correlated with the rest of its group. The fallback
# is recorded per group in $group_results so it is never silent.
.na_select_grouped <- function(data, groups, r_min, p_max, centrality_min,
                               within, screen, component, seed) {
  numeric_data <- .network_numeric_data(data)
  groups <- .validate_groups(groups, colnames(numeric_data))

  group_results <- lapply(names(groups), function(g) {
    members <- groups[[g]]

    if (length(members) == 1) {
      return(list(mds = members, method = "single-indicator group",
                  result = NULL))
    }

    subset <- numeric_data[, members, drop = FALSE]

    attempt <- try(
      na_select_mds(as.data.frame(subset), r_min = r_min, p_max = p_max,
                    centrality_min = centrality_min, within = within,
                    screen = screen, component = component,
                    groups = NULL, seed = seed),
      silent = TRUE
    )

    if (!inherits(attempt, "try-error")) {
      return(list(mds = attempt$mds, method = "network", result = attempt))
    }

    # Fallback: most correlated with the rest of the group.
    cors <- suppressWarnings(
      stats::cor(subset, method = "spearman", use = "pairwise.complete.obs")
    )
    diag(cors) <- NA
    connectedness <- rowSums(abs(cors), na.rm = TRUE)
    pick <- names(sort(connectedness, decreasing = TRUE))[1]

    list(mds = pick,
         method = paste0("fallback: group too small or too sparse for a ",
                         "network (", length(members), " indicators)"),
         result = NULL)
  })
  names(group_results) <- names(groups)

  mds <- unique(unlist(lapply(group_results, `[[`, "mds"), use.names = FALSE))
  if (is.null(mds)) {
    mds <- character(0)
  }

  # Weights come from each group's own centrality where a network was built,
  # and are equal within a group that fell back. Normalised over the selection.
  raw <- vapply(mds, function(ind) {
    for (gr in group_results) {
      if (ind %in% gr$mds) {
        if (!is.null(gr$result)) {
          return(unname(gr$result$weights[ind]))
        }
        return(1)
      }
    }
    1
  }, numeric(1))

  weights <- raw / sum(raw)
  names(weights) <- mds

  fell_back <- names(group_results)[
    vapply(group_results, function(g) grepl("^fallback", g$method), logical(1))
  ]
  if (length(fell_back) > 0) {
    warning("These groups were too small or too sparse to build a ",
            "correlation network, so the most within-group correlated ",
            "indicator was kept instead: ",
            paste(fell_back, collapse = ", "),
            ". See $group_results for what each group did.")
  }

  list(
    mds = mds,
    weights = weights,
    groups = groups,
    group_results = group_results,
    grouped = TRUE
  )
}


# Internal: eigenvector centrality computed within each connected component and
# normalised per component. On a disconnected graph the global calculation puts
# an exact zero on everything outside the dominant component, which discards
# whole well-correlated groups; this evaluates each sub-network on its own
# terms instead. Isolated nodes have no eigenvector and are left at 0.
.componentwise_centrality <- function(g, comp) {
  centrality <- numeric(igraph::vcount(g))

  for (k in seq_len(comp$no)) {
    members <- which(comp$membership == k)

    if (length(members) < 2) {
      next
    }

    sub <- igraph::induced_subgraph(g, members)
    sub_centrality <- igraph::eigen_centrality(
      sub, weights = igraph::E(sub)$weight
    )$vector

    centrality[members] <- sub_centrality
  }

  centrality
}


# Internal: deterministic ordering of indicators -- centrality first, then
# weighted degree as Yuan's stated tie-break, then the indicator name. The
# last step matters: with both metrics tied, the surviving order would
# otherwise depend on Louvain's randomised membership order.
.order_indicators <- function(x, centrality, strength) {
  x[order(-centrality[x], -strength[x], x)]
}


# Internal: igraph lives in Suggests, because this package is MIT-licensed and
# igraph is GPL-2+. A hard dependency in Imports would pull the combined work
# into GPL territory on distribution, so every entry point guards instead.
.require_igraph <- function(fn) {
  if (!requireNamespace("igraph", quietly = TRUE)) {
    stop("Package 'igraph' is required for ", fn, "() but is not installed. ",
         "Install it with install.packages(\"igraph\").", call. = FALSE)
  }
  invisible(TRUE)
}


# Internal: shared numeric-column extraction and validation for the network
# functions. Mirrors the guards in pca_select_mds().
.network_numeric_data <- function(data) {
  if (!is.data.frame(data) && !is.matrix(data)) {
    stop("data must be a data frame or matrix")
  }

  data <- as.data.frame(data)

  numeric_cols <- vapply(data, is.numeric, logical(1))
  if (!any(numeric_cols)) {
    stop("data must contain at least one numeric column")
  }

  numeric_data <- data[, numeric_cols, drop = FALSE]

  all_na <- vapply(numeric_data, function(x) all(is.na(x)), logical(1))
  if (any(all_na)) {
    warning("Removing columns with all NA values: ",
            paste(names(numeric_data)[all_na], collapse = ", "))
    numeric_data <- numeric_data[, !all_na, drop = FALSE]
  }

  # A constant column has undefined correlation with everything.
  constant <- vapply(numeric_data, function(x) {
    v <- x[!is.na(x)]
    length(v) > 0 && length(unique(v)) == 1
  }, logical(1))
  if (any(constant)) {
    warning("Removing constant columns, whose correlation is undefined: ",
            paste(names(numeric_data)[constant], collapse = ", "))
    numeric_data <- numeric_data[, !constant, drop = FALSE]
  }

  if (ncol(numeric_data) < 3) {
    stop("At least 3 usable numeric columns are required to build a ",
         "correlation network (got ", ncol(numeric_data), ")")
  }

  complete <- stats::complete.cases(numeric_data)
  if (!any(complete)) {
    stop("No complete cases available after removing NA values")
  }
  if (sum(complete) < nrow(numeric_data)) {
    warning("Removing ", nrow(numeric_data) - sum(complete),
            " rows with NA values")
  }

  numeric_data <- numeric_data[complete, , drop = FALSE]

  if (nrow(numeric_data) < 4) {
    stop("At least 4 complete observations are required to test correlation ",
         "significance (got ", nrow(numeric_data), ")")
  }

  as.matrix(numeric_data)
}


# Internal: pairwise Spearman correlations with p-values. stats::cor() gives
# the coefficients but not the significance the edge rule needs, so each pair
# goes through cor.test(). The tie warning is expected on real soil data and
# is suppressed rather than surfaced once per pair.
.spearman_with_p <- function(x) {
  p <- ncol(x)
  nm <- colnames(x)

  r_mat <- matrix(NA_real_, p, p, dimnames = list(nm, nm))
  p_mat <- matrix(NA_real_, p, p, dimnames = list(nm, nm))

  diag(r_mat) <- 1
  diag(p_mat) <- 0

  for (i in seq_len(p - 1)) {
    for (j in seq(i + 1, p)) {
      ct <- suppressWarnings(
        stats::cor.test(x[, i], x[, j], method = "spearman")
      )
      r_mat[i, j] <- r_mat[j, i] <- unname(ct$estimate)
      p_mat[i, j] <- p_mat[j, i] <- ct$p.value
    }
  }

  list(r = r_mat, p = p_mat)
}

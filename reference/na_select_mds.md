# Select a Minimum Data Set by correlation-network analysis

Selects indicators by their **centrality** in a correlation network,
rather than by their contribution to variance as
[`pca_select_mds`](https://ccarbajal16.github.io/soilquality/reference/pca_select_mds.md)
does. The two answer different questions, and the literature reports the
network route performing better on several axes.

## Usage

``` r
na_select_mds(
  data,
  r_min = 0.6,
  p_max = 0.01,
  centrality_min = 0.6,
  within = 0.1,
  screen = TRUE,
  component = c("largest", "all"),
  groups = NULL,
  seed = 1L
)
```

## Arguments

- data:

  A data frame of indicator values. Only numeric columns are used.
  Unlike
  [`pca_select_mds`](https://ccarbajal16.github.io/soilquality/reference/pca_select_mds.md),
  the data need **not** be standardised: Spearman correlation is
  rank-based and invariant to any monotonic rescaling.

- r_min:

  Minimum absolute Spearman correlation for an edge. Defaults to 0.60.

- p_max:

  Maximum p-value for an edge. Defaults to 0.01.

- centrality_min:

  Minimum module maximum eigenvector centrality for a module to be
  retained. Defaults to 0.6.

- within:

  Relative tolerance below the module maximum centrality within which
  indicators are retained. Defaults to 0.10, i.e. "within 10 percent".

- screen:

  If `TRUE` (the default), drop a retained indicator when it still
  correlates at `>= r_min` with a retained indicator of higher
  centrality **in the same module**. The screen deliberately does not
  run across modules: they exist to partition the indicator space so
  each contributes a representative, and screening globally would
  discard those representatives as redundant with the single most
  central indicator, collapsing the partition the module step just
  built. **Note:**
  [`pca_select_mds`](https://ccarbajal16.github.io/soilquality/reference/pca_select_mds.md)
  performs no equivalent screening – it takes one indicator per
  component – so this is an additional step in this route, not a mirror
  of the other one.

- component:

  How to compute eigenvector centrality when the network is
  disconnected. `"largest"` (the default) computes it over the whole
  graph, which is Yuan's literal procedure and drives the centrality of
  everything outside the dominant component to zero. `"all"` computes it
  separately within each connected component, normalised per component,
  so that a well-structured but disconnected group of indicators can
  still be selected. Has no effect on a connected network.

- groups:

  Optional named list of character vectors assigning indicators to
  functional groups, as produced by
  [`assign_function_groups`](https://ccarbajal16.github.io/soilquality/reference/assign_function_groups.md).
  When supplied, the whole procedure runs **independently inside each
  group** and the results are combined, so that every function
  contributes an indicator instead of one dominant function crowding the
  others out.

  A group can be too small for a correlation network – carbon cycling is
  two indicators, and three is the minimum for a graph worth clustering.
  Such a group falls back to keeping the indicator most strongly
  correlated with the rest of its group, which is the same principle
  degraded to something computable. **The fallback warns and is recorded
  per group in `$group_results`**, because it is not the published
  method.

  With `groups` supplied the return value carries `$mds`, `$weights`,
  `$groups`, `$group_results` and `$grouped`; the pool-level graph and
  centrality have no single meaning across groups and are absent.

- seed:

  Integer seed for the Louvain step, which is **randomised**. Defaults
  to 1 so that the same data yields the same Minimum Data Set; see the
  note on reproducibility below. The seed is applied in a local scope
  and the caller's random number stream is restored on exit. Pass `NULL`
  to use the ambient stream instead.

## Value

A list with:

- mds:

  Character vector of selected indicators, most central first. This is
  the component that is interchangeable with
  [`pca_select_mds`](https://ccarbajal16.github.io/soilquality/reference/pca_select_mds.md).

- weights:

  Named numeric vector of centrality-derived weights over the selected
  set, summing to 1

- centrality:

  Named numeric vector of eigenvector centrality for every indicator

- strength:

  Named numeric vector of weighted degree

- membership:

  Named integer vector of community membership

- modules:

  Data frame of module id, size, maximum centrality and whether it was
  retained

- isolated:

  Character vector of indicators with no edges

- screened:

  Character vector of indicators dropped by the correlation screen

- graph:

  The `igraph` object

- correlation:

  Spearman correlation matrix

- p_values:

  Matrix of correlation p-values

Note that `pca`, `loadings` and `var_exp` have no network analogue and
are absent.

## Details

**Why this exists.** Yuan and Shi (2026) measured network-analysis
selection against PCA on 40 years of tillage data and found it gave
better fidelity to the total data set (R-squared 0.63 vs 0.58), higher
sensitivity (SI 1.30-2.92 vs 1.14-2.72), and selected *fewer*
indicators. It also makes **no normality assumption**, which PCA does.

The deeper difference is what each method rewards. PCA favours
indicators that carry **variance**; network analysis favours indicators
that are **hubs** – connected to many others. An indicator can be an
ecological hub while varying little, and vice versa.

**The procedure**, following Yuan and Shi (2026) section 2.3.2:

1.  Build a correlation network: nodes are indicators, and an edge is
    drawn where Spearman `|r| >= r_min` **and** `p < p_max`. Edge
    weights are `|r|`.

2.  Detect communities by Louvain/Blondel modularity
    ([`igraph::cluster_louvain`](https://r.igraph.org/reference/cluster_louvain.html),
    after Blondel et al. 2008).

3.  Keep only modules whose **maximum eigenvector centrality exceeds
    `centrality_min`**. Yuan presents this as the network analogue of
    retaining principal components that explain at least 5% of variance.

4.  Within each kept module, retain every indicator whose centrality is
    within `within` of the module maximum, i.e.
    `centrality >= (1 - within) * max(centrality)`.

5.  Break ties by weighted degree
    ([`igraph::strength`](https://r.igraph.org/reference/strength.html)).

6.  Optionally screen out surviving indicators that remain strongly
    correlated with a more central one (see `screen`).

7.  Weights are eigenvector centrality, normalised to sum to 1.

**Two behaviours worth knowing before you rely on this.**

*Uncorrelated indicators are dropped.* An indicator that correlates with
nothing has no edges, so its centrality is approximately zero and it
fails the module filter. PCA would probably retain the same indicator,
because a variable that is uncorrelated with everything tends to
dominate a principal component of its own. If an indicator carries
unique information, this route discards it precisely *because* it is
unique. Check `$isolated` in the returned object.

*Centrality is computed on the whole graph by default, and that erases
disconnected components.* Computing it globally is what lets the
`centrality_min` filter discriminate between modules at all – within a
module's own subgraph the maximum is 1 by normalisation, so the filter
would never reject anything.

The cost is severe and not merely theoretical. When the network splits
into disconnected components, eigenvector centrality drives every node
outside the dominant component to **zero, or to a value
indistinguishable from it** – around \\10^{-17}\\, depending on the BLAS
implementation. A group of three indicators correlating with each other
at 0.98 will be discarded in its entirety, and **no usable value of
`centrality_min` can rescue it**. This was measured during development,
not inferred.

Yuan's procedure implicitly assumes a connected network. When yours is
not, set `component = "all"` to compute centrality separately within
each connected component, so each sub-network is judged on its own
terms. A warning is raised whenever the graph is disconnected, and
`$modules` reports the maximum centrality per module so the damage is
visible.

**Louvain is randomised, so this method is not deterministic by
nature.**
[`igraph::cluster_louvain`](https://r.igraph.org/reference/cluster_louvain.html)
explores node orderings at random, and on data with weak or tied
structure it can return different communities – and therefore a
different Minimum Data Set – from run to run on *identical* input. This
was observed during development: six runs over the same matrix returned
two different selections.

A selection that changes between runs cannot be reproduced from a
published method section, so `seed` defaults to 1 and the result is
stable by default. That stability is a convenience, not evidence: **vary
the seed to find out whether your selection is actually robust**. If it
moves, the network structure is too weak to support a confident choice,
and
[`mds_consensus`](https://ccarbajal16.github.io/soilquality/reference/mds_consensus.md)
or a larger sample is the honest response.

**Correlation is not causation.** A correlation network cannot establish
a causal relationship, and shared environmental drivers routinely
produce edges between indicators that do not interact at all (Yuan cites
Connor et al. 2017 and Deutschmann et al. 2021). Yuan recommends
verifying a selected set against random forest importance or a
structural equation model. Treat the output as a hypothesis about which
indicators matter, not as a finding.

## References

Yuan, X. and Shi, Y. (2026), section 2.3.2. Blondel, V. D. et al. (2008)
– Louvain community detection.

## See also

[`pca_select_mds`](https://ccarbajal16.github.io/soilquality/reference/pca_select_mds.md)
for the variance-based route;
[`mds_consensus`](https://ccarbajal16.github.io/soilquality/reference/mds_consensus.md)
to run both and take the intersection

## Examples

``` r
if (requireNamespace("igraph", quietly = TRUE)) {
  props <- c("Sand", "Silt", "Clay", "pH", "OM", "SOC", "N", "P", "K",
             "CEC", "Ca", "Mg", "BD", "EC")
  result <- na_select_mds(soil_data[, props])

  result$mds
  result$weights

  # Indicators that correlate with nothing are dropped by this route
  result$isolated
}
#>  [1] "Clay" "pH"   "OM"   "SOC"  "N"    "P"    "K"    "CEC"  "Ca"   "Mg"  
#> [11] "BD"   "EC"  
```

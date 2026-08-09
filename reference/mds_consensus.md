# Take the consensus of two Minimum Data Set selection routes

Runs both the PCA and the correlation-network selection over the same
data and returns the indicators both agree on. This is a cheap and
underused robustness check: an indicator selected by two methods that
reward different properties – variance and centrality – is more likely
to matter than one selected by either alone.

## Usage

``` r
mds_consensus(data, pca_args = list(), na_args = list(), standardize = TRUE)
```

## Arguments

- data:

  A data frame of indicator values.

- pca_args:

  A named list of arguments passed to
  [`pca_select_mds`](https://ccarbajal16.github.io/soilquality/reference/pca_select_mds.md).
  Note that the PCA route expects standardised data.

- na_args:

  A named list of arguments passed to
  [`na_select_mds`](https://ccarbajal16.github.io/soilquality/reference/na_select_mds.md).

- standardize:

  If `TRUE` (the default), the data are standardised with
  [`standardize_numeric`](https://ccarbajal16.github.io/soilquality/reference/standardize_numeric.md)
  before the PCA route, which requires it. The network route is given
  the unstandardised data, since Spearman correlation is invariant to
  monotonic rescaling and standardising would make no difference.

## Value

A list with:

- consensus:

  Character vector of indicators selected by both routes

- pca:

  The full
  [`pca_select_mds`](https://ccarbajal16.github.io/soilquality/reference/pca_select_mds.md)
  result

- network:

  The full
  [`na_select_mds`](https://ccarbajal16.github.io/soilquality/reference/na_select_mds.md)
  result

- pca_only:

  Indicators selected only by PCA

- network_only:

  Indicators selected only by the network route

## Details

On Yuan and Shi's (2026) 40-year tillage data, soil organic carbon,
dissolved organic carbon and soil compaction were selected by **all
six** minimum-data-set variants tested.

The intersection can legitimately be empty. That is informative, not an
error: it means the two routes disagree completely about which
indicators carry the signal, which is a reason to look at the data
before trusting either.

## See also

[`pca_select_mds`](https://ccarbajal16.github.io/soilquality/reference/pca_select_mds.md),
[`na_select_mds`](https://ccarbajal16.github.io/soilquality/reference/na_select_mds.md)

## Examples

``` r
if (requireNamespace("igraph", quietly = TRUE)) {
  props <- c("Sand", "Silt", "Clay", "pH", "OM", "SOC", "N", "P", "K",
             "CEC", "Ca", "Mg", "BD", "EC")
  agreement <- mds_consensus(soil_data[, props])

  agreement$consensus
  agreement$pca_only
  agreement$network_only
}
#> character(0)
```

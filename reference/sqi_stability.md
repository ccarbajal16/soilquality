# Test whether a conclusion survives a change of index recipe

Runs the same samples through two or more index recipes and reports
whether the **ranking of samples survives**. This is the practical
question behind most methodological disagreements in the literature: it
usually does not matter which scoring or aggregation route is "better"
in the abstract, it matters whether your conclusion changes when you
switch.

## Usage

``` r
sqi_stability(..., labels = NULL)
```

## Arguments

- ...:

  Two or more `sqi_result` objects or numeric vectors, all of the same
  length. Name them (e.g. `linear = `, `sigmoid = `) and the names are
  used in the report.

- labels:

  Optional character vector of names, overriding those taken from `...`.

## Value

An object of class `sqi_stability`, a list with:

- n:

  Number of samples

- indices:

  Named list of the index vectors compared

- pairs:

  Data frame with one row per pair: the two labels, the Spearman rho,
  and whether the top and bottom samples are preserved

- stable:

  TRUE when every pair preserves both extremes

## Details

For every pair of indices the Spearman rank correlation is reported,
along with a flag for whether the best-ranked and worst-ranked sample
stay the same. A high rank correlation with a changed top sample is
still a changed conclusion if the top sample is what you act on.

Yuan (2026) used this kind of stability as a selection criterion in its
own right: the EMDS route achieved fidelity R-squared of 0.74-0.77 with
no combination of scoring and aggregation producing p \> 0.05 – that is,
it was **stable**, not merely accurate.

**On the name.** The CRAN package SQIpro exports an unrelated
`sqi_compare()`, which tabulates the index value each of its methods
produces. This function asks a different question and therefore carries
a different name: not *what value does each recipe give*, but *does my
conclusion hold when the recipe changes*. The unit of comparison here is
the ranking, not the values.

## See also

[`sqi_validate`](https://ccarbajal16.github.io/soilquality/reference/sqi_validate.md)
to assess a single index

## Examples

``` r
props <- c("pH", "OM", "N", "P", "K", "CEC", "BD")

linear <- compute_sqi_properties(
  soil_data, properties = props, id_column = "SampleID",
  scoring_rules = standard_scoring_rules(props, scoring = "linear")
)
sigmoid <- compute_sqi_properties(
  soil_data, properties = props, id_column = "SampleID",
  scoring_rules = standard_scoring_rules(props, scoring = "sigmoid")
)

sqi_stability(linear = linear, sigmoid = sigmoid)
#> Soil Quality Index recipe stability
#>   Samples: 50 
#>   Indices: linear, sigmoid 
#> 
#> Pairwise rank agreement
#>   linear       vs sigmoid       rho =  0.884   top kept      bottom CHANGED
#> 
#>   At least one pair disagrees on the best or worst sample. A high
#>   rank correlation does not rescue this if the extreme is what you
#>   act on.
```

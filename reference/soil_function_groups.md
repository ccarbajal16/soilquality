# Soil indicators grouped by ecosystem function

A grouping of soil indicators by the **function** they serve, for use as
the `groups` argument of
[`pca_select_mds`](https://ccarbajal16.github.io/soilquality/reference/pca_select_mds.md)
and
[`na_select_mds`](https://ccarbajal16.github.io/soilquality/reference/na_select_mds.md).
Selecting one indicator per function, rather than picking across the
whole pool at once, is what the literature calls an expanded minimum
data set (EMDS).

## Usage

``` r
soil_function_groups
```

## Format

A named list of five character vectors:

- carbon_cycling:

  `OM`, `SOC` – the organic carbon pool

- nutrient_cycling:

  `N`, `P`, `K`, `Ca`, `Mg`, `S` – plant-available nutrient supply

- physical_structure:

  `Sand`, `Silt`, `Clay`, `BD` – texture and compaction

- buffering_filtration:

  `pH`, `CEC`, `EC` – the capacity to buffer reaction and retain or
  transmit solutes

- biodiversity:

  empty – see Details

## Details

**Why group by function rather than by physical/chemical/biological.**
Two independent lines of evidence point the same way.

Yuan and Shi (2026) found that fidelity to the total data set improved
monotonically with grouping detail: an expanded, function-grouped
minimum data set reached R-squared 0.74-0.77, above a reduced grouping,
which was above no grouping at all. The function-grouped route was also
the most **stable** across scoring and aggregation choices.

Maaz et al. (2023) attacked it from the other side. By confirmatory
factor analysis they tested whether the familiar physical / chemical /
biological split describes how soil indicators actually covary, and
found it **has no statistical support**. It is a convention inherited
from how laboratories are organised, not a structure present in the
data.

**This package still ships that split**, as
`soil_property_sets$physical` and `$chemical`. Those sets are exported,
documented and depended upon, so they are not going anywhere – but they
are a vocabulary for *choosing which properties to measure*, not a basis
for selecting a minimum data set. Use `soil_function_groups` for
selection.

**The empty biodiversity group is deliberate.** Yuan's fifth function,
soil biodiversity maintenance, has **no indicator** in the vocabulary
this package's example data provides – it needs microbial biomass
carbon, enzyme activity, respiration or a community measure, none of
which are present. The group is shipped empty rather than filled with a
proxy, because a plausible-looking stand-in would silently misrepresent
which functions the index actually covers. Selection functions skip
empty groups.

**Some indicators serve more than one function.** Calcium and magnesium
are placed in nutrient cycling because they are measured as
plant-available nutrients, but they are also exchangeable bases and
contribute to buffering. Clay contributes to structure and to cation
retention. The assignment here is a defensible default, not a fact;
supply your own list where your interpretation differs.

## References

Yuan, X. and Shi, Y. (2026), after Li et al. (2023) – the five
functions. Maaz, T. M. et al. (2023) – the confirmatory factor analysis.

## See also

[`assign_function_groups`](https://ccarbajal16.github.io/soilquality/reference/assign_function_groups.md)
to map an arbitrary set of property names onto these functions;
[`soil_property_sets`](https://ccarbajal16.github.io/soilquality/reference/soil_property_sets.md)
for the measurement-oriented sets

## Examples

``` r
names(soil_function_groups)
#> [1] "carbon_cycling"       "nutrient_cycling"     "physical_structure"  
#> [4] "buffering_filtration" "biodiversity"        
soil_function_groups$carbon_cycling
#> [1] "OM"  "SOC"

# The biodiversity group ships empty; nothing in the example data measures it
soil_function_groups$biodiversity
#> character(0)

# Use it to select within functions rather than across the whole pool
props <- c("Sand", "Silt", "Clay", "pH", "OM", "SOC", "N", "P", "K",
           "CEC", "BD")
groups <- assign_function_groups(props)
pca_select_mds(standardize_numeric(soil_structured[, props]),
               groups = groups)
#> $mds
#> [1] "OM"   "N"    "P"    "Sand" "Silt" "BD"   "pH"   "CEC" 
#> 
#> $pca
#> Standard deviations (1, .., p=11):
#>  [1] 2.486867e+00 1.460784e+00 1.062110e+00 1.010308e+00 4.346819e-01
#>  [6] 3.981292e-01 3.086863e-01 2.329300e-01 1.695260e-01 8.403420e-02
#> [11] 2.089575e-16
#> 
#> Rotation (n x k) = (11 x 11):
#>              PC1         PC2         PC3         PC4         PC5         PC6
#> Sand  0.19766126 -0.58702512  0.08394402  0.09097461 -0.01387188 -0.02833608
#> Silt -0.07070105  0.26399338 -0.20667573 -0.86810767 -0.09233192  0.04870587
#> Clay -0.19273743  0.54396709  0.01112915  0.35110366  0.06473819  0.00732817
#> pH   -0.07435711 -0.07830663 -0.88703540  0.19262245  0.29114273  0.24130921
#> OM   -0.36914585 -0.23908254  0.08705770 -0.06371724 -0.02840634  0.20690357
#> SOC  -0.36788610 -0.24396470  0.07383768 -0.07353710  0.01539649  0.21841429
#> N    -0.35689332 -0.23891027  0.11813266 -0.09986352  0.10931065  0.42092758
#> P    -0.32635970 -0.20723936 -0.33230718  0.05017661 -0.61522719 -0.52922150
#> K    -0.37311938  0.13389860  0.10771989  0.12351735 -0.20521234  0.04633549
#> CEC  -0.36878700  0.20665373  0.08910808  0.16749023 -0.09255975  0.11664917
#> BD    0.36406102  0.07960387 -0.07952746  0.11166011 -0.67834399  0.61238685
#>              PC7         PC8          PC9          PC10          PC11
#> Sand  0.24455057 -0.03865604  0.155563755  0.0003183533  7.172961e-01
#> Silt  0.09304696 -0.03230926  0.055128458 -0.0042826446  3.245405e-01
#> Clay -0.33347772  0.06197745 -0.209994795  0.0018838673  6.165710e-01
#> pH    0.14313423 -0.02766828  0.003049187 -0.0121412763  5.392732e-17
#> OM   -0.11487506 -0.38337596 -0.320953739 -0.6986638887 -4.161437e-16
#> SOC  -0.17943728 -0.39798608 -0.227118057  0.7100466294 -1.945640e-16
#> N    -0.25179824  0.70486932  0.204049422 -0.0247563789 -6.297004e-17
#> P    -0.23911467  0.14135545  0.042370320  0.0079441326 -1.249393e-16
#> K     0.77820942  0.23484213 -0.326009795  0.0684893099 -3.599068e-18
#> CEC   0.15397710 -0.33823931  0.789346029 -0.0440555612 -3.764027e-17
#> BD   -0.06746429 -0.03326061 -0.035760246  0.0150162283  1.954883e-16
#> 
#> $loadings
#>              PC1         PC2         PC3         PC4         PC5         PC6
#> Sand  0.19766126 -0.58702512  0.08394402  0.09097461 -0.01387188 -0.02833608
#> Silt -0.07070105  0.26399338 -0.20667573 -0.86810767 -0.09233192  0.04870587
#> Clay -0.19273743  0.54396709  0.01112915  0.35110366  0.06473819  0.00732817
#> pH   -0.07435711 -0.07830663 -0.88703540  0.19262245  0.29114273  0.24130921
#> OM   -0.36914585 -0.23908254  0.08705770 -0.06371724 -0.02840634  0.20690357
#> SOC  -0.36788610 -0.24396470  0.07383768 -0.07353710  0.01539649  0.21841429
#> N    -0.35689332 -0.23891027  0.11813266 -0.09986352  0.10931065  0.42092758
#> P    -0.32635970 -0.20723936 -0.33230718  0.05017661 -0.61522719 -0.52922150
#> K    -0.37311938  0.13389860  0.10771989  0.12351735 -0.20521234  0.04633549
#> CEC  -0.36878700  0.20665373  0.08910808  0.16749023 -0.09255975  0.11664917
#> BD    0.36406102  0.07960387 -0.07952746  0.11166011 -0.67834399  0.61238685
#>              PC7         PC8          PC9          PC10          PC11
#> Sand  0.24455057 -0.03865604  0.155563755  0.0003183533  7.172961e-01
#> Silt  0.09304696 -0.03230926  0.055128458 -0.0042826446  3.245405e-01
#> Clay -0.33347772  0.06197745 -0.209994795  0.0018838673  6.165710e-01
#> pH    0.14313423 -0.02766828  0.003049187 -0.0121412763  5.392732e-17
#> OM   -0.11487506 -0.38337596 -0.320953739 -0.6986638887 -4.161437e-16
#> SOC  -0.17943728 -0.39798608 -0.227118057  0.7100466294 -1.945640e-16
#> N    -0.25179824  0.70486932  0.204049422 -0.0247563789 -6.297004e-17
#> P    -0.23911467  0.14135545  0.042370320  0.0079441326 -1.249393e-16
#> K     0.77820942  0.23484213 -0.326009795  0.0684893099 -3.599068e-18
#> CEC   0.15397710 -0.33823931  0.789346029 -0.0440555612 -3.764027e-17
#> BD   -0.06746429 -0.03326061 -0.035760246  0.0150162283  1.954883e-16
#> 
#> $var_exp
#>  [1] 5.622280e-01 1.939901e-01 1.025526e-01 9.279301e-02 1.717713e-02
#>  [6] 1.440971e-02 8.662475e-03 4.932397e-03 2.612643e-03 6.419770e-04
#> [11] 3.969384e-33
#> 
#> $groups
#> $groups$carbon_cycling
#> [1] "OM"  "SOC"
#> 
#> $groups$nutrient_cycling
#> [1] "N" "P" "K"
#> 
#> $groups$physical_structure
#> [1] "Sand" "Silt" "Clay" "BD"  
#> 
#> $groups$buffering_filtration
#> [1] "pH"  "CEC"
#> 
#> 
#> $group_results
#> $group_results$carbon_cycling
#> $group_results$carbon_cycling$mds
#> [1] "OM"
#> 
#> $group_results$carbon_cycling$norms
#> named numeric(0)
#> 
#> $group_results$carbon_cycling$n_indicators
#> [1] 2
#> 
#> 
#> $group_results$nutrient_cycling
#> $group_results$nutrient_cycling$mds
#> [1] "N" "P"
#> 
#> $group_results$nutrient_cycling$norms
#> named numeric(0)
#> 
#> $group_results$nutrient_cycling$n_indicators
#> [1] 3
#> 
#> 
#> $group_results$physical_structure
#> $group_results$physical_structure$mds
#> [1] "Sand" "Silt" "BD"  
#> 
#> $group_results$physical_structure$norms
#> named numeric(0)
#> 
#> $group_results$physical_structure$n_indicators
#> [1] 4
#> 
#> 
#> $group_results$buffering_filtration
#> $group_results$buffering_filtration$mds
#> [1] "pH"  "CEC"
#> 
#> $group_results$buffering_filtration$norms
#> named numeric(0)
#> 
#> $group_results$buffering_filtration$n_indicators
#> [1] 2
#> 
#> 
#> 
#> $selector
#> [1] "loading"
#> 
#> $within
#> NULL
#> 
#> $adequacy
#> PCA adequacy
#>   Observations: 120  Indicators: 11 
#> 
#> Kaiser-Meyer-Olkin: not computable
#>   The correlation matrix is singular, so it cannot be inverted and KMO is undefined. This usually means some indicators are exactly collinear -- particle-size fractions summing to 100 is the classic case. Pairs correlating above 0.99: OM/SOC.
#> 
#> Bartlett's test of sphericity
#>   Not computable: the correlation matrix is singular.
#> 
```

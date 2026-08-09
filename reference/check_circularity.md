# Detect circularity between an index and its predictors

Refuses to let you regress a soil quality index on the indicators that
**built** it. An index is a weighted sum of its components, so a model
predicting it from those components must fit well: the R-squared is
structural arithmetic, not evidence about soil.

## Usage

``` r
check_circularity(
  index,
  predictors,
  data = NULL,
  allow_components = FALSE,
  r_max = 0.9
)
```

## Arguments

- index:

  An `sqi_result` object, whose `$mds` names the indicators that built
  the index, or a character vector of those names.

- predictors:

  The variables you intend to model the index on: a character vector, a
  one-sided formula such as `~ erosion + slope`, or a data frame whose
  column names are used.

- data:

  Optional data frame containing both the index components and the
  predictors. When supplied, differently-named proxies are detected by
  correlation as well as by name.

- allow_components:

  If `FALSE` (the default) any overlap is an error. `TRUE` permits it
  and marks the result as a decomposition.

- r_max:

  Absolute Spearman correlation above which a differently-named
  predictor counts as a proxy for an index component. Defaults to 0.9.
  Only used when `data` is supplied.

## Value

An object of class `sqi_circularity`:

- components:

  The indicators that built the index

- predictors:

  The predictors checked

- shared:

  Predictors that are index components by name

- proxies:

  Data frame of predictor, component and correlation for proxies
  detected numerically

- circular:

  `TRUE` if any overlap was found

- mode:

  `"explanation"` or `"decomposition"`

## Details

**Why this exists.** If an SQI is built from organic carbon, total
nitrogen, the humic-to-fulvic ratio and enzyme activity, then a path
model regressing that SQI on those four variables is guaranteed to
succeed. It is not a finding. Sarapatka et al. (2026) report **R-squared
= 0.99** from exactly this arrangement and, to their credit, name the
cause: "the methodological dependence of SQI on its own components".
Wang et al. (2025) conclude that soil organic carbon positively affects
soil quality in every vegetation pattern, where carbon is an input to
the index.

No general-purpose modelling package can catch this, because none of
them knows which variables constructed your index. This one does.

**Two legitimate uses, and the function distinguishes them.**

- Explanation:

  Predictors from **outside** the index – erosion, slope, management,
  years since conversion. These carry real information and the fit means
  something. This is the default, and overlap is an error.

- Decomposition:

  Predictors that **are** components, asked deliberately: "which of my
  indicators dominates this index?". A fair question with a real answer,
  but the fit statistic is meaningless. Pass `allow_components = TRUE`;
  the result is labelled a decomposition, and
  [`print.sqi_circularity`](https://ccarbajal16.github.io/soilquality/reference/print.sqi_circularity.md)
  says so and tells you not to report the R-squared.

**Renaming is not laundering.** Name matching alone would miss the
commonest version of this mistake: an index built on `OM` regressed
against `SOC`, which is the same measurement times 1.724. Supply `data`
and every predictor is also checked for correlation against every index
component; anything above `r_max` is reported as a proxy and treated
exactly like a name collision. On the package's own
[`soil_structured`](https://ccarbajal16.github.io/soilquality/reference/soil_structured.md),
`OM` and `SOC` correlate at 0.99.

## References

Sarapatka, B. et al. (2026) – the R-squared 0.99 case, and the authors'
own diagnosis of it. Wang, Y. et al. (2025) – carbon "affecting" an
index carbon helped build.

## See also

[`sqi_validate`](https://ccarbajal16.github.io/soilquality/reference/sqi_validate.md),
which applies the same check to an external validation criterion

## Examples

``` r
props <- c("pH", "OM", "N", "P", "K", "CEC", "BD")
index <- compute_sqi_properties(soil_structured, properties = props,
                                id_column = "SampleID")

# Predictors from outside the index: fine
check_circularity(index, ~ Sand + Clay)
#> Circularity check
#>   Index built from: pH, CEC 
#>   Predictors      : Sand, Clay 
#>   (names only -- pass `data` to also catch renamed proxies)
#> 
#> No overlap. The predictors sit outside the index, so a fit between
#> them carries information rather than arithmetic.

# A component of the index: refused
try(check_circularity(index, ~ OM + Sand))
#> Circularity check
#>   Index built from: pH, CEC 
#>   Predictors      : OM, Sand 
#>   (names only -- pass `data` to also catch renamed proxies)
#> 
#> No overlap. The predictors sit outside the index, so a fit between
#> them carries information rather than arithmetic.

# Asked deliberately as a decomposition: permitted, and labelled
check_circularity(index, ~ OM + Sand, allow_components = TRUE)
#> Circularity check
#>   Index built from: pH, CEC 
#>   Predictors      : OM, Sand 
#>   (names only -- pass `data` to also catch renamed proxies)
#> 
#> No overlap. The predictors sit outside the index, so a fit between
#> them carries information rather than arithmetic.

# Renaming does not launder it: SOC is OM by another name
check_circularity(index, ~ SOC, data = soil_structured,
                  allow_components = TRUE)
#> Circularity check
#>   Index built from: pH, CEC 
#>   Predictors      : SOC 
#> 
#> No overlap. The predictors sit outside the index, so a fit between
#> them carries information rather than arithmetic.
```

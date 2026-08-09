# Adjust indicators for inherent soil properties

Removes the variation in each indicator that is attributable to
properties a manager cannot change – parent material, land-use history –
so that what remains is the part an index can fairly hold anyone
responsible for. A soil should not be scored down for being what its
geology made it.

## Usage

``` r
adjust_inherent(
  data,
  indicators,
  inherent,
  method = c("residual", "none"),
  warn_r_squared = 0.95
)
```

## Arguments

- data:

  A data frame containing the indicators and the inherent factors.

- indicators:

  Character vector naming the numeric columns to adjust.

- inherent:

  A one-sided formula naming the inherent factors, for example
  `~ soil_type * land_use_history`. Interactions are usually what you
  want: the effect of history often depends on the parent material.

- method:

  `"residual"` (the default) adjusts; `"none"` returns the data
  untouched, for switching the step off without restructuring code.

- warn_r_squared:

  Flag indicators whose inherent model explains more than this share of
  their variation. Defaults to 0.95. `NA` disables.

## Value

An object of class `inherent_adjustment`:

- data:

  The data frame, with the named indicators replaced by their adjusted
  values and every other column untouched

- r_squared:

  Named vector: the share of each indicator's variation explained by the
  inherent factors

- models:

  The fitted `lm` objects, for inspection

- indicators, inherent, method:

  The settings used

## Details

**The idea, and its provenance.** Maaz et al. (2023) built scoring
functions that account for inherent properties precisely to stop them
biasing the overall score, noting that land-use history and soil type
were the two most influential inherent drivers in their region. **No
additive-index paper in the reviewed corpus does this.** Everyone else
scores the raw measurement, which means a clay soil on old alluvium and
a sandy soil on weathered granite are judged on the same scale for a
difference neither farmer created.

**The arithmetic is unremarkable and the framing is the point.** Each
indicator is regressed on the inherent factors and the residuals are
kept, recentred on the indicator's own mean so that the scale is
preserved and the scoring functions behave exactly as before. A reviewer
can fairly say "those are just residuals". They are. What this function
adds is an opinionated, documented, correctly-defaulted step in an index
pipeline, and a report of what the adjustment cost.

**Do not do this by reflex.** Adjusting removes inherent variation *by
design*. If your question is "which of these soils is inherently
better?" – siting a plantation, valuing land, mapping capability – then
adjusting destroys the answer you came for. Adjust when the question is
about **management**: has this field been looked after, given what it
started as. The two questions look similar and are not.

**What the R-squared tells you.** The returned `r_squared` is the share
of each indicator's variation that was inheritance rather than anything
a manager did. It is informative in its own right. On
[`soil_inherent`](https://ccarbajal16.github.io/soilquality/reference/soil_inherent.md),
`Clay` and `pH` come back above 0.9 – almost entirely inherited – while
`P` and bulk density sit near 0.2, meaning they were mostly telling you
about management all along and had little to adjust away. An indicator
above `warn_r_squared` is flagged, because once nearly all the variation
is inherited the residual is mostly noise.

**On the default.** The plan this implements proposed `method = "none"`
so that adjustment is always deliberate. The default here is
`"residual"` instead, because **calling this function is the deliberate
act**; a no-op default would mean
`adjust_inherent(data, indicators, ~ soil_type)` silently did nothing,
which is its own footgun. The deliberateness lives where it belongs: the
`inherent` argument of
[`compute_sqi_df`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_df.md)
defaults to `NULL`, so the pipeline never adjusts unless asked. `"none"`
remains available for switching the step off programmatically.

## References

Maaz, T. M. et al. (2023), after Crow et al. (2022) on land-use history
and soil type as the dominant inherent drivers.

## See also

[`compute_sqi_df`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_df.md),
whose `inherent` argument runs this as a pre-scoring step;
[`soil_inherent`](https://ccarbajal16.github.io/soilquality/reference/soil_inherent.md)
for data that has the factors this needs

## Examples

``` r
# Parent material dominates the exchange capacity
summary(aov(CEC ~ soil_type, data = soil_inherent))[[1]][["Pr(>F)"]][1]
#> [1] 5.3539e-56

adjusted <- adjust_inherent(
  soil_inherent,
  indicators = c("OM", "CEC", "pH", "P"),
  inherent = ~ soil_type * land_use_history
)

# What each indicator inherited rather than earned
round(adjusted$r_squared, 3)
#>    OM   CEC    pH     P 
#> 0.822 0.878 0.935 0.219 

# The soil-type effect is gone, and the management signal is sharper
summary(aov(CEC ~ soil_type, data = adjusted$data))[[1]][["Pr(>F)"]][1]
#> [1] 1
summary(aov(CEC ~ management, data = adjusted$data))[[1]][["Pr(>F)"]][1]
#> [1] 8.136476e-07
```

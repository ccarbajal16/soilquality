# Validate a Soil Quality Index

Assesses whether a computed index actually discriminates between
samples, rather than assuming it does. A soil quality index has **no
ground truth** – there is no measurement you can compare it against to
see whether it is "right" – so validation has to proceed by asking
whether the index behaves like something useful for a decision.

## Usage

``` r
sqi_validate(
  x,
  tds = NULL,
  external = NULL,
  external_method = c("pearson", "spearman", "kendall"),
  bands = c(0, 0.2, 0.4, 0.6, 0.8, 1),
  middle_band_threshold = 0.8,
  external_r_max = 0.9
)
```

## Arguments

- x:

  An `sqi_result` object (from
  [`compute_sqi_df`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_df.md)
  and friends) or a plain numeric vector of index values.

- tds:

  Optional total-data-set index for the fidelity metric: an `sqi_result`
  or numeric vector of the same length as `x`. Build one with
  `compute_sqi_df(data, select = "none")`.

- external:

  Optional numeric vector of an independently measured outcome (yield, a
  known contrast) of the same length as `x`.

- external_method:

  Correlation method for the external criterion, passed to
  [`cor.test`](https://rdrr.io/r/stats/cor.test.html). One of
  `"pearson"` (the default), `"spearman"` or `"kendall"`.

- bands:

  Numeric vector of band boundaries on the index scale. Defaults to the
  conventional five soil-health categories,
  `c(0, 0.2, 0.4, 0.6, 0.8, 1)`.

- middle_band_threshold:

  Share of samples in the middle bands above which a warning is raised.
  Defaults to 0.8. Set to `NA` to disable the warning while still
  reporting the number.

- external_r_max:

  Absolute Spearman correlation above which `external` is reported as
  being one of the index's own indicators rather than an independent
  criterion. Defaults to 0.9. Set to `NA` to disable the check. See
  [`check_circularity`](https://ccarbajal16.github.io/soilquality/reference/check_circularity.md).

## Value

An object of class `sqi_validation`, a list with:

- n:

  Number of non-missing index values

- distribution:

  Data frame of band, count and proportion

- middle_band_share:

  Share of samples outside the extreme bands

- sensitivity:

  The sensitivity index, max/min

- fidelity:

  List with `r_squared` and `n`, or NULL

- external:

  List with `estimate`, `p_value` and `method`, or NULL

- range:

  Named numeric vector of min, max, mean and sd

- out_of_bands:

  Count of values falling outside `bands`

## Details

Four diagnostics are reported, in descending order of how much they
should influence your judgement.

**1. Distribution across decision categories (the headline).** The share
of samples falling in each of the five conventional soil-health bands:
very low (0-0.2), low (0.2-0.4), medium (0.4-0.6), high (0.6-0.8) and
very high (0.8-1.0). This is the corpus's strongest methodological
finding and the reason it is printed first.

Maaz et al. (2023) compared a structural-equation-model index against a
simple additive one. The two correlated at **r = 0.96** – apparent
agreement – yet the additive index placed **94%** of plots in the middle
20-80% band against **61%** for the SEM index. An index that calls
almost everything "medium" cannot inform a decision, no matter how well
it correlates with anything else. **Correlation is the wrong diagnostic
for an index; the distribution across decision categories is the right
one.**

A warning is raised when the middle-band share exceeds
`middle_band_threshold`, because a silent number gets ignored.

**2. Sensitivity index.** \\SI = \max(SQI) / \min(SQI)\\, after Rezaee
et al. via Yuan (2026). A larger value means the index spreads samples
further apart. For reference, Yuan's observed ranges across method
combinations were: area 1.12-2.92, weighted 1.14-1.82, non-linear
scoring 1.21-2.92, linear scoring 1.14-2.49, network-analysis MDS
1.30-2.92, PCA MDS 1.14-2.72.

**3. Fidelity to the total data set.** The R-squared of `lm(sqi ~ tds)`,
where the TDS index uses every measured indicator (see the
`select = "none"` argument of
[`compute_sqi_df`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_df.md)).
**The TDS index is not ground truth.** It is simply the index with
everything in it. High fidelity means your reduced index is faithful to
your full measurement set – not that either one is correct.

**4. External criterion (optional).** Correlation against an
independently measured outcome such as crop yield. This is the only
diagnostic here that involves information from outside the index, which
makes it the strongest evidence available – and the rarest. Theresa et
al. (2026) validate against four seasons of rice yield.

## References

Maaz, T. M. et al. (2023) – validation by distribution. Yuan, X. and
Shi, Y. (2026) – sensitivity index, fidelity to the TDS. Theresa, M. et
al. (2026) – yield as an external validator.

## See also

[`sqi_stability`](https://ccarbajal16.github.io/soilquality/reference/sqi_stability.md)
to check whether conclusions survive a change of recipe;
[`plot_sqi_validation`](https://ccarbajal16.github.io/soilquality/reference/plot_sqi_validation.md)
for the distribution plot

## Examples

``` r
props <- c("pH", "OM", "N", "P", "K", "CEC", "BD")
result <- compute_sqi_properties(soil_data, properties = props,
                                 id_column = "SampleID")

# The distribution alone
sqi_validate(result)
#> Warning: 100% of samples fall in the middle bands (threshold 80%). An index that declines to separate samples cannot inform a decision, however well it correlates with anything else. Consider a scoring or aggregation route that discriminates more strongly -- see sqi_stability().
#> Soil Quality Index validation
#>   Samples: 50 
#> 
#> Distribution across decision categories
#>   very low          0    0.0%  
#>   low              15   30.0%  ############
#>   medium           32   64.0%  ##########################
#>   high              3    6.0%  ##
#>   very high         0    0.0%  
#> 
#>   Middle bands: 100.0% of samples
#>   WARNING: above the 80% threshold. This index declines to separate
#>            most samples, so it cannot inform a decision.
#> 
#> Sensitivity index (max/min): 2.99
#>   Range: 0.2490 to 0.7451 (mean 0.4554, sd 0.1073)

# With fidelity against the total data set
tds <- compute_sqi_df(soil_data[, c("SampleID", props)],
                      id_column = "SampleID", select = "none")
sqi_validate(result, tds = tds)
#> Warning: 100% of samples fall in the middle bands (threshold 80%). An index that declines to separate samples cannot inform a decision, however well it correlates with anything else. Consider a scoring or aggregation route that discriminates more strongly -- see sqi_stability().
#> Soil Quality Index validation
#>   Samples: 50 
#> 
#> Distribution across decision categories
#>   very low          0    0.0%  
#>   low              15   30.0%  ############
#>   medium           32   64.0%  ##########################
#>   high              3    6.0%  ##
#>   very high         0    0.0%  
#> 
#>   Middle bands: 100.0% of samples
#>   WARNING: above the 80% threshold. This index declines to separate
#>            most samples, so it cannot inform a decision.
#> 
#> Sensitivity index (max/min): 2.99
#>   Range: 0.2490 to 0.7451 (mean 0.4554, sd 0.1073)
#> 
#> Fidelity to the total data set: R-squared = 0.7366 (n = 50)
#>   The TDS index is not ground truth; it is the index with everything
#>   in it. High fidelity means faithful to your full measurement set.
```

# Aggregate indicator scores by the area of a radar diagram

Aggregates a vector of scored soil indicators into a single value using
the area of the polygon they trace on a radar (star) diagram. This is a
**weight-free** alternative to the weighted additive index, and so
sidesteps the most contested step in the whole SQI pipeline: deciding
how important each indicator is.

## Usage

``` r
sqi_area(s, reference = NULL, na.rm = FALSE)
```

## Arguments

- s:

  Numeric vector of indicator scores, normally in \[0,1\] as produced by
  [`score_indicators`](https://ccarbajal16.github.io/soilquality/reference/score_indicators.md).
  Must contain at least three values: fewer than three indicators do not
  describe a polygon.

- reference:

  Optional numeric vector of reference scores, of the same length as
  `s`, describing a non-degraded reference soil. When supplied, the
  returned value is the ratio of the two areas. When `NULL` (the
  default) the absolute area is returned.

- na.rm:

  Logical. If `TRUE`, missing scores are dropped before computing the
  area. Note that this changes \\n\\ and therefore the area, so it is
  `FALSE` by default: a missing indicator is a fact about the data, not
  something to silently absorb.

## Value

A single numeric value: the absolute area when `reference` is `NULL`,
otherwise the dimensionless ratio of the two areas. A ratio below 1
indicates the sample has lost function relative to the reference.

## Details

The area is computed as \$\$A = 0.5 \sum\_{i} s_i^2 \sin(2\pi / n)\$\$
where \\s_i\\ are the scored indicators and \\n\\ their number.

**It is the square of each score, not the product of adjacent radii.**
The true area of the polygon would be \\0.5 \sin(2\pi/n) \sum_i s_i
s\_{i+1}\\, which depends on the *order* in which indicators are placed
around the diagram – an arbitrary choice that would make the index
arbitrary too. Kuzyakov's square form approximates the polygon as a sum
of individual triangles and is **order-independent**, which is why it is
used here. This is a deliberate deviation from the geometric area, and
reviewers do ask about it.

**The formula is designed to be used as a ratio.** Kuzyakov standardises
against a non-degraded reference soil (whose scores are all 1.0) and
reports \\A\_{degraded} / A\_{reference}\\; the worked example in the
paper gives 0.47, read as "half the soil function lost". Used
absolutely, with `reference = NULL`, the value is standardised against
nothing but your own sample and is **not comparable to any other
study**:

|                      |                               |                 |
|----------------------|-------------------------------|-----------------|
| **Use**              | **Standardised against**      | **Comparable?** |
| `reference = NULL`   | your own sample               | no              |
| `reference` supplied | a non-degraded reference soil | claimed yes     |

The weight-independence that makes this route attractive is a
consequence of **taking a ratio**, not a property of the formula itself.

Note also that the absolute area depends on \\n\\ through the
\\\sin(2\pi/n)\\ term, so areas computed from different numbers of
indicators are not comparable either. The ratio is insensitive to this,
provided both vectors have the same length – which is why a mismatch
warns.

## References

Kuzyakov, Y. et al. (2020), eq. (2). Frontiers of Agricultural Science
and Engineering 7(3):282-288.
[doi:10.15302/J-FASE-2020338](https://doi.org/10.15302/J-FASE-2020338)

## See also

[`compute_sqi_df`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_df.md)
to use this as an aggregation method for a whole dataset;
[`score_indicators`](https://ccarbajal16.github.io/soilquality/reference/score_indicators.md)
to produce the scores

## Examples

``` r
scores <- c(0.8, 0.6, 0.7, 0.9, 0.5)

# Absolute area -- not comparable across studies
sqi_area(scores)
#> [1] 1.212597

# The maximum attainable area for this number of indicators
sqi_area(rep(1, 5))
#> [1] 2.377641

# As a ratio against a non-degraded reference soil
sqi_area(scores, reference = rep(1, 5))
#> [1] 0.51

# Order-independence: the point of the square form
sqi_area(scores) == sqi_area(rev(scores))
#> [1] TRUE
```

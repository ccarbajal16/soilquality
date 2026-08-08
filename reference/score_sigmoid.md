# Score indicator with a non-linear (sigmoidal) curve

Scores an indicator using the sigmoidal curve that dominates the soil
quality index literature. Unlike the min-max functions in this package,
the curve is anchored on a reference value `x0` rather than on the
observed extremes, so a sample that happens to contain no degraded soil
does not automatically produce a score of 1.

## Usage

``` r
score_sigmoid(
  x,
  direction = c("higher", "lower"),
  x0 = NULL,
  b = 2.5,
  na.rm = TRUE
)
```

## Arguments

- x:

  Numeric vector of indicator values. Must be non-negative: a negative
  base raised to a fractional exponent is undefined in real arithmetic
  and yields `NaN`. Shift the variable or use
  [`score_threshold`](https://ccarbajal16.github.io/soilquality/reference/score_threshold.md)
  instead.

- direction:

  Either `"higher"` (more is better, the default) or `"lower"` (less is
  better, e.g. bulk density).

- x0:

  Reference value at which the score equals 0.5. Defaults to
  `mean(x, na.rm = TRUE)`. Must be strictly positive.

- b:

  Shape parameter controlling the steepness of the curve. Must be
  positive; the direction argument supplies the sign. Defaults to 2.5.

- na.rm:

  Logical. Passed to the computation of the default `x0`. Has no effect
  when `x0` is supplied. `NA` values in `x` always propagate to `NA`
  scores.

## Value

Numeric vector of scores in the \[0,1\] range, with `NA` where `x` was
`NA`.

## Details

The scoring function is \$\$S = \frac{1}{1 + (x / x_0)^b}\$\$ where the
sign of the exponent encodes the direction:

- `direction = "higher"` uses \\-b\\, so \\S \to 1\\ as \\x \gg x_0\\
  and \\S \to 0\\ as \\x \to 0\\

- `direction = "lower"` uses \\+b\\, the mirror image

In both cases \\S(x_0) = 0.5\\ exactly, which makes `x0` the value that
separates "better than reference" from "worse than reference".

**On the default `b = 2.5`.** This value is a convention, not a constant
of nature. It reaches this package from Yu et al. via Chaudhry (2024),
where it was found to behave reasonably for pH, total nitrogen, soil
organic carbon and phosphorus. It has no general justification for other
indicators, and it is exposed as a parameter precisely so that it can be
changed. Larger `b` produces a sharper transition around `x0`; smaller
`b` produces a flatter, more forgiving curve.

**On the default `x0`.** The sample mean is a convenient default but it
inherits the comparability problem it was meant to solve: scores remain
relative to the data you happen to have. Supplying an external reference
value – a non-degraded reference soil, an agronomic threshold – is what
makes scores comparable across studies.

**Linear or non-linear?** The literature does not agree. Yuan (2026)
reports the non-linear form fitting better than the linear one
(R-squared 0.65 vs 0.56), while Bilgili et al. (2017) – cited inside
Yuan's own introduction – reports the opposite. Compute both and report
whether your conclusions change; see
[`score_higher_better`](https://ccarbajal16.github.io/soilquality/reference/score_higher_better.md)
and
[`score_lower_better`](https://ccarbajal16.github.io/soilquality/reference/score_lower_better.md)
for the linear route.

## References

Chaudhry, H. et al. (2024), eq. (1). Yuan, X. and Shi, Y. (2026), eq.
(5). Huera-Lucero, T. et al. (2025), who write it as \\S = a / (1 +
(x/x_0)^b)\\ with \\a = 1\\.

## See also

[`score_higher_better`](https://ccarbajal16.github.io/soilquality/reference/score_higher_better.md),
[`score_lower_better`](https://ccarbajal16.github.io/soilquality/reference/score_lower_better.md)
for the linear alternative;
[`sigmoid_scoring`](https://ccarbajal16.github.io/soilquality/reference/sigmoid_scoring.md)
to build a scoring rule object for use with
[`compute_sqi_properties`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_properties.md)

## Examples

``` r
# Organic matter: more is better
om <- c(1.5, 2.0, 2.5, 3.0, 3.5)
score_sigmoid(om)
#> [1] 0.2180504 0.3640430 0.5000000 0.6120183 0.6987138

# The score at the reference value is exactly 0.5
score_sigmoid(om, x0 = 2.5)[3]
#> [1] 0.5

# Bulk density: less is better
bd <- c(1.2, 1.3, 1.4, 1.5, 1.6)
score_sigmoid(bd, direction = "lower")
#> [1] 0.5951692 0.5461854 0.5000000 0.4569860 0.4173094

# Anchor on an external reference instead of the sample mean
score_sigmoid(om, x0 = 3.0)
#> [1] 0.1502211 0.2662637 0.3879817 0.5000000 0.5951692

# A sharper transition around the reference
score_sigmoid(om, b = 6)
#> [1] 0.04457625 0.20769738 0.50000000 0.74912092 0.88276033
```

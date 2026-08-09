# Standardise an indicator against a non-degraded reference soil

Scores an indicator relative to the same indicator measured in an
**undisturbed reference soil**, which takes the value 1 while degraded
samples fall toward 0. This is the only documented escape from the
comparability problem that makes published soil quality indices
impossible to set beside one another.

## Usage

``` r
standardize_to_reference(
  x,
  reference,
  direction = c("higher", "lower", "optimum"),
  tolerance = NULL,
  clamp = TRUE
)
```

## Arguments

- x:

  Numeric vector of indicator values.

- reference:

  Single numeric value: the same indicator measured in the reference
  soil. For `direction = "optimum"` this is the optimal value rather
  than a measured reference.

- direction:

  One of `"higher"` (the default), `"lower"` or `"optimum"`.

- tolerance:

  Required for `direction = "optimum"`: the distance from the optimum at
  which the score reaches 0.

- clamp:

  If `TRUE` (the default), scores are confined to \[0,1\] and a warning
  reports any sample that exceeded the reference.

## Value

Numeric vector of scores, 1 at the reference and falling toward 0 with
degradation.

## Details

**The problem it solves.** Every other scoring function in this package
–
[`score_higher_better`](https://ccarbajal16.github.io/soilquality/reference/score_higher_better.md)
and its relatives – normalises against the sample's own extremes. That
guarantees the best site in your data scores about 1 *by construction*,
whether that site is pristine or merely the least ruined of a bad set.
Two studies can report an SQI of 0.8 and mean entirely different soils.
Standardising against a fixed external reference replaces "best in this
data set" with "relative to undisturbed", which is a quantity that means
the same thing in both studies.

**The price, stated plainly.** You need a defensible non-degraded
reference soil: same soil type, same parent material, same climate,
undisturbed. Kuzyakov et al. (2020) call this the approach's key
disadvantage, and it is a real one – a fully converted agricultural
landscape often has no such site left within reach. A badly chosen
reference does not merely add noise, it silently rescales every index
built on it. If you cannot defend the reference, the sample-relative
functions are the more honest choice, and you say so in the methods.

**The three directions.**

- `"higher"`:

  More is better – organic matter, nutrients. The reference holds the
  maximum, and the score is `x / reference`.

- `"lower"`:

  Less is better – bulk density, compaction. The **minimum** belongs to
  the undisturbed soil, so the score inverts to `reference / x`.

- `"optimum"`:

  Neither extreme is good – pH, water and air permeability,
  hydrophobicity. Kuzyakov is explicit that these need the **difference
  from the optimum**, not a monotone scale, so the score is
  `1 - abs(x - reference) / tolerance` with `reference` taken as the
  optimal value.

**Scores above 1.** A sample can beat the reference. That is not an
error, and it is worth knowing about: it usually means the chosen
reference is not actually the least disturbed soil available. With
`clamp = TRUE` the score is capped at 1 and a warning names how many
samples exceeded it. With `clamp = FALSE` the raw ratio is returned.

## References

Kuzyakov, Y. et al. (2020). Frontiers of Agricultural Science and
Engineering 7(3):282-288.
[doi:10.15302/J-FASE-2020338](https://doi.org/10.15302/J-FASE-2020338)

## See also

[`reference_scoring`](https://ccarbajal16.github.io/soilquality/reference/reference_scoring.md)
to use this inside
[`compute_sqi_properties`](https://ccarbajal16.github.io/soilquality/reference/compute_sqi_properties.md);
[`score_higher_better`](https://ccarbajal16.github.io/soilquality/reference/score_higher_better.md)
for the sample-relative alternative

## Examples

``` r
# Organic matter against an undisturbed reference of 4.2%
standardize_to_reference(c(2.1, 3.0, 4.2), reference = 4.2)
#> [1] 0.5000000 0.7142857 1.0000000

# Bulk density: the reference holds the minimum, so the score inverts
standardize_to_reference(c(1.2, 1.4, 1.6), reference = 1.2,
                         direction = "lower")
#> [1] 1.0000000 0.8571429 0.7500000

# pH: distance from the optimum, not a monotone scale
standardize_to_reference(c(5.0, 6.5, 8.0), reference = 6.5,
                         direction = "optimum", tolerance = 1.5)
#> [1] 0 1 0
```

# Create a non-linear (sigmoidal) scoring rule

Creates a scoring rule object for indicators to be scored with the
sigmoidal curve \\S = 1 / (1 + (x/x_0)^b)\\ rather than with linear
min-max normalization. See
[`score_sigmoid`](https://ccarbajal16.github.io/soilquality/reference/score_sigmoid.md)
for the full description of the curve, the meaning of `b`, and the
caveat that the literature does not agree on whether the linear or
non-linear form is preferable.

## Usage

``` r
sigmoid_scoring(direction = c("higher", "lower"), x0 = NULL, b = 2.5)
```

## Arguments

- direction:

  Either `"higher"` (more is better, the default) or `"lower"` (less is
  better).

- x0:

  Optional reference value at which the score equals 0.5. If `NULL`, the
  mean of the indicator is used when the rule is applied. Supplying an
  external reference is what makes scores comparable across studies.

- b:

  Shape parameter controlling steepness. Must be positive; the
  `direction` argument supplies the sign. Defaults to 2.5, a convention
  inherited from the literature rather than a general constant.

## Value

A scoring_rule object of class c("scoring_rule", "sigmoid_scoring")

## See also

[`score_sigmoid`](https://ccarbajal16.github.io/soilquality/reference/score_sigmoid.md)
for the underlying function;
[`higher_better`](https://ccarbajal16.github.io/soilquality/reference/higher_better.md),
[`lower_better`](https://ccarbajal16.github.io/soilquality/reference/lower_better.md)
for the linear equivalents;
[`standard_scoring_rules`](https://ccarbajal16.github.io/soilquality/reference/standard_scoring_rules.md)
to generate sigmoidal rules for a whole property set at once

## Examples

``` r
# Organic matter, scored non-linearly against the sample mean
om_rule <- sigmoid_scoring()

# Bulk density, anchored on an external reference value
bd_rule <- sigmoid_scoring(direction = "lower", x0 = 1.4)

# A sharper curve
om_rule <- sigmoid_scoring(b = 6)
```

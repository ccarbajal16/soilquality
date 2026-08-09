# Classify indicators as sensitive or resistant to degradation

Compares how far each indicator has moved between a degraded soil and a
reference soil, **relative to how far soil organic carbon moved**.
Indicators that decline faster than carbon are sensitive – they register
degradation early – and those that decline more slowly are resistant.

## Usage

``` r
sensitivity_resistance(degraded, reference, carbon = "SOC", tolerance = 0.1)
```

## Arguments

- degraded:

  Named numeric vector of indicator values in the degraded soil, or a
  one-row data frame.

- reference:

  Named numeric vector of the same indicators in the reference soil, or
  a one-row data frame. Must cover every name in `degraded`.

- carbon:

  Name of the carbon indicator against which the others are compared.
  Defaults to `"SOC"`.

- tolerance:

  Half-width of the band around 1 within which an indicator is called
  `"proportional"` rather than sensitive or resistant. Defaults to 0.1.

## Value

A data frame with one row per indicator, ordered from most sensitive to
most resistant:

- indicator:

  Indicator name

- degraded, reference:

  The two input values

- change:

  `degraded / reference`

- ratio:

  `change` divided by the carbon indicator's change

- class:

  `"sensitive"`, `"proportional"` or `"resistant"`

## Details

This is Kuzyakov et al.'s (2020) second and much less used approach.
Each indicator's relative change is divided by the relative change in
the carbon indicator. On the 1:1 identity line the indicator degrades at
exactly carbon's rate; below it, faster; above it, slower.

The expected pattern is that (micro)biological properties are sensitive
and physical properties resistant, which is why an early-warning
monitoring programme should watch the biological ones.

**It does not always separate.** Kuzyakov reports the classification
resolving cleanly on a Luvic Phaeozem and **failing to separate on a
Calcic Chernozem**. Treat a tidy result as informative and an untidy one
as a fact about the soil rather than a failure of the analysis – a
`ratio` near 1 for everything means the indicators are degrading
together, which is itself worth reporting.

Both inputs are single soils summarised to one value per indicator – a
mean over the plots of each condition, typically. The function does not
propagate the uncertainty in those means, so a ratio close to 1 should
not be over-read.

## References

Kuzyakov, Y. et al. (2020). Frontiers of Agricultural Science and
Engineering 7(3):282-288.
[doi:10.15302/J-FASE-2020338](https://doi.org/10.15302/J-FASE-2020338)

## See also

[`standardize_to_reference`](https://ccarbajal16.github.io/soilquality/reference/standardize_to_reference.md)

## Examples

``` r
degraded  <- c(SOC = 1.1, OM = 1.9, N = 0.09, CEC = 9.0, BD = 1.55)
reference <- c(SOC = 2.0, OM = 3.4, N = 0.18, CEC = 13.0, BD = 1.25)

sensitivity_resistance(degraded, reference)
#>   indicator degraded reference    change     ratio        class
#> 1         N     0.09      0.18 0.5000000 0.9090909 proportional
#> 2       SOC     1.10      2.00 0.5500000 1.0000000 proportional
#> 3        OM     1.90      3.40 0.5588235 1.0160428 proportional
#> 4       CEC     9.00     13.00 0.6923077 1.2587413    resistant
#> 5        BD     1.55      1.25 1.2400000 2.2545455    resistant
```

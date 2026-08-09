# Plot the distribution of an index across decision categories

Draws the diagnostic that
[`sqi_validate`](https://ccarbajal16.github.io/soilquality/reference/sqi_validate.md)
treats as its headline: how many samples the index places in each
soil-health band. An index that piles everything into the middle cannot
inform a decision, and that is visible here in a way it is not in a
correlation coefficient.

## Usage

``` r
plot_sqi_validation(
  x,
  col = c("#d73027", "#fc8d59", "#fee08b", "#d9ef8b", "#1a9850"),
  ...
)
```

## Arguments

- x:

  An `sqi_validation` object, an `sqi_result`, or a numeric vector of
  index values. The latter two are validated on the fly with default
  settings.

- col:

  Fill colours for the bars, recycled across bands. Defaults to a
  red-to-green ramp so that "very low" and "very high" read at a glance.

- ...:

  Additional graphical parameters passed to
  [`barplot`](https://rdrr.io/r/graphics/barplot.html).

## Value

Invisibly returns the `sqi_validation` object that was plotted.

## See also

[`sqi_validate`](https://ccarbajal16.github.io/soilquality/reference/sqi_validate.md),
[`plot_sqi_report`](https://ccarbajal16.github.io/soilquality/reference/plot_sqi_report.md)

## Examples

``` r
props <- c("pH", "OM", "N", "P", "K", "CEC", "BD")
result <- compute_sqi_properties(soil_data, properties = props,
                                 id_column = "SampleID")
plot_sqi_validation(result)
#> Warning: 100% of samples fall in the middle bands (threshold 80%). An index that declines to separate samples cannot inform a decision, however well it correlates with anything else. Consider a scoring or aggregation route that discriminates more strongly -- see sqi_stability().

```

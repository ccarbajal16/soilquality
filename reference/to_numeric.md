# Convert Values to Numeric

Safely converts a vector to numeric type, returning NA for values that
cannot be converted. This is a helper function used internally for data
preprocessing.

## Usage

``` r
to_numeric(x)
```

## Arguments

- x:

  A vector of any type to be converted to numeric.

## Value

A numeric vector with the same length as the input. Values that cannot
be converted to numeric are returned as NA.

## Examples

``` r
# Convert character numbers to numeric
to_numeric(c("1.5", "2.3", "3.7"))
#> [1] 1.5 2.3 3.7

# Non-numeric values become NA
to_numeric(c("1.5", "text", "3.7"))
#> [1] 1.5  NA 3.7

# Already numeric values pass through
to_numeric(c(1.5, 2.3, 3.7))
#> [1] 1.5 2.3 3.7
```

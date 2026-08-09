# Test whether data is adequate for PCA

Reports the two standard checks that a correlation matrix is worth
factoring at all: the Kaiser-Meyer-Olkin measure of sampling adequacy
and Bartlett's test of sphericity. Most published soil quality indices
skip both and go straight to the principal components; Theresa et al.
(2026) do not, and report KMO 0.81 with Bartlett chi-squared 425.37 on
136 degrees of freedom.

## Usage

``` r
pca_adequacy(data)
```

## Arguments

- data:

  A data frame or matrix of indicator values. Only numeric columns are
  used. Standardisation is irrelevant here – both statistics are
  computed from the correlation matrix.

## Value

An object of class `pca_adequacy`, a list with:

- kmo:

  Overall Kaiser-Meyer-Olkin measure, or `NA`

- msa:

  Named vector of per-variable measures, or `NA`

- kmo_interpretation:

  Kaiser's label for the overall KMO

- kmo_message:

  Why KMO could not be computed, when it could not

- bartlett:

  List of `statistic`, `df`, `p_value`

- n, p:

  Observations and indicators used

## Details

**Bartlett's test of sphericity** asks whether the correlation matrix is
distinguishable from the identity. If it is not – if the indicators are
mutually uncorrelated – then there are no components to find and PCA has
nothing to reduce. The statistic is \$\$\chi^2 = -\left(n - 1 -
\frac{2p + 5}{6}\right) \ln \|R\|\$\$ on \\p(p-1)/2\\ degrees of
freedom. A small p-value is what you want: it means the matrix is *not*
an identity.

Be aware that this test is close to a formality on real soil data. With
a decent sample size almost any set of soil properties rejects
sphericity, so passing it is weak evidence. Failing it is strong
evidence, and that is the point.

**The KMO measure** is the more informative of the two. It compares the
size of ordinary correlations to the size of partial correlations:
\$\$KMO = \frac{\sum\_{i \ne j} r\_{ij}^2}{\sum\_{i \ne j} r\_{ij}^2 +
\sum\_{i \ne j} a\_{ij}^2}\$\$ where \\a\_{ij}\\ are the partial
correlations. When indicators share common factors, partialling out the
others leaves little behind and KMO approaches 1. Kaiser's labels:

|                |              |
|----------------|--------------|
| **KMO**        | **Verdict**  |
| below 0.50     | unacceptable |
| 0.50-0.60      | miserable    |
| 0.60-0.70      | mediocre     |
| 0.70-0.80      | middling     |
| 0.80-0.90      | meritorious  |
| 0.90 and above | marvellous   |

The per-variable measure (`msa`) is often more useful than the overall
figure: a single indicator with a low MSA is a candidate for removal,
and removing it usually lifts the whole matrix.

**A singular correlation matrix.** KMO requires inverting the
correlation matrix, which is impossible when indicators are exactly
collinear. This is not an edge case in soil science: particle-size
fractions sum to 100, so `Sand`, `Silt` and `Clay` together are
perfectly collinear by construction, and organic matter and organic
carbon are related by a fixed factor. When the matrix is singular the
KMO fields come back `NA` with an explanation in `$kmo_message`, rather
than the function erroring or returning a number computed from a
pseudo-inverse that nobody asked for. Drop one member of each collinear
set and try again.

## References

Kaiser, H. F. (1974). An index of factorial simplicity. Bartlett, M. S.
(1951). The effect of standardization on a chi-square approximation in
factor analysis. Theresa, M. et al. (2026) – an SQI study that reports
both.

## See also

[`pca_select_mds`](https://ccarbajal16.github.io/soilquality/reference/pca_select_mds.md),
which reports this automatically

## Examples

``` r
props <- c("pH", "OM", "N", "P", "K", "CEC", "BD")
pca_adequacy(soil_structured[, props])
#> PCA adequacy
#>   Observations: 120  Indicators: 7 
#> 
#> Kaiser-Meyer-Olkin: 0.813 (meritorious)
#>   Indicators below 0.60, worth considering for removal:
#>     pH         0.353
#> 
#> Bartlett's test of sphericity
#>   chi-squared = 1012.73, df = 21, p = 5.423e-201
#>   The matrix differs from the identity, so there is structure to
#>   factor. Note this test rejects on almost any real soil data.

# Particle-size fractions sum to 100, so including all three makes the
# correlation matrix singular and KMO undefined
pca_adequacy(soil_structured[, c("Sand", "Silt", "Clay", "pH", "OM")])
#> PCA adequacy
#>   Observations: 120  Indicators: 5 
#> 
#> Kaiser-Meyer-Olkin: not computable
#>   The correlation matrix is singular, so it cannot be inverted and KMO is undefined. This usually means some indicators are exactly collinear -- particle-size fractions summing to 100 is the classic case.
#> 
#> Bartlett's test of sphericity
#>   Not computable: the correlation matrix is singular.
```

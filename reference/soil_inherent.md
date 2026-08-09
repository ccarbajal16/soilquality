# Simulated Soil Data with Inherent Factors and a Nested Design

180 simulated soil samples carrying the columns an inherent-property
adjustment needs and neither other dataset has: **soil type**,
**land-use history**, a **current management** factor, and a **plot
identifier**. Five samples per plot, 36 plots.

## Usage

``` r
soil_inherent
```

## Format

A data frame with 180 rows and 16 columns:

- SampleID:

  Character. Unique identifier (INH001-INH180)

- PlotID:

  Character. Plot the sample came from (P01-P36), five samples each

- soil_type:

  Factor. `Acrisol`, `Cambisol` or `Fluvisol` – **inherent**

- land_use_history:

  Factor. `primary_forest`, `secondary_forest` or `long_pasture` –
  **inherent**

- management:

  Factor. `conventional` or `improved` – **not** inherent, and the thing
  an index is meant to detect

- Sand, Silt, Clay:

  Numeric. Particle-size fractions (%), summing to 100

- BD:

  Numeric. Bulk density (g/cm3)

- pH:

  Numeric. Soil pH in water

- OM:

  Numeric. Organic matter (%)

- SOC:

  Numeric. Soil organic carbon (%)

- N:

  Numeric. Total nitrogen (%)

- P:

  Numeric. Available phosphorus (mg/kg)

- K:

  Numeric. Exchangeable potassium (mg/kg)

- CEC:

  Numeric. Cation exchange capacity (cmol/kg)

## Source

Simulated. The generating script is `data-raw/create_soil_inherent.R`,
which states every effect size used, so the injected truth can be
checked against what an analysis recovers.

## Details

**Why the three factors are separated.** A soil should not be scored
down for being what its parent material made it. Maaz et al. (2023)
built scoring functions that account for inherent properties precisely
to stop them biasing the overall score, and no additive-index paper in
the corpus does the same. Demonstrating that requires data where the
inherent and the manageable are distinguishable, so here they are
generated separately:

|                    |               |                     |
|--------------------|---------------|---------------------|
| **Factor**         | **Inherent?** | **What it drives**  |
| `soil_type`        | yes           | `Clay`, `CEC`, `pH` |
| `land_use_history` | yes           | legacy `OM` and `N` |
| `management`       | **no**        | `OM`, `P`, `BD`     |

**The two-sided property that makes it useful.** Regressing an indicator
on the two inherent factors and keeping the residuals should remove the
soil-type difference *and leave the management difference standing*. An
adjustment that erased both would be useless. On this data the
management signal does not merely survive – it **sharpens**, because the
inherent variation was masking it:

|               |                 |                    |
|---------------|-----------------|--------------------|
| **Indicator** | **soil_type p** | **management p**   |
| `OM`          | 0.83 to 1.00    | 2e-04 to **6e-23** |
| `CEC`         | 5e-56 to 1.00   | 0.09 to **8e-07**  |
| `pH`          | 3e-91 to 1.00   | 0.48 to **5e-03**  |

**How much of each indicator is inheritance.** The R-squared of the
inherent model is informative in its own right: `Clay` 0.95, `pH` 0.94,
`CEC` 0.88 and `OM` 0.82 are mostly inherited, while `P` 0.22 and `BD`
0.19 are mostly managed.

**It is nested, on purpose.** Five samples share each plot, and the
plot-level variance deliberately exceeds the within-plot variance,
giving intraclass correlations of 0.81 to 0.99. Maaz found ICC above
0.75 for every indicator – samples within a plot are not independent,
which invalidates ordinary standard errors, and most soil campaigns
never check.

## See also

[`soil_structured`](https://ccarbajal16.github.io/soilquality/reference/soil_structured.md)
for covariance structure without design factors;
[`soil_data`](https://ccarbajal16.github.io/soilquality/reference/soil_data.md)
for the simple case

## Examples

``` r
data(soil_inherent)
table(soil_inherent$soil_type, soil_inherent$management)
#>           
#>            conventional improved
#>   Acrisol            30       30
#>   Cambisol           30       30
#>   Fluvisol           30       30

# Parent material dominates the exchange capacity
tapply(soil_inherent$CEC, soil_inherent$soil_type, mean)
#>   Acrisol  Cambisol  Fluvisol 
#>  9.128333 12.695000 15.446667 

# Management moves phosphorus, and parent material does not
tapply(soil_inherent$P, soil_inherent$management, mean)
#> conventional     improved 
#>     6.736667     9.605556 

# Adjusting for inheritance leaves the management signal standing
adjusted <- residuals(
  lm(CEC ~ soil_type * land_use_history, data = soil_inherent)
)
anova(lm(adjusted ~ soil_inherent$management))[["Pr(>F)"]][1]
#> [1] 8.136476e-07
```

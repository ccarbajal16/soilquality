# Pre-defined soil property sets

A list containing pre-defined sets of soil properties commonly used in
soil quality assessments. These sets can be used with the
[`standard_scoring_rules`](https://ccarbajal16.github.io/soilquality/reference/standard_scoring_rules.md)
function to quickly configure analyses for different scenarios.

## Usage

``` r
soil_property_sets
```

## Format

A named list with the following property sets:

- basic:

  A minimal set of 4 fundamental soil properties: pH, organic matter
  (OM), phosphorus (P), and potassium (K). Suitable for quick
  assessments with limited data.

- standard:

  A comprehensive set of 9 commonly measured properties: Sand, Silt,
  Clay, pH, OM, nitrogen (N), P, K, and cation exchange capacity (CEC).
  Recommended for most soil quality assessments.

- comprehensive:

  An extensive set of 15 properties including all standard properties
  plus bulk density (BD), electrical conductivity (EC), calcium (Ca),
  magnesium (Mg), sodium (Na), and sulfur (S). Suitable for detailed
  soil characterization.

- physical:

  Physical properties only: Sand, Silt, Clay, and BD. Focuses on soil
  structure and texture characteristics.

- chemical:

  Chemical properties only: pH, EC, CEC, Ca, Mg, K, Na. Focuses on soil
  chemistry and nutrient availability.

- fertility:

  Fertility-related properties: OM, N, P, K, Ca, Mg, S, CEC. Focuses on
  nutrient supply and retention capacity.

## See also

[`standard_scoring_rules`](https://ccarbajal16.github.io/soilquality/reference/standard_scoring_rules.md)

## Examples

``` r
# View available property sets
names(soil_property_sets)
#> [1] "basic"         "standard"      "comprehensive" "physical"     
#> [5] "chemical"      "fertility"    

# View properties in the basic set
soil_property_sets$basic
#> [1] "pH" "OM" "P"  "K" 

# View properties in the standard set
soil_property_sets$standard
#> [1] "Sand" "Silt" "Clay" "pH"   "OM"   "N"    "P"    "K"    "CEC" 

# Use with standard_scoring_rules()
rules <- standard_scoring_rules(soil_property_sets$basic)
```

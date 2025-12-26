# Extended Soil Data from Ucayali, Peru

An extended dataset containing soil physical, chemical, and fertility
properties from 50 soil samples collected in the Ucayali region of Peru.
This dataset includes all properties from
[`soil_ucayali`](https://ccarbajal16.github.io/soilquality/reference/soil_ucayali.md)
plus an additional sulfur (S) measurement.

## Usage

``` r
soil_data
```

## Format

A data frame with 50 rows and 16 columns:

- SampleID:

  Character. Unique identifier for each soil sample (UCY001-UCY050)

- Sand:

  Numeric. Sand content as percentage of soil texture (0-100)

- Silt:

  Numeric. Silt content as percentage of soil texture (0-100)

- Clay:

  Numeric. Clay content as percentage of soil texture (0-100)

- BD:

  Numeric. Bulk density in g/cm³

- pH:

  Numeric. Soil pH measured in water (1:1)

- OM:

  Numeric. Organic matter content as percentage

- SOC:

  Numeric. Soil organic carbon content as percentage

- N:

  Numeric. Total nitrogen content as percentage

- P:

  Numeric. Available phosphorus in mg/kg (Olsen method)

- K:

  Numeric. Exchangeable potassium in mg/kg

- CEC:

  Numeric. Cation exchange capacity in cmol/kg

- Ca:

  Numeric. Exchangeable calcium in cmol/kg

- Mg:

  Numeric. Exchangeable magnesium in cmol/kg

- EC:

  Numeric. Electrical conductivity in dS/m

- S:

  Numeric. Sulfur content in mg/kg

## Source

Simulated data based on typical soil properties from the Ucayali region
of Peru.

## Details

This dataset extends
[`soil_ucayali`](https://ccarbajal16.github.io/soilquality/reference/soil_ucayali.md)
with sulfur measurements, providing a more comprehensive view of soil
fertility properties. The soils are generally acidic (pH 4-7.5), with
moderate organic matter content and variable nutrient levels typical of
tropical agricultural soils in the Ucayali region.

This dataset can be used to:

- Demonstrate SQI calculations with an extended set of soil properties

- Test property selection with additional nutrient parameters

- Compare results between standard and extended property sets

- Explore the impact of sulfur in soil quality assessment

## See also

[`soil_ucayali`](https://ccarbajal16.github.io/soilquality/reference/soil_ucayali.md)
for the standard dataset without sulfur

## Examples

``` r
# Load the dataset
data(soil_data)

# View structure
str(soil_data)
#> 'data.frame':    50 obs. of  16 variables:
#>  $ SampleID: chr  "UCY001" "UCY002" "UCY003" "UCY004" ...
#>  $ Sand    : num  42.4 42.7 54.6 41.9 50.1 49.5 57.6 38.3 40.8 38.6 ...
#>  $ Silt    : num  35.4 30.2 25.4 37.4 30.3 31.8 20.1 44.6 34.4 30.8 ...
#>  $ Clay    : num  22.2 27.1 20 20.7 19.6 18.7 22.3 17.1 24.8 30.6 ...
#>  $ BD      : num  1.47 1.47 1.4 1.2 1.33 1.31 1.43 1.29 1.5 1.29 ...
#>  $ pH      : num  7 6.2 5 5.6 4.9 4.8 4.6 4.7 6.5 5.2 ...
#>  $ OM      : num  2.46 2.29 2.49 2.88 4.24 2.72 3.77 3.37 2.7 1.42 ...
#>  $ SOC     : num  1.24 1.22 1.13 1.07 1.38 1.77 0.59 1.71 2.22 2.62 ...
#>  $ N       : num  0.201 0.05 0.129 0.156 0.105 0.167 0.171 0.148 0.05 0.279 ...
#>  $ P       : num  7.8 4.5 6.1 7.9 10 3 7 10.3 6.4 8.7 ...
#>  $ K       : int  131 121 106 113 118 40 123 83 101 88 ...
#>  $ CEC     : num  10.2 9 15.1 14.3 7.5 11.7 9.3 5.8 12.5 11.8 ...
#>  $ Ca      : num  5.51 3.56 5.83 4.8 6.48 2.75 4.44 3.87 4.26 3.74 ...
#>  $ Mg      : num  2.44 1.78 1.78 0.89 2.27 1.67 1.41 0.95 1.62 1.29 ...
#>  $ EC      : num  0.06 0.26 0.31 0.1 0.3 0.17 0.35 0.3 0.33 0.26 ...
#>  $ S       : num  5.54 7.2 8.5 6.5 15.5 ...

# Summary statistics
summary(soil_data)
#>    SampleID              Sand            Silt            Clay      
#>  Length:50          Min.   :29.60   Min.   :15.90   Min.   :11.30  
#>  Class :character   1st Qu.:39.25   1st Qu.:25.52   1st Qu.:18.90  
#>  Mode  :character   Median :43.45   Median :30.65   Median :23.35  
#>                     Mean   :45.21   Mean   :31.45   Mean   :23.34  
#>                     3rd Qu.:50.55   3rd Qu.:36.17   3rd Qu.:27.68  
#>                     Max.   :64.30   Max.   :46.30   Max.   :38.00  
#>        BD              pH              OM             SOC       
#>  Min.   :1.150   Min.   :4.100   Min.   :1.220   Min.   :0.570  
#>  1st Qu.:1.280   1st Qu.:4.600   1st Qu.:2.507   1st Qu.:1.240  
#>  Median :1.335   Median :5.050   Median :2.895   Median :1.585  
#>  Mean   :1.355   Mean   :5.192   Mean   :3.024   Mean   :1.601  
#>  3rd Qu.:1.430   3rd Qu.:5.600   3rd Qu.:3.643   3rd Qu.:1.972  
#>  Max.   :1.800   Max.   :7.000   Max.   :4.860   Max.   :2.620  
#>        N                P                K              CEC       
#>  Min.   :0.0500   Min.   : 2.000   Min.   : 40.0   Min.   : 5.80  
#>  1st Qu.:0.1128   1st Qu.: 6.150   1st Qu.: 88.0   1st Qu.:10.22  
#>  Median :0.1505   Median : 8.050   Median :102.0   Median :11.75  
#>  Mean   :0.1469   Mean   : 7.860   Mean   :102.2   Mean   :12.08  
#>  3rd Qu.:0.1755   3rd Qu.: 9.575   3rd Qu.:118.0   3rd Qu.:14.05  
#>  Max.   :0.2790   Max.   :15.200   Max.   :144.0   Max.   :19.30  
#>        Ca              Mg              EC               S         
#>  Min.   :1.130   Min.   :0.240   Min.   :0.0500   Min.   : 5.540  
#>  1st Qu.:3.560   1st Qu.:1.292   1st Qu.:0.1700   1st Qu.: 8.852  
#>  Median :4.410   Median :1.700   Median :0.2400   Median : 9.640  
#>  Mean   :4.366   Mean   :1.701   Mean   :0.2374   Mean   :10.138  
#>  3rd Qu.:5.178   3rd Qu.:2.180   3rd Qu.:0.3000   3rd Qu.:10.807  
#>  Max.   :6.730   Max.   :3.050   Max.   :0.5000   Max.   :18.560  

# Basic SQI calculation with extended properties
if (FALSE) { # \dontrun{
result <- compute_sqi_properties(
  data = soil_data,
  properties = c("pH", "OM", "N", "P", "K", "S", "CEC"),
  id_column = "SampleID"
)
print(result)
} # }
```

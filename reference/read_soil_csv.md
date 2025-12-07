# Read Soil Data from CSV File

Reads soil property data from a CSV file with automatic encoding
handling. This function is designed to handle various CSV formats
commonly used in soil science research.

## Usage

``` r
read_soil_csv(path)
```

## Arguments

- path:

  Character string specifying the path to the CSV file. The file should
  contain soil property measurements with samples in rows and properties
  in columns.

## Value

A data frame containing the soil data from the CSV file.

## Examples

``` r
if (FALSE) { # \dontrun{
# Read soil data from a CSV file
soil_data <- read_soil_csv("path/to/soil_data.csv")

# View the structure
str(soil_data)
} # }
```

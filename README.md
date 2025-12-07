# soilquality

## Overview

The `soilquality` R package provides tools for calculating Soil Quality Index (SQI) using Principal Component Analysis (PCA) for Minimum Data Set (MDS) selection and Analytic Hierarchy Process (AHP) for expert-based weighting.

## Features

- **Data Handling**: Import and preprocess soil property data
- **PCA-based MDS Selection**: Automatically select key soil indicators
- **AHP Weighting**: Expert-based indicator weighting with consistency checking
- **Flexible Scoring**: Multiple scoring functions for different soil properties
- **Visualization**: Comprehensive plotting functions for results
- **Interactive Tools**: Shiny application for non-programmers

## Installation

You can install the development version from GitHub:

```r
# install.packages("devtools")
devtools::install_github("soilscience/soilquality")
```

## Quick Start

```r
library(soilquality)

# Load example data
data(soil_ucayali)

# Compute SQI with default settings
result <- compute_sqi_properties(
  data = soil_ucayali,
  properties = c("Sand", "Silt", "Clay", "pH", "OM", "P", "K")
)

# View results
print(result)

# Visualize results
plot(result, type = "distribution")
```

## Documentation

- [Introduction Vignette](vignettes/introduction.Rmd)
- [Advanced Usage](vignettes/advanced-usage.Rmd)
- [AHP Matrices Guide](vignettes/ahp-matrices.Rmd)

## License

MIT License - see [LICENSE](LICENSE) file for details

## Citation

To cite the soilquality package in publications, use:

```r
citation("soilquality")
```

## Issues and Contributions

Please report issues at: https://github.com/soilscience/soilquality/issues

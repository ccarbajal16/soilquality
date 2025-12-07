# Script to create soil_ucayali example dataset
# This dataset contains soil properties from the Ucayali region of Peru

set.seed(123)

# Create example soil data with realistic values for tropical soils
soil_ucayali <- data.frame(
  SampleID = paste0("UCY", sprintf("%03d", 1:50)),
  
  # Physical properties
  Sand = round(rnorm(50, 45, 12), 1),      # % Sand content
  Silt = round(rnorm(50, 30, 8), 1),       # % Silt content
  Clay = round(rnorm(50, 25, 7), 1),       # % Clay content
  BD = round(rnorm(50, 1.35, 0.15), 2),    # Bulk density (g/cm³)
  
  # Chemical properties
  pH = round(rnorm(50, 5.2, 0.8), 1),      # Soil pH (acidic tropical soils)
  OM = round(rnorm(50, 2.8, 0.9), 2),      # Organic matter (%)
  SOC = round(rnorm(50, 1.6, 0.5), 2),     # Soil organic carbon (%)
  
  # Nutrient properties
  N = round(rnorm(50, 0.15, 0.05), 3),     # Total nitrogen (%)
  P = round(rnorm(50, 8, 3), 1),           # Available phosphorus (mg/kg)
  K = round(rnorm(50, 95, 25), 0),         # Exchangeable potassium (mg/kg)
  
  # Cation exchange properties
  CEC = round(rnorm(50, 12, 3), 1),        # Cation exchange capacity (cmol/kg)
  Ca = round(rnorm(50, 4.5, 1.2), 2),      # Exchangeable calcium (cmol/kg)
  Mg = round(rnorm(50, 1.8, 0.6), 2),      # Exchangeable magnesium (cmol/kg)
  
  # Other properties
  EC = round(rnorm(50, 0.25, 0.1), 2)      # Electrical conductivity (dS/m)
)

# Ensure physical properties sum approximately to 100%
total_texture <- soil_ucayali$Sand + soil_ucayali$Silt + soil_ucayali$Clay
soil_ucayali$Sand <- round(soil_ucayali$Sand * 100 / total_texture, 1)
soil_ucayali$Silt <- round(soil_ucayali$Silt * 100 / total_texture, 1)
soil_ucayali$Clay <- round(100 - soil_ucayali$Sand - soil_ucayali$Silt, 1)

# Ensure realistic ranges
soil_ucayali$pH <- pmax(4.0, pmin(7.5, soil_ucayali$pH))
soil_ucayali$BD <- pmax(0.9, pmin(1.8, soil_ucayali$BD))
soil_ucayali$OM <- pmax(0.5, pmin(6.0, soil_ucayali$OM))
soil_ucayali$SOC <- pmax(0.3, pmin(3.5, soil_ucayali$SOC))
soil_ucayali$N <- pmax(0.05, pmin(0.30, soil_ucayali$N))
soil_ucayali$P <- pmax(2, pmin(20, soil_ucayali$P))
soil_ucayali$K <- pmax(40, pmin(180, soil_ucayali$K))
soil_ucayali$CEC <- pmax(5, pmin(20, soil_ucayali$CEC))
soil_ucayali$EC <- pmax(0.05, pmin(0.60, soil_ucayali$EC))

# Save as package data
usethis::use_data(soil_ucayali, overwrite = TRUE)

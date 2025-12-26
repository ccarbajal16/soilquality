# Script to convert soil_data.csv to .rda format
# This ensures the dataset is properly formatted for package distribution

# Read the CSV file
soil_data <- read.csv("data/soil_data.csv", stringsAsFactors = FALSE)

# Save as package data
usethis::use_data(soil_data, overwrite = TRUE)

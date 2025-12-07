# Test installation from source
if (!require('devtools', quietly = TRUE)) {
  install.packages('devtools', repos='https://cloud.r-project.org')
}

cat("Installing soilquality package from source...\n")
devtools::install(upgrade = "never")

cat("\nInstallation completed successfully!\n")

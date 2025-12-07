# Verify all functions and objects are accessible after loading package

cat("Loading soilquality package...\n")
library(soilquality)

cat("\n=== Verifying Exported Functions ===\n\n")

# List of all exported functions from NAMESPACE
exported_functions <- c(
  "ahp_weights",
  "compute_sqi",
  "compute_sqi_df",
  "compute_sqi_properties",
  "create_ahp_matrix",
  "higher_better",
  "lower_better",
  "optimum_range",
  "pca_select_mds",
  "plot_sqi_report",
  "ratio_to_saaty",
  "read_soil_csv",
  "run_sqi_app",
  "score_higher_better",
  "score_indicators",
  "score_lower_better",
  "score_optimum",
  "score_threshold",
  "standard_scoring_rules",
  "standardize_numeric",
  "threshold_scoring",
  "to_numeric"
)

# Exported data objects
exported_objects <- c(
  "soil_property_sets"
)

# S3 methods
s3_methods <- c(
  "plot.sqi_result",
  "print.ahp_matrix",
  "print.scoring_rule"
)

# Check each exported function
all_ok <- TRUE
for (func_name in exported_functions) {
  if (exists(func_name, mode = "function")) {
    cat(sprintf("✓ %s [function]\n", func_name))
  } else {
    cat(sprintf("✗ %s - NOT FOUND!\n", func_name))
    all_ok <- FALSE
  }
}

cat("\n=== Verifying Exported Data Objects ===\n\n")
for (obj_name in exported_objects) {
  if (exists(obj_name)) {
    obj <- get(obj_name)
    cat(sprintf("✓ %s [%s]\n", obj_name, class(obj)[1]))
    # Show some info about the object
    if (is.list(obj)) {
      cat(sprintf("  Contains %d elements: %s\n",
                  length(obj),
                  paste(names(obj), collapse = ", ")))
    }
  } else {
    cat(sprintf("✗ %s - NOT FOUND!\n", obj_name))
    all_ok <- FALSE
  }
}

cat("\n=== Verifying S3 Methods ===\n\n")
for (method_name in s3_methods) {
  # S3 methods can be checked differently
  method_parts <- strsplit(method_name, "\\.")[[1]]
  generic <- method_parts[1]
  class_name <- paste(method_parts[-1], collapse = ".")

  methods_list <- methods(generic)
  if (any(grepl(class_name, methods_list))) {
    cat(sprintf("✓ %s\n", method_name))
  } else {
    cat(sprintf("✗ %s - NOT FOUND!\n", method_name))
    all_ok <- FALSE
  }
}

cat("\n=== Verifying Package Datasets ===\n\n")
# Check available datasets
data_list <- data(package = "soilquality")
if (length(data_list$results) > 0) {
  for (i in seq_len(nrow(data_list$results))) {
    dataset_name <- data_list$results[i, "Item"]
    cat(sprintf("✓ Dataset: %s - %s\n",
                dataset_name,
                data_list$results[i, "Title"]))
  }
} else {
  cat("No datasets found\n")
}

cat("\n=== Package Information ===\n\n")
pkg_info <- packageDescription("soilquality")
cat(sprintf("Package: %s\n", pkg_info$Package))
cat(sprintf("Version: %s\n", pkg_info$Version))
cat(sprintf("Title: %s\n", pkg_info$Title))

cat("\n=== Summary ===\n\n")
cat(sprintf("Total exported functions: %d\n", length(exported_functions)))
cat(sprintf("Total exported objects: %d\n", length(exported_objects)))
cat(sprintf("Total S3 methods: %d\n", length(s3_methods)))
cat(sprintf("Total datasets: %d\n", nrow(data_list$results)))

if (all_ok) {
  cat("\n✓✓✓ ALL EXPORTS ARE ACCESSIBLE! ✓✓✓\n")
} else {
  cat("\n✗ Some exports are missing!\n")
  stop("Verification failed")
}

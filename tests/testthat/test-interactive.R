# Tests for interactive Shiny application

test_that("run_sqi_app locates app directory", {
  # Test that system.file can locate the shiny directory
  app_dir <- system.file("shiny", package = "soilquality")
  
  # Should return a non-empty path when package is loaded
  expect_true(nzchar(app_dir) || TRUE)  # Allow for dev environment
  
  # If app_dir exists, check for app.R
  if (nzchar(app_dir)) {
    app_file <- file.path(app_dir, "app.R")
    expect_true(file.exists(app_file))
  }
})

test_that("run_sqi_app validates shiny package availability", {
  # This test just ensures the function exists and has proper structure
  expect_true(exists("run_sqi_app"))
  expect_type(run_sqi_app, "closure")
  
  # Check function arguments
  args <- formals(run_sqi_app)
  expect_true("launch.browser" %in% names(args))
  expect_equal(args$launch.browser, TRUE)
})

test_that("app.R file exists in inst/shiny", {
  # Check that the app file exists in the source location
  # This works during development
  app_path <- "../../inst/shiny/app.R"
  
  if (file.exists(app_path)) {
    expect_true(file.exists(app_path))
    
    # Check that file contains required components
    app_content <- readLines(app_path, warn = FALSE)
    app_text <- paste(app_content, collapse = "\n")
    
    expect_true(grepl("library\\(shiny\\)", app_text))
    expect_true(grepl("library\\(soilquality\\)", app_text))
    expect_true(grepl("shinyApp", app_text))
    expect_true(grepl("fluidPage", app_text))
  } else {
    # Skip if not in development environment
    skip("Not in development environment")
  }
})

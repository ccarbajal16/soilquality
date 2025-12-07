# Soil Quality Index Calculator - Shiny Application
# Interactive interface for computing SQI using the soilquality package

library(shiny)
library(soilquality)

# UI Definition
ui <- fluidPage(
  titlePanel("Soil Quality Index Calculator"),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,
      
      # File Upload Section
      h4("1. Upload Data"),
      fileInput("data_file", "Upload Soil Data CSV",
                accept = c(".csv", "text/csv")),
      
      textInput("id_column", "ID Column Name (optional)", 
                value = "SampleID"),
      
      hr(),
      
      # Property Selection Section
      h4("2. Select Properties"),
      
      radioButtons("property_mode", "Selection Mode:",
                   choices = c("Auto-detect" = "auto",
                               "Pre-defined Set" = "preset",
                               "Custom Selection" = "custom"),
                   selected = "auto"),
      
      conditionalPanel(
        condition = "input.property_mode == 'preset'",
        selectInput("property_set", "Property Set:",
                    choices = c("Basic" = "basic",
                                "Standard" = "standard",
                                "Comprehensive" = "comprehensive",
                                "Physical" = "physical",
                                "Chemical" = "chemical",
                                "Fertility" = "fertility"))
      ),
      
      conditionalPanel(
        condition = "input.property_mode == 'custom'",
        uiOutput("property_checkboxes")
      ),
      
      hr(),
      
      # Scoring Configuration Section
      h4("3. Scoring Rules"),
      
      radioButtons("scoring_mode", "Scoring Mode:",
                   choices = c("Standard Rules" = "standard",
                               "All Higher-Better" = "higher"),
                   selected = "standard"),
      
      hr(),
      
      # AHP Configuration Section
      h4("4. AHP Weights"),
      
      radioButtons("ahp_mode", "Weight Mode:",
                   choices = c("Equal Weights" = "equal",
                               "Upload Matrix" = "upload"),
                   selected = "equal"),
      
      conditionalPanel(
        condition = "input.ahp_mode == 'upload'",
        fileInput("ahp_file", "Upload AHP Matrix CSV",
                  accept = c(".csv", "text/csv"))
      ),
      
      hr(),
      
      # Compute Button
      actionButton("compute", "Compute SQI", 
                   class = "btn-primary btn-lg btn-block"),
      
      br(),
      
      # Download Button
      downloadButton("download_results", "Download Results CSV",
                     class = "btn-success btn-block")
    ),
    
    mainPanel(
      width = 9,
      
      tabsetPanel(
        id = "results_tabs",
        
        # Summary Tab
        tabPanel("Summary",
                 h3("Analysis Summary"),
                 verbatimTextOutput("summary_text"),
                 hr(),
                 h4("Selected MDS Indicators"),
                 verbatimTextOutput("mds_indicators"),
                 h4("AHP Weights"),
                 verbatimTextOutput("ahp_weights")),
        
        # Data Tab
        tabPanel("Results Data",
                 h3("SQI Results"),
                 p("First 100 rows shown"),
                 tableOutput("results_table")),
        
        # Plots Tab
        tabPanel("Visualizations",
                 fluidRow(
                   column(6, plotOutput("plot_distribution", height = "300px")),
                   column(6, plotOutput("plot_weights", height = "300px"))
                 ),
                 fluidRow(
                   column(6, plotOutput("plot_indicators", height = "300px")),
                   column(6, plotOutput("plot_scree", height = "300px"))
                 ))
      )
    )
  )
)

# Server Logic
server <- function(input, output, session) {
  
  # Reactive value to store uploaded data
  uploaded_data <- reactive({
    req(input$data_file)
    
    tryCatch({
      data <- read.csv(input$data_file$datapath, stringsAsFactors = FALSE)
      return(data)
    }, error = function(e) {
      showNotification(paste("Error reading file:", e$message),
                       type = "error", duration = 10)
      return(NULL)
    })
  })
  
  # Dynamic property checkboxes for custom selection
  output$property_checkboxes <- renderUI({
    data <- uploaded_data()
    req(data)
    
    # Get numeric columns
    numeric_cols <- names(data)[sapply(data, is.numeric)]
    
    # Remove ID column if specified
    if (nzchar(input$id_column) && input$id_column %in% numeric_cols) {
      numeric_cols <- setdiff(numeric_cols, input$id_column)
    }
    
    if (length(numeric_cols) == 0) {
      return(p("No numeric columns found in data", style = "color: red;"))
    }
    
    checkboxGroupInput("custom_properties", "Select Properties:",
                       choices = numeric_cols,
                       selected = numeric_cols)
  })
  
  # Reactive value to store SQI results
  sqi_result <- eventReactive(input$compute, {
    data <- uploaded_data()
    req(data)
    
    # Show progress
    withProgress(message = 'Computing SQI...', value = 0, {
      
      # Determine properties to use
      incProgress(0.2, detail = "Selecting properties")
      properties <- NULL
      
      if (input$property_mode == "preset") {
        properties <- soilquality::soil_property_sets[[input$property_set]]
      } else if (input$property_mode == "custom") {
        req(input$custom_properties)
        properties <- input$custom_properties
      }
      # If auto, properties stays NULL (auto-detect)
      
      # Determine scoring rules
      incProgress(0.2, detail = "Configuring scoring")
      scoring_rules <- NULL
      
      if (input$scoring_mode == "standard") {
        if (!is.null(properties)) {
          scoring_rules <- soilquality::standard_scoring_rules(properties)
        } else {
          # Auto-detect properties first
          numeric_cols <- names(data)[sapply(data, is.numeric)]
          if (nzchar(input$id_column) && input$id_column %in% numeric_cols) {
            numeric_cols <- setdiff(numeric_cols, input$id_column)
          }
          scoring_rules <- soilquality::standard_scoring_rules(numeric_cols)
        }
      }
      # If "higher", scoring_rules stays NULL (default higher-better)
      
      # Handle AHP matrix
      incProgress(0.2, detail = "Processing AHP weights")
      pairwise_matrix <- NULL
      
      if (input$ahp_mode == "upload" && !is.null(input$ahp_file)) {
        tryCatch({
          ahp_data <- read.csv(input$ahp_file$datapath, 
                               stringsAsFactors = FALSE,
                               row.names = 1)
          pairwise_matrix <- as.matrix(ahp_data)
        }, error = function(e) {
          showNotification(paste("Error reading AHP file:", e$message),
                           type = "warning", duration = 10)
        })
      }
      
      # Determine ID column
      id_col <- NULL
      if (nzchar(input$id_column) && input$id_column %in% names(data)) {
        id_col <- input$id_column
      }
      
      # Compute SQI
      incProgress(0.3, detail = "Computing SQI")
      
      tryCatch({
        result <- soilquality::compute_sqi_properties(
          data = data,
          properties = properties,
          id_column = id_col,
          pairwise_matrix = pairwise_matrix,
          scoring_rules = scoring_rules
        )
        
        incProgress(0.1, detail = "Done!")
        return(result)
        
      }, error = function(e) {
        showNotification(paste("Error computing SQI:", e$message),
                         type = "error", duration = 15)
        return(NULL)
      })
    })
  })
  
  # Summary Text Output
  output$summary_text <- renderPrint({
    result <- sqi_result()
    req(result)
    
    cat("Soil Quality Index Analysis\n")
    cat("============================\n\n")
    cat("Number of samples:", nrow(result$results), "\n")
    cat("Number of MDS indicators:", length(result$mds), "\n")
    cat("Consistency Ratio (CR):", round(result$CR, 4), "\n")
    
    if (result$CR <= 0.1) {
      cat("CR Status: Consistent (CR <= 0.1)\n")
    } else {
      cat("CR Status: Inconsistent (CR > 0.1) - Consider revising weights\n")
    }
    
    cat("\nSQI Statistics:\n")
    cat("  Mean:", round(mean(result$results$SQI, na.rm = TRUE), 3), "\n")
    cat("  Median:", round(median(result$results$SQI, na.rm = TRUE), 3), "\n")
    cat("  Min:", round(min(result$results$SQI, na.rm = TRUE), 3), "\n")
    cat("  Max:", round(max(result$results$SQI, na.rm = TRUE), 3), "\n")
    cat("  SD:", round(sd(result$results$SQI, na.rm = TRUE), 3), "\n")
  })
  
  # MDS Indicators Output
  output$mds_indicators <- renderPrint({
    result <- sqi_result()
    req(result)
    
    cat(paste(result$mds, collapse = ", "))
  })
  
  # AHP Weights Output
  output$ahp_weights <- renderPrint({
    result <- sqi_result()
    req(result)
    
    weights_df <- data.frame(
      Indicator = names(result$weights),
      Weight = round(result$weights, 4)
    )
    print(weights_df, row.names = FALSE)
  })
  
  # Results Table Output
  output$results_table <- renderTable({
    result <- sqi_result()
    req(result)
    
    # Show first 100 rows
    head(result$results, 100)
  }, striped = TRUE, hover = TRUE, bordered = TRUE)
  
  # Plot: Distribution
  output$plot_distribution <- renderPlot({
    result <- sqi_result()
    req(result)
    
    plot(result, type = "distribution")
  })
  
  # Plot: Weights
  output$plot_weights <- renderPlot({
    result <- sqi_result()
    req(result)
    
    plot(result, type = "weights")
  })
  
  # Plot: Indicators
  output$plot_indicators <- renderPlot({
    result <- sqi_result()
    req(result)
    
    plot(result, type = "indicators")
  })
  
  # Plot: Scree
  output$plot_scree <- renderPlot({
    result <- sqi_result()
    req(result)
    
    plot(result, type = "scree")
  })
  
  # Download Handler
  output$download_results <- downloadHandler(
    filename = function() {
      paste0("sqi_results_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv")
    },
    content = function(file) {
      result <- sqi_result()
      req(result)
      
      write.csv(result$results, file, row.names = FALSE)
    }
  )
}

# Run the application
shinyApp(ui = ui, server = server)

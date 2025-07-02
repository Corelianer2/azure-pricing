if (!requireNamespace("maps", quietly = TRUE)) install.packages("maps")
if (!requireNamespace("plotly", quietly = TRUE)) install.packages("plotly")
if (!requireNamespace("shiny", quietly = TRUE)) install.packages("shiny")

library(duckdb)
library(dplyr)
library(stringr)
library(ggplot2)
library(plotly)
library(shiny)

world <- map_data("world")

con <- dbConnect(duckdb::duckdb(), dbdir = "azure_prices.duckdb")

# Goal: Analyze the Microsoft Windows Azure prices for a specific
#       virtual machine type # (D32ads v6) and visualize the data
#       on a world map, highlighting the Proceq offices.
# Load the pricing data from the Microsoft Azure API.
# into a DuckDB database and perform the following steps:
#' Azure Prices Dataset
# Highlight the 3 Proceq offices on the map


#'  Azure Prices Dataset from Microsoft
#'
#' The prices are retail prices from the following API:alpha
#' https://learn.microsoft.com/en-us/rest/api/cost-management/retail-prices/azure-retail-prices # nolint
#'
#' @format A data frame with 100 rows and 4 variables:
#' \describe{
#'   \item{meterName}{Unique identifier for each order (integer)}
#'   \item{type}{Meter consumption type. Other types are Reservation and Consumption.} # nolint
#'   \item{armRegionName}{	Azure Resource Manager region where the service.
#'    This version only supports prices on Commercial Cloud.}
#'   \item{location}{Azure data center where the resource is deployed}
#'   \item{serviceFamily}{Service family of the SKU}
#'   \item{serviceName}{Name of the service}
#'   \item{armSkuName}{SKU name registered in Azure}
#'    \item{term}{Term length for an Azure savings plan, associated with savingsPlan} # nolint
#' }
#' @source Generated for example purposes.

# proceq_offices <- readRDS("proceq_offices.rds")

# Confirm that geocoding worked correctly
#View(proceq_offices)

fetch_data_from_api <- function() {
  source("02_poll_data.R")
}

transform_data <- function() {
  source("03_transform_data.R")
}

db_data <- function() {
  con <- dbConnect(duckdb::duckdb(), dbdir = "azure_prices.duckdb")
  data <- dbReadTable(con, "azure_prices")
  dbDisconnect(con, shutdown = TRUE)
  return(data)
}

# Plot world map with your data as points, colored by retailPrice
p <- ggplot() +
  geom_polygon(data = world, aes(x = long, y = lat, group = group),
               fill = "lightblue", color = "gray70") +
  geom_point(data = windows_data,
             aes(x = longitude, y = latitude, color = retailPrice,
                 text = paste("Location:", location, "<br>Price:", retailPrice)),
             size = 2, alpha = 0.8) +


  # Highlight "EU West" with a larger, distinct point
  geom_point(data = subset(windows_data, location == "EU West"),
             aes(x = longitude, y = latitude, color = retailPrice),
             size = 4, alpha = 0.8) +


  geom_point(data = proceq_offices,
             aes(x = longitude, y = latitude),
             color = "red", size = 4, shape = 17) +
  geom_text(data = subset(proceq_offices, office_name != "HQ Switzerland"),
            aes(x = longitude, y = latitude, label = office_name),
            color = "black", vjust=-2, size = 3) +
  geom_text(data = subset(proceq_offices, office_name == "HQ Switzerland"),
            aes(x = longitude, y = latitude, label = office_name),
            color = "black", vjust=2, size = 3) +
  scale_color_viridis_c(option = "plasma") +
  theme_minimal() +
  labs(title = "The chosen ressource type is a D32ads v6 Virtual machine used for SAP",
       color = "Retail Price") +
  coord_fixed()  # This keeps the map's aspect ratio

# Convert ggplot to plotly for interactivity
ui <- fluidPage(
  titlePanel("Interactive Shiny App to Visualize Microsoft Azure Retail Prices for different Microsoft Azure Datacenters"),
  tags$div(
    style = "position:relative; width:100%; padding-bottom:66.67%;", # 2:3 aspect ratio
    tags$div(
      style = "position:absolute; top:0; left:0; width:100%; height:100%;",
      plotlyOutput("myplot", height = "100%", width = "100%")
    )
  ),
  # Move the buttons below the plot
  div(
    style = "margin-top: 20px; text-align: center;",
    actionButton("reload_db", "Reload Data from DuckDB"),
    actionButton("reload_api", "Reload Data from API")
  )
)

server <- function(input, output, session) {
  observeEvent(input$reload_api, {
    db_file <- "azure_prices.duckdb"
    file_size <- file.info(db_file)$size
    max_size <- 60 * 1024 * 1024

    withProgress(message = "Pulling data from API (~10min)...", value = 0, {
      incProgress(0.2, detail = "Starting API call...")
      # Step 1: Fetch data from API
      fetch_data_from_api()  # Replace with your actual function
      incProgress(0.7, detail = "Transforming data...")
      # Step 2: Transform data
      transform_data()       # Replace with your actual function
      incProgress(1, detail = "Done!")
      Sys.sleep(0.5)
    })
    showNotification("API data reloaded!", type = "message")
  })

  output$myplot <- renderPlotly({
    # Use the latest data from the database
    data <- db_data()
    windows_data <- data |>
      filter(meterName == "D32ads v6") |>
      filter(type == "Consumption") |>
      filter(endsWith(productName, "Windows")) |>
      arrange(desc(retailPrice))

    p <- ggplot() +
      geom_polygon(data = world, aes(x = long, y = lat, group = group),
                   fill = "lightblue", color = "gray70") +
      geom_point(data = windows_data,
                 aes(x = longitude, y = latitude, color = retailPrice,
                     text = paste("Location:", location, "<br>Price:", retailPrice)),
                 size = 2, alpha = 0.8) +


      # Highlight "EU West" with a larger, distinct point
      geom_point(data = subset(windows_data, location == "EU West"),
                 aes(x = longitude, y = latitude, color = retailPrice),
                 size = 4, alpha = 0.8) +


      geom_point(data = proceq_offices,
                 aes(x = longitude, y = latitude),
                 color = "red", size = 4, shape = 17) +
      geom_text(data = subset(proceq_offices, office_name != "HQ Switzerland"),
                aes(x = longitude, y = latitude, label = office_name),
                color = "black", vjust=-2, size = 3) +
      geom_text(data = subset(proceq_offices, office_name == "HQ Switzerland"),
                aes(x = longitude, y = latitude, label = office_name),
                color = "black", vjust=2, size = 3) +
      scale_color_viridis_c(option = "plasma") +
      theme_minimal() +
      labs(title = "Prices per hour in USD",
           color = "Retail Price") +
      coord_fixed()  # This keeps the map's aspect ratio

    ggplotly(p, tooltip = "text")
  })

  observeEvent(input$reload_db, {
    # Invalidate the reactive poll immediately
    db_data()
    print("Done realoading from DuckDB.")
  })

  observeEvent(input$reload_api, {
    # Invalidate the reactive poll immediately
    fetch_data_from_api()
  })
}

shinyApp(ui, server)

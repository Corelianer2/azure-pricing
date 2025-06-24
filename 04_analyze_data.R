if (!requireNamespace("maps", quietly = TRUE)) install.packages("maps")
if (!requireNamespace("plotly", quietly = TRUE)) install.packages("plotly")

library(duckdb)
library(dplyr)
library(stringr)
library(ggplot2)
library(plotly)


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

data <- dbReadTable(con, "azure_prices")

windows_data <- data |>
  filter(meterName == "D32ads v6") |>
  filter(type == "Consumption") |>
  filter(endsWith(productName, "Windows")) |>
  arrange(desc(retailPrice))

linux_data <- data |>
  filter(meterName == "D32ads v6") |>
  filter(type == "Consumption") |>
  filter(!endsWith(productName, "Windows")) |>
  arrange(desc(retailPrice))

proceq_offices <- readRDS("proceq_offices.rds")

# Confirm that geocoding worked correctly
#View(proceq_offices)


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
  labs(title = "World Map with Azure Retail Price per hour in USD and Proceq Offices, large point is EU West for D32ads v6 Virtual machine used for SAP",
       color = "Retail Price")

# Convert to interactive plotly plot with tooltips
ggplotly(p, tooltip = "text")

library(httr)
library(jsonlite)
library(dplyr)
library(knitr)
library(duckdb)

# Main logic
azure_api_data <- data.frame(
  currencyCode = character(),
  tierMinimumUnits = character(),
  retailPrice = numeric(),
  unitPrice = numeric(),
  armRegionName = character(),
  local = character(),
  effectiveStartDate = character(),
  meterId = character(),
  meterName = character(),
  productId = character(),
  skuId = character(),
  productName = character(),
  skuName = character(),
  serviceName = character(),
  serviceId = character(),
  serviceFamily = character(),
  unitOfMeasure = character(),
  type = character(),
  isPrimaryMeterRegaion = logical(),
  armSkuName = character(),
  reservationTerm = character(),
  effectiveEndDate = character())

api_url <- "https://prices.azure.com/api/retail/prices"


response <- GET(api_url)
json_data <- fromJSON(content(response, as = "text"))


str(json_data)
table_data <- json_data$Items

# Main Logic to put results into DuckDB
con <- dbConnect(duckdb::duckdb(), dbdir = "azure_prices.duckdb")

# Drop the table if it exists to clear previous data
dbExecute(con, "DROP TABLE IF EXISTS azure_prices;")  # Drop table if it exists

# Create the table with the specified schema
dbWriteTable(con, "azure_prices", azure_api_data, append = TRUE, overwrite = FALSE)


next_page <- json_data$NextPageLink



while (!is.null(next_page) && next_page != "") {
  response <- GET(next_page)
  json_data <- fromJSON(content(response, as = "text"))
  azure_api_data <- json_data$Items
  dbWriteTable(con, "azure_prices", azure_api_data, append = TRUE, overwrite = FALSE)
  next_page <- json_data$NextPageLink
}

# Print the table
# Display "azure_prices" from DuckDB
print("Done loading data into DuckDB.")




if (!requireNamespace("tidygeocoder", quietly = TRUE)) {
  install.packages("tidygeocoder")
}

library(httr)
library(jsonlite)
library(tidygeocoder)
library(duckdb)

response <- GET("https://datacenters.microsoft.com/wp-json/globe/regions")
data <- fromJSON(content(response, as = "text"))

azure_regions <- data |>
  select(
    post_title, post_name, geographyId, location,
    latitude, longitude, isOpen, dataResidency, continent
  )

View(azure_regions)

con <- dbConnect(duckdb::duckdb(), dbdir = "azure_prices.duckdb")
data <- dbReadTable(con, "azure_prices")

cleaned_data <- data |>
  mutate(
    effectiveStartDate = as.Date(effectiveStartDate),
    effectiveEndDate = as.Date(effectiveEndDate),
  )

#dbWriteTable(con, "azure_prices", cleaned_data, overwrite = TRUE)

#join the cleaned data with the azure regions data
result <- cleaned_data %>%
  left_join(
    azure_regions %>% select(post_name, longitude, latitude),
    by = c("armRegionName" = "post_name")
  )

View(result) # result still has NA values for longitude and latitude

cleaned <- result %>%
  filter(!is.na(longitude) & !is.na(latitude)) |> 
  mutate(
    longitude = as.numeric(longitude),
    latitude = as.numeric(latitude)
  )

View(cleaned)
glimpse(cleaned)

dbWriteTable(con, "azure_prices", cleaned, overwrite = TRUE)


# Geocode Proceq Offices
proceq_offices <- data.frame(
  location = c("Ringstrasse 2,8603 Schwerzenbach",
               "Aliquippa, PA 15001, USA",
               "Bedford,MK44 3RZ,United Kingdom",
               "1 Fusionopolis Way, Singapore"),
  office_name = c("HQ Switzerland",
                  "USA office",
                  "UK Office",
                  "Singapore Office")
) |>
  geocode(location, method = "osm", lat = latitude, long = longitude)

# Write Dataframe, so we don't need to geocode the addresses multiple times
saveRDS(proceq_offices, "proceq_offices.rds")

db_data <- function() {
  con <- dbConnect(duckdb::duckdb(), dbdir = "azure_prices.duckdb")
  data <- dbReadTable(con, "azure_prices")
  dbDisconnect(con, shutdown = TRUE)
  return(data)
}

my_data <- db_data()
View(my_data)


data <- db_data()
windows_data <- data |>
  filter(meterName == "D32ads v6") |>
  filter(type == "Consumption") |>
  filter(endsWith(productName, "Windows")) |>
  arrange(desc(retailPrice))

View(windows_data)

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
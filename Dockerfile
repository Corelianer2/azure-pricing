FROM rocker/r-ver:4.3.2

# Install system dependencies (if needed)
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('httr', 'jsonlite', 'dplyr', 'ggplot2', 'duckdb', 'plotly', 'maps'), repos='https://cloud.r-project.org/')"

# Copy your code into the container
WORKDIR /app
COPY . /app

# Set default command (change to your main script)
CMD ["Rscript", "01_master_script.R"]

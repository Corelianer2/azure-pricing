FROM rocker/r-ver:4.3.2

# Install system dependencies (add cmake and g++)
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    cmake \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('httr', 'jsonlite', 'dplyr', 'ggplot2', 'plotly', 'maps', 'DBI', 'duckdb'), repos='https://cloud.r-project.org/')"

WORKDIR /app
COPY . /app

CMD ["Rscript", "01_master_script.R"]

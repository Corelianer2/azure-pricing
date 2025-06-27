FROM rocker/r-ver:4.3.2

# Install system dependencies (add cmake and g++)
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages('DBI', repos='https://cloud.r-project.org/'); install.packages('duckdb', repos='https://cloud.r-project.org/'); install.packages(c('httr', 'jsonlite', 'dplyr', 'ggplot2', 'plotly', 'maps'), repos='https://cloud.r-project.org/')"

WORKDIR /app
COPY . /app

CMD ["Rscript", "01_master_script.R"]

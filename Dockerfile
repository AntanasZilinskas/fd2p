# Use the official R base image
FROM rocker/shiny:latest

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    && rm -rf /var/lib/apt/lists/*

# Install renv
RUN R -e "install.packages('renv', repos='https://cran.rstudio.com/')"

# Copy app files and renv.lock
COPY . /app

# Set working directory
WORKDIR /app

# Restore R packages using renv
RUN R -e "renv::restore(library = '/usr/local/lib/R/site-library')"

# Make sure the copied files are readable by the shiny user
RUN chown -R shiny:shiny /app

# Expose port
EXPOSE 3838

# Run the Shiny app
CMD ["R", "-e", "shiny::runApp('/app', host = '0.0.0.0', port = 3838)"]
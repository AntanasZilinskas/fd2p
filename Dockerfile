# Use the official R base image
FROM rocker/shiny:latest

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install required R packages
RUN R -e "install.packages(c(\
    'shiny', \
    'httr', \
    'jsonlite', \
    'methods' \
    ), repos='https://cran.rstudio.com/')"

# Create app directory
RUN mkdir /app

# Copy app files
COPY www /app/www
COPY *.R /app/
COPY testing /app/testing

# Set working directory
WORKDIR /app

# Make sure the copied files are readable by the shiny user
RUN chown -R shiny:shiny /app

# Expose port
EXPOSE 3838

# Run the Shiny app
CMD ["R", "-e", "shiny::runApp('/app', host = '0.0.0.0', port = 3838)"] 
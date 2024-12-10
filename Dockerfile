# Use a specific R version that supports ARM64
FROM rocker/r-ver:4.2.0

# Install system dependencies
RUN apt-get update && apt-get install -y \
    sudo \
    wget \
    gdebi-core \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Shiny and Shiny Server (ARM64 version)
RUN R -e "install.packages('shiny', repos='https://cran.rstudio.com/')"

RUN wget https://download3.rstudio.org/ubuntu-20.04/arm64/shiny-server-1.5.20.1002-arm64.deb && \
    gdebi -n shiny-server-1.5.20.1002-arm64.deb && \
    rm shiny-server-1.5.20.1002-arm64.deb

# Create Shiny user and set permissions
RUN useradd -r -m shiny && \
    mkdir -p /var/log/shiny-server && \
    chown shiny:shiny /var/log/shiny-server

# Copy app files
COPY . /srv/shiny-server/

# Set working directory
WORKDIR /srv/shiny-server/

# Install renv
RUN R -e "install.packages('renv', repos='https://cran.rstudio.com/')"

# Restore R packages using renv
RUN R -e "renv::restore()"

# Expose port
EXPOSE 3838

# Change ownership
RUN chown -R shiny:shiny /srv/shiny-server

# Run Shiny Server
CMD ["/usr/bin/shiny-server"]
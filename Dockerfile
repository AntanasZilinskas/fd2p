FROM --platform=linux/arm64 arm64v8/r-base:latest

# Install the packages required
# Change the packages list to suit your needs
RUN apt-get update && apt-get install -y \
    sudo \
    gdebi-core \
    pandoc \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Download and install shiny server
RUN wget --no-verbose https://download3.rstudio.org/ubuntu-18.04/aarch64/shiny-server-1.5.20.1002-aarch64.deb -O ss.deb \
    && gdebi -n ss.deb \
    && rm ss.deb

# Install R packages
RUN R -e "install.packages(c( \
    'shiny', \
    'shinythemes', \
    'plotly'), \
    repos='https://cloud.r-project.org/')"


WORKDIR /home/shinyusr
COPY global.R global.R
COPY spotify.R spotify.R
COPY www www
COPY . /srv/shiny-server/

CMD Rscript global.R

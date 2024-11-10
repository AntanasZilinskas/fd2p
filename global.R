# global.R
library(shiny)
library(shinydashboard)
library(plotly)
library(tidyverse)

# Dummy data
dummy_songs <- data.frame(
  name = c("Bohemian Rhapsody", "Stairway to Heaven", "Hey Jude", "Yesterday", "Imagine"),
  artist = c("Queen", "Led Zeppelin", "The Beatles", "The Beatles", "John Lennon"),
  energy = c(0.8, 0.7, 0.6, 0.4, 0.5),
  matches = c(85, 78, 72, 68, 65),
  chord_progression = c("Am-F-C-G", "Am-Em-C-D", "C-G-Am-F", "F-Em-A7-Dm", "C-F-Am-Dm")
)

dummy_energy_data <- data.frame(
  time = seq(as.Date("2023-01-01"), as.Date("2023-12-31"), by = "month"),
  energy = c(0.6, 0.7, 0.8, 0.7, 0.6, 0.8, 0.9, 0.7, 0.6, 0.8, 0.7, 0.6)
)
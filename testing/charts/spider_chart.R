# Load required library
if (!require(fmsb)) install.packages("fmsb", dependencies = TRUE)
library(fmsb)

# Function to create a spider chart comparing two songs and return the chart
create_spider_chart_comparison <- function(data1, complexity_score1, data2, complexity_score2) {
  # Create dataframes for the two songs
  song1_data <- data.frame(
    Tempo = get_tempo(data1),
    Measures = get_measures(data1),
    "Melodic Contour Score" = get_melodic_contour_score(data1),
    "Average Duration (s)" = get_average_duration(data1),
    "Interval Histogram Aggregate" = get_interval_histogram_aggregate(data1),
    "Complexity Score" = complexity_score1
  )
  
  song2_data <- data.frame(
    Tempo = get_tempo(data2),
    Measures = get_measures(data2),
    "Melodic Contour Score" = get_melodic_contour_score(data2),
    "Average Duration (s)" = get_average_duration(data2),
    "Interval Histogram Aggregate" = get_interval_histogram_aggregate(data2),
    "Complexity Score" = complexity_score2
  )
  
  # Add min and max rows for scaling the radar chart
  max_values <- data.frame(
    Tempo = 300,
    Measures = 100,
    "Melodic Contour Score" = 1,  # Maximum is 1
    "Average Duration (s)" = 600,
    "Interval Histogram Aggregate" = 1,
    "Complexity Score" = 1  # Assume normalized complexity score with max = 1
  )
  min_values <- data.frame(
    Tempo = 0,
    Measures = 0,
    "Melodic Contour Score" = 0,  # Minimum is 0
    "Average Duration (s)" = 0,
    "Interval Histogram Aggregate" = 0,
    "Complexity Score" = 0
  )
  
  # Combine data with min and max for proper scaling
  radar_data <- rbind(max_values, min_values, song1_data, song2_data)
  
  # Create a radar chart as a ggplot object
  radar_chart <- radarchart(
    radar_data,
    axistype = 1,  # Axis type
    pcol = c("#494949", "#F56C37"),  # Line colors for two songs
    pfcol = c("#D9D9D980", "#F56C3780"),  # Fill colors for two songs
    plwd = 2,  # Line width
    cglcol = "grey",  # Grid line color
    cglty = 1,  # Grid line type
    axislabcol = "black",  # Axis label color
    caxislabels = seq(0, 1, length.out = 5),  # Axis labels for normalized range
    vlcex = 0.8  # Variable label size
  )
  
  # Add a title
  title("Spider Chart Comparison of Two Songs")
  
  # Return the radar chart
  return(radar_chart)
}

# Example usage
# Assuming `song_data1` and `song_data2` contain the input data structures
song_data1 <- get_song_details_by_title("Wexford")
song_data2 <- get_song_details_by_title("In The Bleak Midwinter")

complexity_score1 <- calculate_complexity(song_data1)
complexity_score2 <- calculate_complexity(song_data2)

# Create and return the comparison spider chart
radar_chart <- create_spider_chart_comparison(song_data1, complexity_score1, song_data2, complexity_score2)

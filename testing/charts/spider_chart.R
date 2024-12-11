if (!requireNamespace("fmsb", quietly = TRUE)) install.packages("fmsb")
library(fmsb)

source("testing/charts/complexity.R")
source("testing/charts/note_freq_chart.R")

# Function to extract tempo
get_tempo <- function(data) {
  data[[1]]$tempo
}

# Function to extract measures
get_measures <- function(data) {
  data[[1]]$measures
}

# Function to extract mode
get_mode <- function(data) {
  data[[1]]$mode
}

get_melodic_contour_score <- function(data) {
  # Extract the melodic contour values
  contour <- unlist(data[[1]]$melodic_contour, use.names = FALSE)
  
  if (length(contour) < 3) {
    warning("Melodic contour data is incomplete. Filling missing values with 0.")
    contour <- c(contour, rep(0, 3 - length(contour)))
  }
  
  # Assign names explicitly
  names(contour) <- c("up", "flat", "down")
  
  # Calculate the total for normalization
  total <- sum(contour, na.rm = TRUE)
  if (total == 0) total <- 1  # Prevent division by zero
  
  # Normalize the values
  percentages <- contour / total
  
  # Compute weighted score: 1 for up, 0.5 for flat, 0 for down
  score <- (percentages["up"] * 1) + (percentages["flat"] * 0.5) + (percentages["down"] * 0)
  return(score)
}

# Function to extract average duration
get_average_duration <- function(data) {
  data[[1]]$average_duration
}

# Function to aggregate interval histogram into a single figure (e.g., mean or sum)
get_interval_histogram_aggregate <- function(data) {
  intervals <- unlist(data[[1]]$interval_histogram)
  mean(intervals)  # You can change this to `sum(intervals)` or other aggregate measures
}

# Function to extract and summarize time signatures
get_time_signatures <- function(data) {
  time_signatures <- unlist(data[[1]]$time_signatures)
  unique_time_signatures <- unique(time_signatures)
  paste(unique_time_signatures, collapse = ", ")
}

# Function to create a summary dataframe for charting
create_summary_dataframe <- function(data) {
  melodic_contour <- get_melodic_contour_score(data)
  
  data.frame(
    Feature = c("Tempo", "Measures", "Mode", "Melodic Contour Score",
                "Average Duration (s)", "Interval Histogram Aggregate", "Time Signatures"),
    Value = c(
      get_tempo(data),
      get_measures(data),
      get_mode(data),
      melodic_contour,
      get_average_duration(data),
      get_interval_histogram_aggregate(data),
      get_time_signatures(data)
    )
  )
}

# Function to create a spider chart comparing two songs and return the chart
create_spider_chart_comparison <- function(data1, complexity_score1, data2, complexity_score2) {
  # Combine the two songs' data into a single dataframe
  song_data <- rbind(
    data.frame(
      Tempo = get_tempo(data1),
      Measures = get_measures(data1),
      "Melodic Contour Score" = get_melodic_contour_score(data1),
      "Average Duration (s)" = get_average_duration(data1),
      "Interval Histogram Aggregate" = get_interval_histogram_aggregate(data1),
      "Complexity Score" = complexity_score1,
      row.names = "Song 1"
    ),
    data.frame(
      Tempo = get_tempo(data2),
      Measures = get_measures(data2),
      "Melodic Contour Score" = get_melodic_contour_score(data2),
      "Average Duration (s)" = get_average_duration(data2),
      "Interval Histogram Aggregate" = get_interval_histogram_aggregate(data2),
      "Complexity Score" = complexity_score2,
      row.names = "Song 2"
    )
  )
  
  # Add max and min rows for scaling
  max_values <- data.frame(
    Tempo = 300,
    Measures = 100,
    "Melodic Contour Score" = 1,
    "Average Duration (s)" = 600,
    "Interval Histogram Aggregate" = 1,
    "Complexity Score" = 1,
    row.names = "Max"
  )
  min_values <- data.frame(
    Tempo = 0,
    Measures = 0,
    "Melodic Contour Score" = 0,
    "Average Duration (s)" = 0,
    "Interval Histogram Aggregate" = 0,
    "Complexity Score" = 0,
    row.names = "Min"
  )
  
  # Combine with the actual data
  radar_data <- rbind(max_values, min_values, song_data)
  
  # Create the radar chart
  radarchart(
    radar_data,
    axistype = 1,
    pcol = c("#d9d9d9", "#ffac27"),
    pfcol = c("#FF999980", "#9999FF80"),
    plwd = 2,
    cglcol = "grey",
    cglty = 1,
    axislabcol = "black",
    caxislabels = seq(0, 1, length.out = 5),
    vlcex = 0.8
  )
  
  # Add title
  title("Spider Chart Comparison of Two Songs")
}
spider_chart_compare_with_average <- function(song_title, song_list) {
  library(stringr)
  library(fmsb)
  
  # Validate the song list
  if (is.null(song_list) || length(song_list) == 0) {
    stop("Error: song_list is empty or NULL. Please provide a valid list of song titles.")
  }
  
  # Clean and validate song titles
  song_list <- str_trim(song_list)
  if (any(song_list == "")) {
    stop("Error: song_list contains empty or invalid song titles after trimming.")
  }
  
  # Fetch details for the specific song
  song_details <- tryCatch(
    get_song_details_by_title(str_trim(song_title)),
    error = function(e) stop("Error fetching details for the specific song: ", e$message)
  )
  
  # Fetch details for the song list
  song_results <- lapply(song_list, function(song) {
    tryCatch(get_song_details_by_title(song), error = function(e) {
      warning(paste("Skipping song:", song, "due to error:", e$message))
      return(NULL)
    })
  })
  
  # Remove NULL entries from song_results
  song_results <- Filter(Negate(is.null), song_results)
  if (length(song_results) == 0) {
    stop("Error: Unable to fetch details for any songs in the list.")
  }
  
  # Compute average features for the song list
  average_features <- tryCatch(
    average_song_features(song_results),
    error = function(e) stop("Error computing average features: ", e$message)
  )
  
  # Calculate complexity scores
  specific_complexity <- calculate_complexity(song_details)
  average_complexity <- calculate_complexity(average_features)
  
  # Prepare data for the spider chart
  specific_song_data <- data.frame(
    Tempo = get_tempo(song_details),
    Measures = get_measures(song_details),
    "Melodic Contour" = get_melodic_contour_score(song_details),
    "Duration" = get_average_duration(song_details),
    "Intervals" = get_interval_histogram_aggregate(song_details),
    "Complexity" = specific_complexity
  )
  
  average_song_data <- data.frame(
    Tempo = get_tempo(average_features),
    Measures = get_measures(average_features),
    "Melodic Contour" = get_melodic_contour_score(average_features),
    "Duration" = get_average_duration(average_features),
    "Intervals" = get_interval_histogram_aggregate(average_features),
    "Complexity" = average_complexity
  )
  
  # Add max and min rows for scaling
  max_values <- data.frame(
    Tempo = 300,
    Measures = 100,
    "Melodic Contour" = 1,
    "Duration" = 600,
    "Intervals" = 1,
    "Complexity" = 1
  )
  
  min_values <- data.frame(
    Tempo = 0,
    Measures = 0,
    "Melodic Contour" = 0,
    "Duration" = 0,
    "Intervals" = 0,
    "Complexity" = 0
  )
  
  # Combine the data frames
  radar_data <- rbind(max_values, min_values, specific_song_data, average_song_data)
  rownames(radar_data) <- c("Max", "Min", "Specific Song", "Average")
  
  # Adjust margins
  old_par <- par(mar = c(1, 1, 1, 1), oma = c(0, 0, 0, 0))  # Reduce margins
  
  # Create the radar chart
  radarchart(
    radar_data,
    axistype = 1,
    pcol = c("#F56C37", "#d9d9d9"),  # Colors for specific song and average
    pfcol = c("#F56C3780", "#d9d9d980"),  # Fill colors
    plwd = 2,  # Line width
    cglcol = "grey",  # Grid line color
    cglty = 1,  # Grid line type
    axislabcol = "black",  # Axis label color
    caxislabels = seq(0, 1, length.out = 5),  # Axis labels for normalized range
    calcex = 0.5,
    vlcex = 0.5,  # Variable label size
    custom.labels = list(  # Add custom labels with tooltips
      "Tempo" = list(
        label = "Tempo",
        tooltip = "Speed of the music measured in beats per minute (BPM)"
      ),
      "Measures" = list(
        label = "Measures",
        tooltip = "Number of musical bars in the piece"
      ),
      "Melodic Contour" = list(
        label = "Melodic Contour",
        tooltip = "How the melody moves - whether it tends to go up, down, or stay level"
      ),
      "Duration" = list(
        label = "Duration",
        tooltip = "Average length of notes in milliseconds"
      ),
      "Intervals" = list(
        label = "Intervals",
        tooltip = "The musical distance between consecutive notes"
      ),
      "Complexity" = list(
        label = "Complexity",
        tooltip = "Overall musical complexity based on various factors"
      )
    )
  )
  
  # Reset margins to previous values
  par(old_par)
}


song_title <- "Wexford"
song_list <- c("Wexford", "In The Bleak Midwinter", "Deck The Halls")

# Generate the comparison spider chart
spider_chart_compare_with_average(song_title, song_list)




# # Example usage
# song_data1 <- get_song_details_by_title("Wexford")
# song_data2 <- get_song_details_by_title("In The Bleak Midwinter")

# complexity_score1 <- calculate_complexity(song_data1)
# complexity_score2 <- calculate_complexity(song_data2)

# # Create and return the comparison spider chart
# radar_chart <- create_spider_chart_comparison(song_data1, complexity_score1, song_data2, complexity_score2)


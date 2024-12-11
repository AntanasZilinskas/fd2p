library(httr)
library(jsonlite)
library(ggplot2)

# Function to call the API to return the list of song features
get_song_details_by_title <- function(song_name) {
  # Define the API URL and headers
  url <- "https://dvplamwokfwyvuaskgyk.supabase.co/rest/v1/rpc/get_song_details_by_title"
  headers <- add_headers(
    `Content-Type` = "application/json",
    `apikey` = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR2cGxhbXdva2Z3eXZ1YXNrZ3lrIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczMjI5NjE0NiwiZXhwIjoyMDQ3ODcyMTQ2fQ.Gsu1OOTI2qfkeXCywm1Q5CLD3Igd5jOuUCYUoW_KYZo",
    `Authorization` = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR2cGxhbXdva2Z3eXZ1YXNrZ3lrIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczMjI5NjE0NiwiZXhwIjoyMDQ3ODcyMTQ2fQ.Gsu1OOTI2qfkeXCywm1Q5CLD3Igd5jOuUCYUoW_KYZo"
  )

  # Define the body of the POST request
  body <- toJSON(list(song_name = song_name), auto_unbox = TRUE)

  # Send the POST request
  response <- POST(url, headers, body = body)

  # Check if the request was successful
  if (status_code(response) == 200) {
    # print(content(response, "parsed"))
    # Parse and return the response content

    return(content(response, "parsed"))
  } else {
    # Print the error message
    stop("Failed to fetch song details: ", content(response, "text"))
  }
}

# Function to create a comparative bar chart for note frequencies of two songs.  1st is preferences
# Param: reorder: TRUE if we want it graduated by freq, FALSE if we want it alphabelical
note_freq_chart_comparison <- function(song_details1, song_details2, reorder = TRUE) {
  library(ggplot2)
  
  pitch_class_histogram1 <- unlist(song_details1[[1]]$pitch_class_histogram)
  pitch_class_histogram2 <- unlist(song_details2[[1]]$pitch_class_histogram)
  note_names <- c("C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B")
  
  note_data <- data.frame(
    Note = rep(note_names, 2),
    Frequency = c(pitch_class_histogram1, pitch_class_histogram2),
    Song = rep(c("Preferences", "Song"), each = length(note_names))
  )
  
  if (reorder) {
    sorted_notes <- note_data[note_data$Song == "Preferences", ]
    sorted_notes <- sorted_notes[order(sorted_notes$Frequency, decreasing = TRUE), ]
    note_data$Note <- factor(note_data$Note, levels = sorted_notes$Note)
  }
  
  # Separate data for line and bar
  line_data <- note_data[note_data$Song == "Preferences", ]
  bar_data <- note_data[note_data$Song == "Song", ]
  
  ggplot() +
    # Bar plot for Song
    geom_bar(data = bar_data, aes(x = Note, y = Frequency, fill = "Song"), 
             stat = "identity", position = "dodge", width = 0.8, color = "black") +
    scale_fill_manual(values = c("Song" = "#F56C37"), labels = c("Song")) +
    scale_color_manual(values = c("Preferences" = "#D9D9D980"), labels = c("Preferences")) +
    
    # Line plot for Preferences
    geom_line(data = line_data, aes(x = Note, y = Frequency, group = 1, color = "Preferences"), size = 1.2) +
    labs(
      title = "Note Occurrence",
      x = "",
      y = "",
      fill = "",
      color = ""
    ) +
    theme_minimal(base_size = 10) +
    theme(
      plot.title = element_text(size = 12, hjust = 0.5),
      axis.text.x = element_text(size = 8, angle = 45, hjust = 1),
      axis.text.y = element_blank(), # Remove y-axis numbering
      axis.title.x = element_text(size = 10),
      axis.title.y = element_text(size = 10),
      legend.position = "bottom",
      legend.title = element_blank(), # Simplify legend
      legend.text = element_text(size = 8),
      panel.grid = element_blank() # Remove background grid lines
    )
}

# Function to compute average features from a list of song details
average_song_features <- function(song_details_list) {
  # Initialize accumulators for different features
  num_songs <- length(song_details_list)
  
  # Initialize accumulators for histograms, numerical features, and feature vector
  pitch_class_histogram_sum <- rep(0, 12)
  interval_histogram_sum <- rep(0, 12)
  melodic_contour_sum <- rep(0, 3)
  note_duration_histogram_sum <- rep(0, 11)
  feature_vector_sum <- rep(0, 128) # Ensure feature vector is 128 elements
  average_duration_sum <- 0
  tempo_sum <- 0
  measures_sum <- 0
  
  # Loop through each song's details
  for (song_details in song_details_list) {
    if (!is.null(song_details[[1]]$pitch_class_histogram)) {
      pitch_class_histogram_sum <- pitch_class_histogram_sum + unlist(song_details[[1]]$pitch_class_histogram)
    }
    if (!is.null(song_details[[1]]$interval_histogram)) {
      interval_histogram_sum <- interval_histogram_sum + unlist(song_details[[1]]$interval_histogram)
    }
    if (!is.null(song_details[[1]]$melodic_contour)) {
      melodic_contour_sum <- melodic_contour_sum + unlist(song_details[[1]]$melodic_contour)
    }
    if (!is.null(song_details[[1]]$note_duration_histogram)) {
      note_duration_histogram_sum <- note_duration_histogram_sum + unlist(song_details[[1]]$note_duration_histogram)
    }
    if (!is.null(song_details[[1]]$feature_vector)) {
      # Convert feature_vector to numeric and sum
      feature_vector_sum <- feature_vector_sum + as.numeric(strsplit(gsub("\\[|\\]", "", song_details[[1]]$feature_vector), ",")[[1]])
    }
    if (!is.null(song_details[[1]]$average_duration)) {
      average_duration_sum <- average_duration_sum + song_details[[1]]$average_duration
    }
    if (!is.null(song_details[[1]]$tempo)) {
      tempo_sum <- tempo_sum + song_details[[1]]$tempo
    }
    if (!is.null(song_details[[1]]$measures)) {
      measures_sum <- measures_sum + song_details[[1]]$measures
    }
  }
  
  # Compute averages
  average_features <- list(
    list(
      id = "average",
      creators = list(),
      pitch_class_histogram = as.list(pitch_class_histogram_sum / num_songs),
      interval_histogram = as.list(interval_histogram_sum / num_songs),
      melodic_contour = as.list(melodic_contour_sum / num_songs),
      chord_progressions = NULL, # No meaningful average for chord progressions
      key_signature = "average", # Placeholder
      mode = "average",          # Placeholder
      note_duration_histogram = as.list(note_duration_histogram_sum / num_songs),
      feature_vector = feature_vector_sum / num_songs, # Store as numeric array
      average_duration = average_duration_sum / num_songs,
      tempo = tempo_sum / num_songs,
      measures = measures_sum / num_songs,
      time_signatures = list("average") # Placeholder for time signatures
    )
  )
  
  return(average_features)
}

# Example usage
result <- get_song_details_by_title("The Wexford Carol")
result2 <- get_song_details_by_title("Wexford")
result3 <- get_song_details_by_title("In The Bleak Midwinter")
result4 <- get_song_details_by_title("Deck The Halls")


note_freq_chart_comparison_titles <- function(song1, song2) {
  result <- get_song_details_by_title(song1)
  result2 <- get_song_details_by_title(song2)

  note_freq_chart_comparison(result, result2)
}

average_from_titles <- function(song_list) {
  # Check if the song list is not empty
  if (length(song_list) == 0) {
    stop("The song list is empty.")
  }
  
  # Initialize a list to store the results
  song_results <- list()
  
  # Loop through each song title in the song_list
  for (song in song_list) {
    # Call get_songs_by_title for each song
    song_results[[song]] <- get_song_details_by_title(song)
  }
  
  # Call average_songs with the results
  average_result <- average_song_features(song_results)
  
  # Return the final result
  return(average_result)
}

library(stringr) # For str_trim

compare_song_with_average <- function(song_title, song_list) {
  # Check if song_list is valid
  if (is.null(song_list) || length(song_list) == 0) {
    stop("Error: song_list is empty or NULL. Please provide a valid list of song titles.")
  }
  
  # Clean up song titles in song_list by trimming leading/trailing spaces
  song_list <- str_trim(song_list)
  
  # Check if any song title is still invalid after trimming
  if (any(song_list == "")) {
    stop("Error: song_list contains empty or invalid song titles after trimming.")
  }
  
  # Get the song details for the individual song
  song_details <- get_song_details_by_title(str_trim(song_title)) # Also trim song_title
  
  # Get the song details for each song in the list
  song_results <- list()
  for (song in song_list) {
    # print(paste("Fetching details for song:", song)) # Debugging
    song_results[[song]] <- get_song_details_by_title(song)
  }
  
  # Compute the average features for the list of songs
  average_features <- average_song_features(song_results)
  
  # Call note_freq_chart_comparison to compare the individual song's features
  # with the average features of the song list
  chart <- note_freq_chart_comparison(average_features, song_details)
  
  # Return the chart
  return(chart)
}

# Example usage
# song_title <- "The Wexford Carol"
# song_list <- c("Wexford     ", "Wests       ", "Wexford Reel") # Example with trailing spaces
# chart <- compare_song_with_average(song_title, song_list)

# Print the chart
# print(chart)
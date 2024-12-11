# Load necessary library
library(entropy)

# Function to calculate entropy
calculate_entropy <- function(distribution) {
  distribution <- distribution[distribution > 0]  # Remove zeroes for entropy calculation
  if (length(distribution) > 0) {
    return(entropy(distribution, unit = "log2"))
  } else {
    return(0)
  }
}

# Function to calculate complexity scores for a list of songs
calculate_complexity <- function(songs) {
  scores <- sapply(songs, function(song) {
    # Extract features
    pitch_class_histogram <- unlist(song$pitch_class_histogram)
    interval_histogram <- unlist(song$interval_histogram)
    melodic_contour <- unlist(song$melodic_contour)
    chord_progressions <- unlist(song$chord_progressions)
    note_duration_histogram <- unlist(song$note_duration_histogram)
    
    # Handle feature vector if it exists (placeholder: feature_vector is not present in the example output)
    feature_vector <- c()  # Adjust this if the feature_vector exists or can be computed
    
    # Calculate metrics
    pitch_entropy <- calculate_entropy(pitch_class_histogram)
    interval_var <- if (length(interval_histogram) > 1) var(interval_histogram) else 0
    contour_entropy <- calculate_entropy(melodic_contour)
    chord_complexity <- if (length(chord_progressions) > 0) {
      length(unique(chord_progressions)) / length(chord_progressions)
    } else {
      0
    }
    duration_entropy <- calculate_entropy(note_duration_histogram)
    feature_vector_norm <- if (length(feature_vector) > 0) {
      sqrt(sum(feature_vector^2))
    } else {
      0
    }
    
    # Combine into a weighted score (I am not too sure about these but can adjust)
    score <- (
      0.2 * pitch_entropy +
      0.15 * interval_var +
      0.2 * contour_entropy +
      0.1 * chord_complexity +
      0.15 * duration_entropy +
      0.2 * feature_vector_norm
    )
    return(score)
  })
  
  return(scores)
}

# Example usage
# result <- get_song_details_by_title("In The Bleak Midwinter")
# result2 <- get_song_details_by_title("Wexford")
# complexity_score_1 <- calculate_complexity(result)
# complexity_score_2 <- calculate_complexity(result2)
# print(complexity_score_1)
# print(complexity_score_2)


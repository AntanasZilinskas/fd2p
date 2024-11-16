library(reticulate)
library(tidyverse)
library(jsonlite)
library(RcppCNPy)  # For saving and loading .npy files

# Use your pyenv Python
use_python("/Users/antanaszilinskas/.pyenv/versions/3.10.13/bin/python", required = TRUE)

# Print Python configuration for debugging
print("Python Configuration:")
py_config()

create_and_save_embeddings <- function(csv_path, output_dir = "data/") {
  # Create output directory if it doesn't exist
  dir.create(output_dir, showWarnings = FALSE)
  
  # Read CSV
  message("Reading CSV...")
  songs_df <- read_csv(csv_path, col_types = cols()) %>%
    distinct() %>%  # Remove any duplicates
    mutate(id = row_number())  # Add an ID column starting from 1
  
  # Assign song_titles to the Python session
  song_titles <- songs_df$title %>% as.list()
  py$song_titles <- song_titles
  
  # Define paths
  embeddings_path <- file.path(output_dir, "song_embeddings.npy")
  songs_df_path <- file.path(output_dir, "songs_with_ids.csv")
  
  # Prepare Python code as a string
  py_code <- sprintf("
import numpy as np
from sentence_transformers import SentenceTransformer

print('Loading SentenceTransformer model...')
model = SentenceTransformer('all-MiniLM-L6-v2')

print('Encoding song titles...')
embeddings = model.encode(song_titles, batch_size=64, show_progress_bar=True)
embeddings = np.ascontiguousarray(embeddings.astype('float32'))

print('Saving embeddings to %s')
np.save(r'%s', embeddings)
", embeddings_path, embeddings_path)
  
  # Execute the Python code
  message("Executing Python code...")
  py_run_string(py_code)
  
  # Save song data with IDs
  message("Saving song data to ", songs_df_path)
  write_csv(songs_df, songs_df_path)
  
  message("Embeddings and song data have been saved successfully!")
}

# Example usage:
# create_and_save_embeddings("data/processed_songs.csv")
  
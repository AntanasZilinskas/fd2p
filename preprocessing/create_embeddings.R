library(reticulate)
library(tidyverse)
library(readr)
library(jsonlite)

# Use your pyenv Python
use_python("/Users/antanaszilinskas/.pyenv/versions/3.10.13/bin/python", required = TRUE)

# Print Python configuration for debugging
print("Python Configuration:")
py_config()

# Import Python modules
np <- import("numpy")
faiss <- import("faiss")
sentence_transformers <- import("sentence_transformers")

create_and_save_embeddings <- function(csv_path, output_dir = "data/") {
  # Create output directory if it doesn't exist
  dir.create(output_dir, showWarnings = FALSE)
  
  # Read CSV
  message("Reading CSV...")
  songs_df <- read_csv(csv_path) %>%
    distinct() %>%  # Remove any duplicates
    mutate(id = row_number())  # Add an ID column
  
  # Initialize the model in Python global namespace
  py_run_string("
from sentence_transformers import SentenceTransformer
model = SentenceTransformer('all-MiniLM-L6-v2')
embeddings_list = []
  ")
  
  # Create embeddings in batches
  message("Creating embeddings...")
  batch_size <- 1000
  n_batches <- ceiling(nrow(songs_df) / batch_size)
  
  for(i in 1:n_batches) {
    start_idx <- ((i-1) * batch_size) + 1
    end_idx <- min(i * batch_size, nrow(songs_df))
    
    batch <- songs_df$title[start_idx:end_idx]
    
    # Convert batch to Python list directly
    py$current_batch <- as.list(batch)
    py_run_string("
batch_embeddings = model.encode(current_batch)
embeddings_list.append(batch_embeddings)
    ")
    
    message(sprintf("Processed batch %d of %d", i, n_batches))
  }
  
  # Combine embeddings in Python
  py_run_string("
import numpy as np
embeddings = np.vstack(embeddings_list)
embeddings = np.ascontiguousarray(embeddings.astype(np.float32))
  ")
  
  # Create FAISS index
  dimension <- py_eval("embeddings.shape[1]")
  index <- faiss$IndexFlatIP(as.integer(dimension))
  index$add(py$embeddings)
  
  # Save everything
  message("Saving files...")
  faiss$write_index(index, file.path(output_dir, "songs.faiss"))
  saveRDS(songs_df, file = file.path(output_dir, "processed_songs.rds"))
  
  message("Done!")
} 
# global.R

# Define required packages
required_packages <- c(
  "shiny",
  "httr",
  "jsonlite",
  "shinyjs",
  "methods"
)

# Install missing packages
new_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) install.packages(new_packages)

# Load all required packages
lapply(required_packages, library, character.only = TRUE)

# Source the Spotify API functions
source("spotify.R")

# note frequency chart functions
source("testing/charts/note_freq_chart.R")

# Define the quick_search_songs function using fuzzy search on titles
quick_search_songs <- function(query, max_results = 5L) {
  # Ensure 'query' is a single string
  query <- as.character(query[1])
  if (nchar(query) < 2) return(data.frame())
  
  # Define the URL of the Supabase Edge Function
  supabase_url <- "https://dvplamwokfwyvuaskgyk.supabase.co/functions/v1/search_songs"
  
  # Retrieve the API key from environment variable
  supabase_key <- Sys.getenv("SUPABASE_ANON_KEY")
  
  if (supabase_key == "") {
    stop("Supabase API key is not set. Please set SUPABASE_ANON_KEY in your .Renviron file.")
  }
  
  # Create the JSON payload
  payload <- list(
    query = query,
    max_results = as.integer(max_results)
  )
  
  # Send POST request to the Supabase Edge Function with Authorization header
  response <- POST(
    url = supabase_url,
    body = payload,
    encode = "json",
    content_type_json(),
    add_headers(Authorization = paste("Bearer", supabase_key))
  )
  
  # Check if the request was successful
  if (response$status_code != 200) {
    message("Error: Failed to retrieve results from Supabase Edge Function.")
    message("Status code: ", response$status_code)
    message("Response: ", content(response, "text", encoding = "UTF-8"))
    return(data.frame())
  }
  
  # Parse the JSON response
  results <- content(response, as = "parsed", simplifyDataFrame = TRUE)
  
  # Convert results to data frame
  if (length(results) == 0) {
    return(data.frame())
  } else {
    return(as.data.frame(results))
  }
}

# Function to find similar songs based on selected titles
find_similar_songs <- function(input_titles, top_n = 5L) {
  # Ensure 'input_titles' is a character vector
  input_titles <- as.character(input_titles)
  
  # Define the Supabase URL and Key
  supabase_url <- "https://dvplamwokfwyvuaskgyk.supabase.co/rest/v1/rpc/find_similar_songs_by_titles"
  
  # Retrieve the API key from environment variable
  supabase_key <- Sys.getenv("SUPABASE_SERVICE_KEY")
  
  if (supabase_key == "") {
    stop("Supabase SERVICE API key is not set. Please set SUPABASE_SERVICE_KEY in your .Renviron file.")
  }
  
  # Create the JSON payload
  payload <- list(
    input_titles = input_titles,
    top_n = as.integer(top_n)
  )
  
  # Send POST request to the Supabase RPC function with Authorization header
  response <- POST(
    url = supabase_url,
    body = toJSON(payload, auto_unbox = TRUE),
    content_type("application/json"),
    add_headers(
      apikey = supabase_key,
      Authorization = paste("Bearer", supabase_key)
    )
  )
  
  # Print the response content to the console immediately
  cat("Received response from Supabase:\n")
  cat(content(response, "text", encoding = "UTF-8"), "\n")
  flush.console()
  
  # Check if the request was successful
  if (response$status_code != 200) {
    message("Error: Failed to retrieve similar songs from Supabase RPC function.")
    message("Status code: ", response$status_code)
    message("Response: ", content(response, "text", encoding = "UTF-8"))
    return(data.frame())
  }
  
  # Parse the JSON response
  results <- content(response, as = "parsed", type = "application/json", encoding = "UTF-8")
  
  # Debugging: Print the structure of results
  message("Results from Supabase:")
  str(results)
  
  if (length(results) == 0) {
    message("No recommendations found.")
    return(data.frame())
  }
  
  # Process the results to handle 'creators' field
  results <- lapply(results, function(song) {
    # If 'creators' is NULL or empty, set it to NA
    if (is.null(song$creators) || length(song$creators) == 0) {
      song$creators <- NA
    } else {
      # Concatenate the creators into a single string
      song$creators <- paste(unlist(song$creators), collapse = ", ")
    }
    # Return the modified song
    song
  })
  
  # Ensure all elements have the same fields
  field_names <- unique(unlist(lapply(results, names)))
  results <- lapply(results, function(song) {
    missing_fields <- setdiff(field_names, names(song))
    if (length(missing_fields) > 0) {
      song[missing_fields] <- NA
    }
    song[field_names]
  })
  
  # Convert to data frame
  recommended_songs <- do.call(rbind, lapply(results, function(x) as.data.frame(x, stringsAsFactors = FALSE)))
  
  # Reset row names
  rownames(recommended_songs) <- NULL
  
  # Ensure that the 'similarity' column is numeric and available
  recommended_songs$similarity <- as.numeric(recommended_songs$similarity)
  
  # Get Spotify credentials from environment variables
  client_id <- Sys.getenv("SPOTIFY_CLIENT_ID")
  client_secret <- Sys.getenv("SPOTIFY_CLIENT_SECRET")
  
  if (client_id == "" || client_secret == "") {
    stop("Spotify client ID and secret are not set. Please set SPOTIFY_CLIENT_ID and SPOTIFY_CLIENT_SECRET in your .Renviron file.")
  }
  
  # Get Spotify access token
  spotify_token <- get_spotify_token(client_id, client_secret)
  
  # For each song, fetch the Spotify link
  recommended_songs$spotify_url <- sapply(recommended_songs$title, function(title) {
    search_spotify_song(title, spotify_token)
  })
  
  return(recommended_songs)
}
# spotify.R

# Load required packages
library(httr)
library(jsonlite)

# Function to get Spotify access token
get_spotify_token <- function(client_id, client_secret) {
  # Authentication URL
  auth_url <- "https://accounts.spotify.com/api/token"
  
  # Request access token
  auth_response <- POST(
    url = auth_url,
    authenticate(client_id, client_secret),
    body = list(grant_type = "client_credentials"),
    encode = "form"
  )
  
  # Parse the response
  auth_content <- content(auth_response, as = "parsed", type = "application/json")
  
  # Check for errors
  if (!is.null(auth_content$error)) {
    stop("Error obtaining Spotify access token: ", auth_content$error_description)
  }
  
  return(auth_content$access_token)
}

# Function to search for a song and get its Spotify URL
search_spotify_song <- function(song_title, token) {
  # Base URL for Spotify Search API
  base_url <- "https://api.spotify.com/v1/search"
  
  # Query parameters
  query <- list(
    q = song_title,
    type = "track",
    limit = 1
  )
  
  # Send GET request
  response <- GET(
    url = base_url,
    query = query,
    add_headers(Authorization = paste("Bearer", token))
  )
  
  # Parse the response
  data <- content(response, as = "parsed", type = "application/json")
  
  # Check if any track is found
  if (!is.null(data$tracks) && length(data$tracks$items) > 0) {
    return(data$tracks$items[[1]]$external_urls$spotify)
  } else {
    return(NA)  # Return NA if no song is found
  }
}

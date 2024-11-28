# global.R

# Load required packages
library(shiny)
library(httr)
library(jsonlite)

# Define the quick_search_songs function
quick_search_songs <- function(query, max_results = 10L) {
  # Ensure 'query' is a single string
  query <- as.character(query[1])
  if (nchar(query) < 2) return(character(0))
  
  # Define the URL of the Supabase Edge Function
  supabase_url <- "https://dvplamwokfwyvuaskgyk.supabase.co/functions/v1/search_similar_titles"
  
  # Retrieve the API key from environment variable
  supabase_key <- Sys.getenv("SUPABASE_ANON_KEY")
  
  if (supabase_key == "") {
    stop("Supabase API key is not set. Please set SUPABASE_ANON_KEY in your .Renviron file.")
  }
  
  # Create the JSON payload
  payload <- list(
    query = query,
    top_n = as.integer(max_results)
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
    return(character(0))
  }
  
  # Parse the JSON response
  results <- content(response, as = "parsed", type = "application/json", encoding = "UTF-8")
  
  # Assuming the response is a list of song titles
  song_titles <- sapply(results, function(x) x$title)
  
  return(song_titles)
}
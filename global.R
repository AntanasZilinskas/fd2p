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

  # Send GET request to the Flask microservice
  response <- GET(
    url = "http://127.0.0.1:5000/search",
    query = list(query = query, max_results = max_results)
  )

  # Check if the request was successful
  if (response$status_code != 200) {
    message("Error: Failed to retrieve results from the microservice.")
    message("Status code: ", response$status_code)
    message("Response: ", content(response, "text"))
    return(character(0))
  }

  # Parse the JSON response
  results <- content(response, as = "parsed", type = "application/json", encoding = "UTF-8")

  return(unlist(results))
}
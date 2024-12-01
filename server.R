# server.R
library(shiny)
library(methods)
# Ensure global.R is sourced
source("global.R")

server <- function(input, output, session) {
  # Store selected songs
  selected_songs <- reactiveVal(character(0))
  
  # Reactive value to store search results
  search_results <- reactiveVal(data.frame(title = character(0), stringsAsFactors = FALSE))
  
  # Reactive value to store recommended songs
  recommended_songs <- reactiveVal(data.frame())
  
  # Reactive value to track search progress
  search_in_progress <- reactiveVal(FALSE)
  
  # Reactive value to control visibility of search results
  show_search_results <- reactiveVal(FALSE)
  
  # Function to perform the search
  perform_search <- function(query) {
    message("Search query: ", query)
    
    # Set search_in_progress to TRUE
    search_in_progress(TRUE)
    
    # Show the spinner
    session$sendCustomMessage("show_spinner", TRUE)
    
    # Check if 'query' is valid
    if (!is.null(query) && nzchar(query) && nchar(query) >= 2) {
      results <- quick_search_songs(query, max_results = 10L)
      if (length(results) > 0) {
        # Update search results
        search_results(data.frame(title = results, stringsAsFactors = FALSE))
        # Show search results
        show_search_results(TRUE)
      } else {
        # No results found
        search_results(data.frame(title = character(0), stringsAsFactors = FALSE))
        showNotification("No songs found for your search.", type = "warning")
        # Hide search results
        show_search_results(FALSE)
      }
    } else {
      # Query is too short or invalid
      search_results(data.frame(title = character(0), stringsAsFactors = FALSE))
      showNotification("Please enter at least 2 characters to search.", type = "warning")
      # Hide search results
      show_search_results(FALSE)
    }
    
    # Set search_in_progress to FALSE after search completes
    search_in_progress(FALSE)
    
    # Hide the spinner
    session$sendCustomMessage("show_spinner", FALSE)
  }
  
  # Observe search input changes
  observeEvent(input$searchInput, {
    query <- input$searchInput
    if (!is.null(query) && query != "") {
      perform_search(query)
    } else {
      # If input is empty, hide search results
      show_search_results(FALSE)
      search_results(data.frame(title = character(0), stringsAsFactors = FALSE))
    }
  }, ignoreInit = TRUE)
  
  # Render search results as a dropdown
  output$searchResults <- renderUI({
    if (!show_search_results()) return(NULL)
    
    results <- search_results()
    if (nrow(results) == 0) {
      return(NULL)
    }
    
    tags$div(
      class = "search-results-dropdown",
      lapply(seq_len(nrow(results)), function(i) {
        song_title <- results$title[i]
        tags$div(
          class = "search-result-item",
          `data-value` = song_title,
          song_title
        )
      })
    )
  })
  
  # Handle clicking on search result items
  observe({
    # Send a custom message to set up the click handler
    session$sendCustomMessage("setupSearchResultClick", TRUE)
  })
  
  # Receive clicked song title
  observeEvent(input$searchResultClicked, {
    song_title <- input$searchResultClicked
    songs <- selected_songs()
    if (!(song_title %in% songs)) {
      selected_songs(c(songs, song_title))
    }
    # Remove selected song from search results
    results <- search_results()
    updated_results <- results[results$title != song_title, , drop = FALSE]
    search_results(updated_results)
    
    # Hide search results if empty
    if (nrow(updated_results) == 0) {
      show_search_results(FALSE)
    }
  })
  
  # Hide search results when clicking outside
  observeEvent(input$hide_search_results, {
    show_search_results(FALSE)
  }, ignoreInit = TRUE)
  
  # Display selected songs
  output$selectedSongs <- renderUI({
    songs <- selected_songs()
    if (length(songs) == 0) {
      # No songs selected, display the title styled like placeholder text
      return(tags$h3("Selected Songs", class = "placeholder-text"))
    }
    
    # Songs selected, display the song items
    tagList(
      lapply(seq_along(songs), function(i) {
        song <- songs[i]
        tags$div(
          class = "selected-song-item",
          tags$span(class = "song-title", song),
          tags$span(
            class = "remove-song",
            `data-song-index` = i,
            `data-song-title` = song,
            "✕"
          )
        )
      })
    )
  })
  
  # Observe remove song button clicks
  observeEvent(input$remove_song, {
    song_to_remove <- input$remove_song
    songs <- selected_songs()
    updated_songs <- songs[songs != song_to_remove]
    selected_songs(updated_songs)
  })
  
  # Render recommended songs on the MDNA page
  output$recommendedSongs <- renderUI({
    recommendations <- recommended_songs()
    if (nrow(recommendations) == 0) {
      return(tags$p("No recommendations to display."))
    }
    
    tagList(
      h2("Your Recommended Songs"),
      lapply(seq_len(nrow(recommendations)), function(i) {
        song <- recommendations[i, ]
        
        # Safely access song fields with defaults
        title <- if (!is.null(song$title) && nzchar(song$title)) song$title else "Unknown Title"
        creators <- if (!is.null(song$creators) && nzchar(song$creators)) song$creators else "Unknown Artist"
        album <- if (!is.null(song$album) && nzchar(song$album)) song$album else "Unknown Album"
        spotify_url <- if (!is.null(song$spotify_url) && nzchar(song$spotify_url)) song$spotify_url else NULL
        
        tags$div(
          class = "recommendation-item",
          tags$h4(title),
          tags$p(paste("Artists:", creators)),
          tags$p(paste("Album:", album)),
          if (!is.null(spotify_url)) {
            tags$a(href = spotify_url, target = "_blank", "Listen on Spotify")
          } else {
            NULL
          }
        )
      })
    )
  })
  
  # Add a session listener for custom messages
  session$onFlushed(function() {
    session$sendCustomMessage("initialize_spinner", TRUE)
  })
}
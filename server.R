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
  
  # Handle search when the search button is clicked
  observeEvent(input$searchBtn, {
    query <- input$searchInput
    message("Search query: ", query)
    
    # Check if 'query' is not NULL and is a non-empty string
    if (!is.null(query) && nzchar(query) && nchar(query) >= 2) {
      results <- quick_search_songs(query, max_results = 10L)
      
      if (length(results) > 0) {
        # Update search results
        search_results(data.frame(title = results, stringsAsFactors = FALSE))
      } else {
        # No results found
        search_results(data.frame(title = character(0), stringsAsFactors = FALSE))
        showNotification("No songs found for your search.", type = "warning")
      }
    } else {
      # Query is too short or invalid
      search_results(data.frame(title = character(0), stringsAsFactors = FALSE))
      showNotification("Please enter at least 2 characters to search.", type = "warning")
    }
  })
  
  # Render search results using actionButtons
  output$searchResults <- renderUI({
    results <- search_results()
    if (nrow(results) == 0) {
      return(NULL)
    }
    
    tagList(
      h3("Search Results"),
      lapply(seq_len(nrow(results)), function(i) {
        song_title <- results$title[i]
        actionButton(
          inputId = paste0("select_song_", i),
          label = song_title,
          class = "song-result",
          style = "width: 100%; text-align: left;"
        )
      })
    )
  })
  
  # Remove previous observers before creating new ones
  observeEvent(search_results(), {
    # Remove previous observers
    observers <- ls(envir = .GlobalEnv, pattern = "^song_observer_")
    for (obs_name in observers) {
      observer <- get(obs_name, envir = .GlobalEnv)
      observer$destroy()
      rm(list = obs_name, envir = .GlobalEnv)
    }
    
    results <- search_results()
    lapply(seq_len(nrow(results)), function(i) {
      song_title <- results$title[i]
      button_id <- paste0("select_song_", i)
      
      # Create a new observer and assign it to a variable in the global environment
      observer <- observeEvent(input[[button_id]], {
        songs <- selected_songs()
        if (!(song_title %in% songs)) {
          selected_songs(c(songs, song_title))
          message("Song selected: ", song_title)
        }
      }, ignoreInit = TRUE)
      
      # Assign the observer to a variable for later removal
      assign(paste0("song_observer_", i), observer, envir = .GlobalEnv)
    })
  })
  
  # Display selected songs
  output$selectedSongs <- renderUI({
    songs <- selected_songs()
    if (length(songs) == 0) {
      return(NULL)
    }
    
    tagList(
      lapply(seq_along(songs), function(i) {
        div(class = "song-item",
          span(songs[i]),
          span(
            class = "remove-song",
            onclick = sprintf("Shiny.setInputValue('remove_song', %d, {priority: 'event'});", i),
            "×"
          )
        )
      })
    )
  })
  
  # Handle song removal
  observeEvent(input$remove_song, {
    songs <- selected_songs()
    index_to_remove <- as.integer(input$remove_song)
    if (!is.na(index_to_remove) && index_to_remove <= length(songs)) {
      selected_songs(songs[-index_to_remove])
    }
  })
  
  # Handle analyze button
  observeEvent(input$analyzeBtn, {
    req(length(selected_songs()) > 0)
    # Call the function to find similar songs
    recommendations <- find_similar_songs(selected_songs(), top_n = 10L)
    
    if (nrow(recommendations) == 0) {
      showNotification("No recommendations found.", type = "warning")
    } else {
      # Store recommendations
      recommended_songs(recommendations)
      message("Recommendations retrieved.")
      
      # Navigate to the MDNA page
      updateNavbarPage(session, "mainNav", selected = "Your MDNA")
    }
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
  
  # Keep your existing MDNA outputs or add new ones
  # ... your existing MDNA server code ...
}
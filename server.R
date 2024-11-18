# server.R
library(shiny)
library(methods)
# Ensure global.R is sourced
source("global.R")

server <- function(input, output, session) {
  # Store selected songs
  selected_songs <- reactiveVal(character(0))
  
  # Debounced reactive for search term
  debounced_search_term <- debounce(reactive(input$searchTerm), 500)
  
  # Handle search using the debounced search term
  observeEvent(debounced_search_term(), ignoreNULL = FALSE, {
    query <- debounced_search_term()
    message("Query value: ", query)
    
    # Check if 'query' is not NULL and is a non-empty string
    if (!is.null(query) && nzchar(query) && nchar(query) >= 2) {
      results <- quick_search_songs(query, max_results = 10L)
      
      if (length(results) > 0) {
        # Format results as a list of lists with a 'title' field
        choices_list <- lapply(results, function(title) list(title = title))
        
        # Send a custom message to update the Selectize options
        session$sendCustomMessage('updateSelectizeOptions', list(
          inputId = 'songInput',
          options = choices_list
        ))
      } else {
        # Clear choices if no results
        session$sendCustomMessage('updateSelectizeOptions', list(
          inputId = 'songInput',
          options = list()
        ))
      }
    } else {
      # Clear choices if query is too short or invalid
      session$sendCustomMessage('updateSelectizeOptions', list(
        inputId = 'songInput',
        options = list()
      ))
    }
  })
  
  # Handle song selection
  observeEvent(input$songInput, {
    song <- input$songInput
    if (!is.null(song) && nzchar(song)) {
      songs <- selected_songs()
      if (!(song %in% songs)) {
        selected_songs(c(songs, song))
        
        # Log the selected song into the R console
        message("Song selected: ", song)
      }
      # Clear the selectize input via custom message
      session$sendCustomMessage('clearSelectizeInput', list(
        inputId = 'songInput'
      ))
    }
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
    updateNavbarPage(session, "mainNav", selected = "Your MDNA")
  })
  
  # Keep your existing MDNA outputs or add new ones
  # ... your existing MDNA server code ...
}
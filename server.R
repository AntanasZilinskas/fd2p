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
  
  # Reactive value to store the ID of the selected song
  selected_song_id <- reactiveVal(NULL)
  
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
      if (nrow(results) > 0) {
        # Update search results directly
        search_results(results)
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
        # Adjusted if your 'results' data frame has different column names
        song_title <- results$title[i]
        # Alternatively, if your column is 'song_title', use:
        # song_title <- results$song_title[i]
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
      return(tags$p("No recommendations to display, please select some songs first."))
    }
    
    tagList(
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
  
  # Observe Analyze button click
  observeEvent(input$analyzeBtn, {
    # Check if any songs are selected
    selected_songs_list <- selected_songs()
    if(length(selected_songs_list) == 0) {
      showNotification("Please select at least one song before analyzing.", type = "warning")
    } else {
      # Send message to start processing
      session$sendCustomMessage('analyzeButtonProcessing', list(status = 'start'))

      # Perform the processing
      recommended_songs_data <- find_similar_songs(selected_songs_list, top_n = 5L)

      # Debugging: Print the recommended songs data
      print("Recommended Songs Data:")
      print(recommended_songs_data)

      recommended_songs(recommended_songs_data)

      # Send message to end processing and redirect
      session$sendCustomMessage('analyzeButtonProcessing', list(status = 'end'))
    }
  })
  
  # Render recommended songs visualization on the MDNA page
  output$recommendedSongsVisualization <- renderUI({
    recommendations <- recommended_songs()
    
    if (nrow(recommendations) == 0) {
      return(NULL)
    }

    max_distance <- 150  # Adjust based on container size
    center_x <- 0
    center_y <- 0

    # Ensure similarity scores are available
    similarity_scores <- as.numeric(recommendations$similarity)
    min_score <- min(similarity_scores)
    max_score <- max(similarity_scores)
    normalized_scores <- (similarity_scores - min_score) / (max_score - min_score + 0.0001)  # Prevent division by zero

    num_songs <- nrow(recommendations)
    angle_increment <- 360 / num_songs

    # Generate UI elements for each song
    song_elements <- lapply(1:num_songs, function(i) {
      song <- recommendations[i, ]
      angle_deg <- angle_increment * (i - 1)
      angle_rad <- angle_deg * (pi / 180)
      distance <- (1 - normalized_scores[i]) * max_distance  # Closer distance for higher similarity

      # Calculate position relative to center
      x_pos <- center_x + distance * cos(angle_rad)
      y_pos <- center_y + distance * sin(angle_rad)

      # Create inline CSS for positioning
      position_style <- sprintf(
        "left: calc(50%% + %.2fpx); top: calc(50%% + %.2fpx);",
        x_pos,
        y_pos
      )

      # Determine icon based on selection
      selected_id <- selected_song_id()
      if (!is.null(selected_id) && song$id == selected_id) {
        icon_src <- "assets/selected-song.svg"
      } else {
        icon_src <- "assets/suggested-songs.svg"
      }

      # Create a div for the song icon with onclick event
      tags$div(
        class = "suggested-song",
        style = position_style,
        `data-song-id` = song$id,  # For JavaScript access
        # Tooltip with song details
        title = paste(
          "Title:", song$title, "\n",
          "Artists:", song$creators, "\n",
          "Similarity Score:", sprintf("%.2f", song$similarity)
        ),
        img(
          src = icon_src,
          class = "suggested-song-icon",
          onclick = sprintf("event.stopPropagation(); Shiny.setInputValue('song_clicked', %d, {priority: 'event'});", song$id)
        )
      )
    })

    # Return the list of song elements
    do.call(tagList, song_elements)
  })

  # Observe the song click event
  observeEvent(input$song_clicked, {
    selected_song_id(input$song_clicked)
  })

  output$mdnaContent <- renderUI({
    recommendations <- recommended_songs()
    
    if (nrow(recommendations) == 0) {
      # No recommendations yet; display a message or keep it empty
      return(NULL)
    } else {
      # Main container holding both the MDNA visualization and the song details
      div(
        class = "mdna-main-container",
        # Left-side MDNA visualization container
        div(
          class = "mdna-visualization-container-custom",
          onclick = "Shiny.setInputValue('container_clicked', Math.random());",
          # Center icon with title
          div(
            class = "center-icon",
            img(src = "assets/your-mdna.svg", class = "your-mdna-icon"),
            span(class = "mdna-label", "Your MDNA")
          ),
          # Visualization of recommended songs
          uiOutput("recommendedSongsVisualization")
        ),
        # Right-side song details container
        div(
          class = "song-details-container-custom",
          uiOutput("songDetails")
        )
      )
    }
  })

  output$songDetails <- renderUI({
    song_id <- selected_song_id()
    if (is.null(song_id)) {
      return(
        div(
          class = "song-details-placeholder",
          "Click on a song to see details."
        )
      )
    }

    recommendations <- recommended_songs()
    song <- recommendations[recommendations$id == song_id, ]

    if (nrow(song) == 0) {
      return(NULL)
    }

    # Display song details with Spotify link and the chart
    div(
      class = "song-details-custom",
      h3(class = "song-title-custom", song$title),
      p(class = "song-artist-custom", paste("Artist:", song$creators)),
      p(
        class = "song-similarity-custom", 
        paste("Similarity Score:", sprintf("%.2f", song$similarity))
      ),
      # Add the Spotify link button
      if (!is.na(song$spotify_url)) {
        a(
          href = song$spotify_url,
          target = "_blank",
          class = "spotify-link-button",
          img(src = "assets/spotify.svg", class = "spotify-icon"),
          span("Listen on Spotify!")
        )
      } else {
        NULL
      },
      # Add the chart below song details with 12px top margin
      div(
        style = "margin-top: 12px;",  # Apply 12px top margin
        plotOutput("songChart", height = "210px", width = "100%")
      )
    )
  })
  # Render the chart for the selected song comparison
  output$songChart <- renderPlot({
    song_id <- selected_song_id()
    if (is.null(song_id)) return(NULL)  # If no song is selected, don't render a chart

    # Get the selected song details
    recommendations <- recommended_songs()
    song1 <- recommendations[recommendations$id == song_id, ]

    if (nrow(song1) == 0) return(NULL)

    # Define the comparison song (e.g., the first recommended song)
    if (nrow(recommendations) > 1) {
      song2 <- recommendations[1, ]  # Use the first song as a comparison
      if (song2$id == song_id && nrow(recommendations) > 1) {
        song2 <- recommendations[2, ]  # Skip if the first is the selected song
      }
    } else {
      song2 <- song1  # Fallback: Compare the song to itself
    }

    # Extract song titles to pass to the updated function
    title1 <- song1$title
    title2 <- song2$title

    # Generate the chart using the updated function
    chart <- note_freq_chart_comparison_titles(title1, title2)
    print(chart)  # For debugging purposes, optional

    # Return the chart
    return(chart)
  })

}
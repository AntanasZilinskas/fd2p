# server.R
library(shiny)
library(methods)
library(shinyWidgets)
# Ensure global.R is sourced
source("global.R")
source("testing/charts/spider_chart.R")
source("testing/charts/note_freq_chart.R")

# Set the slider color globally (for all sliders)
setSliderColor("#F56C37", sliderId = 0)

server <- function(input, output, session) {
  # Initialize reactive values
  selected_songs <- reactiveVal(list())
  recommended_songs <- reactiveVal(NULL)
  has_analyzed <- reactiveVal(FALSE)

  # Watch for navigation attempts
  observeEvent(input$mainNav, {
    if (input$mainNav == "Analyse MDNA" && !has_analyzed()) {
      showModal(modalDialog(
        title = "Analysis Required",
        "Please analyze your selected songs first by clicking the Analyse button!",
        footer = actionButton("returnToSearch", "Return to Search", 
          class = "btn-primary",
          style = "background-color: #F56C37; border-color: #F56C37;"
        ),
        easyClose = FALSE
      ))
      updateNavbarPage(session, "mainNav", selected = "Search Songs")
    }
  })

  # Handle return to search button click
  observeEvent(input$returnToSearch, {
    removeModal()
    updateNavbarPage(session, "mainNav", selected = "Search Songs")
  })

  # Observe Analyze button click
  observeEvent(input$analyseBtn, {
    req(length(selected_songs()) >= 2)
    
    # Send message to start processing
    session$sendCustomMessage('analyseButtonProcessing', list(status = 'start'))
    
    # Perform the processing
    tryCatch({
      recommended_songs_data <- find_similar_songs(selected_songs(), top_n = 5L)
      recommended_songs(recommended_songs_data)
      has_analyzed(TRUE)
      
      # Only redirect if analysis was successful
      updateNavbarPage(session, "mainNav", selected = "Analyse MDNA")
      showNotification("Analysis complete!", type = "message")
    }, error = function(e) {
      showNotification(paste("An error occurred:", e$message), type = "error")
    }, finally = {
      session$sendCustomMessage('analyseButtonProcessing', list(status = 'end'))
    })
  })

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
  
  # Reactive value to store selected Nerd mode tab
  nerd_mode_tab <- reactiveVal("overview")
  
  # Define the tabs without 'Structure'
  nerd_tabs <- c("overview", "harmonics", "melody", "rhythm")
  
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
        # Remove duplicate titles from initial results
        results <- results[!duplicated(results$title), , drop = FALSE]
        
        # Get current selected songs
        current_songs <- selected_songs()
        
        # Filter out titles that are already selected
        new_results <- results[!results$title %in% current_songs, , drop = FALSE]
        
        # Update search results directly
        search_results(new_results)
        # Show search results if we have any new ones
        show_search_results(nrow(new_results) > 0)
        
        if (nrow(new_results) == 0) {
          showNotification("All matching songs are already selected.", type = "warning")
        }
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
    if (!is.null(query)) {
      if (query != "") {
        perform_search(query)
      } else {
        # If input is empty but we have previous results, show them
        results <- search_results()
        if (nrow(results) > 0) {
          show_search_results(TRUE)
        }
      }
    }
  }, ignoreInit = TRUE)
  
  # Send a custom message to set up click handlers
  observe({
    # Send a custom message to set up the click handler for search results
    session$sendCustomMessage("setupSearchResultClick", TRUE)
    
    # Send a custom message to set up the search input click handler
    session$sendCustomMessage("setupSearchInputClick", list(
      inputId = "searchInput"
    ))
  })
  
  # Handle clicking on search input to show previous results
  observeEvent(input$searchInput_clicked, {
    print("Search input clicked")
    results <- search_results()
    if (nrow(results) > 0) {
      print("Showing previous search results")
      show_search_results(TRUE)
    }
  }, ignoreInit = TRUE)
  
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
    
    # Hide search results immediately after selection
    show_search_results(FALSE)
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
  
  # Add a session listener for custom messages
  session$onFlushed(function() {
    session$sendCustomMessage("initialize_spinner", TRUE)
  })
  
  # Observe changes in selected songs to enable/disable Analyse button
  observe({
    songs <- selected_songs()
    if (length(songs) < 2) {
      shinyjs::disable("analyseBtn")
      # Optional: add visual feedback about why it's disabled
      shinyjs::addClass("analyseBtn", "disabled")
      # Update tooltip or hint
      shinyjs::runjs("document.getElementById('analyseBtn').title = 'Select at least 2 songs to analyze';")
    } else {
      shinyjs::enable("analyseBtn")
      shinyjs::removeClass("analyseBtn", "disabled")
      shinyjs::runjs("document.getElementById('analyseBtn').title = '';")
    }
  })
  
  # Observe the song click event
  observeEvent(input$song_clicked, {
    selected_song_id(input$song_clicked)
  })
  
  # Observe tab link clicks
  lapply(nerd_tabs, function(tab_name) {
    observeEvent(input[[paste0("nerdTab_", tab_name)]], {
      nerd_mode_tab(tab_name)
    })
  })
  
  # Render content based on selected Nerd mode tab
  output$nerdModeContent <- renderUI({
    tab <- nerd_mode_tab()
    switch(tab,
           "overview" = {
             div(
               class = "overview-container",
               # Center icon with title
               div(
                 class = "center-icon",
                 img(src = "assets/your-mdna.svg", class = "your-mdna-icon"),
                 span(class = "mdna-label", "Your MDNA")
               ),
               # Visualization of recommended songs
               uiOutput("recommendedSongsVisualization")
             )
           },
           "harmonics" = {
             # Content for the Harmonics tab
             plotOutput("harmonicsChart", height = "400px", width = "100%")
           },
           "melody" = {
             # Content for the Melody tab
             div("This is the Melody content.")
           },
           "rhythm" = {
             # Content for the Rhythm tab
             selected_data <- selected_song_tempo_duration()
             average_data <- average_tempo_duration()
             
             if (is.null(selected_data) || is.null(average_data)) {
               div("Tempo and note duration data not available.")
             } else {
               div(
                 class = "rhythm-container",
                 # Introduction text
                 div(
                   class = "rhythm-intro",
                   h3("Rhythm Analysis and Song Discovery"),
                   p("Adjust the tempo and note duration to find songs with similar rhythmic patterns. 
                     The current values are based on your selected songs' average.")
                 ),
                 
                 # Tempo section
                 div(
                   class = "rhythm-section",
                   h4("Tempo Comparison"),
                   div(
                     class = "rhythm-values",
                     div(
                       class = "rhythm-value",
                       span(class = "value-label", "Average Tempo:"),
                       span(class = "value-number", paste(round(average_data$tempo, 0), "BPM"))
                     ),
                     div(
                       class = "rhythm-value",
                       span(class = "value-label", "Selected Song:"),
                       span(class = "value-number", paste(round(selected_data$tempo, 0), "BPM"))
                     )
                   ),
                   div(
                     class = "custom-slider",
                     sliderInput(
                       inputId = "tempo_adjustment",
                       label = "Adjust Tempo:",
                       min = 0,
                       max = 1000,
                       value = average_data$tempo,
                       step = 1,
                       post = " BPM"
                     )
                   )
                 ),
                 
                 # Note Duration section
                 div(
                   class = "rhythm-section",
                   h4("Average Note Duration"),
                   div(
                     class = "rhythm-values",
                     div(
                       class = "rhythm-value",
                       span(class = "value-label", "Average Duration:"),
                       span(class = "value-number", paste(round(average_data$average_note_duration, 0), "ms"))
                     ),
                     div(
                       class = "rhythm-value",
                       span(class = "value-label", "Selected Song:"),
                       span(class = "value-number", paste(round(selected_data$average_note_duration, 0), "ms"))
                     )
                   ),
                   div(
                     class = "custom-slider",
                     sliderInput(
                       inputId = "duration_adjustment",
                       label = "Adjust Note Duration:",
                       min = 0,
                       max = 1000,
                       value = average_data$average_note_duration,
                       step = 1,
                       post = " ms"
                     )
                   )
                 ),
                 
                 # Action button section
                 div(
                   class = "rhythm-action",
                   actionButton(
                     inputId = "analyze_button",
                     label = "Find Similar Songs",
                     class = "analyze-button",
                     icon = icon("search")
                   ),
                   div(
                     class = "action-hint",
                     "Adjust the values above and click to discover songs with similar rhythmic patterns"
                   )
                 )
               )
             }
           },
           # Default case
           div("Select a tab.")
    )
  })
  
  # Render the MDNA content based on Nerd mode
  output$mdnaContent <- renderUI({
    recommendations <- recommended_songs()
    
    if (nrow(recommendations) == 0) {
      return(NULL)
    } else {
      # Left side container
      left_container <- div(
        class = "left-side-container",
        if (input$nerdMode) {
          # Content for Nerd mode
          tagList(
            # Tabs at the top
            div(
              class = "nerd-mode-tabs",
              # Generate tabs
              lapply(nerd_tabs, function(tab_name) {
                tab_label <- tools::toTitleCase(tab_name)
                # Determine if this tab is selected
                tab_class <- "nerd-tab"
                if (nerd_mode_tab() == tab_name) {
                  tab_class <- paste(tab_class, "selected")
                }
                # Create tab button
                actionLink(
                  inputId = paste0("nerdTab_", tab_name),
                  label = tab_label,
                  class = tab_class
                )
              })
            ),
            # Visualization content based on selected tab
            div(
              class = "mdna-visualization-container-nerd",
              uiOutput("nerdModeContent")
            )
          )
        } else {
          # Content for non-Nerd mode
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
          )
        }
      )
      
      # Right-side song details container
      right_container <- div(
        class = "song-details-container-custom",
        uiOutput("songDetails")
      )
      
      # Main container including left and right components
      div(
        class = "mdna-main-container",
        left_container,
        right_container
      )
    }
  })
  
  # Render the song details in the right container
  output$songDetails <- renderUI({
    song_id <- selected_song_id()
    recommendations <- recommended_songs()
    
    if (is.null(song_id) || nrow(recommendations) == 0) {
      return(
        div(
          class = "song-details-placeholder",
          "Click on a song to see details."
        )
      )
    }

    # Ensure both are character type for comparison
    song <- recommendations[as.character(recommendations$id) == as.character(song_id), , drop = FALSE]

    if (nrow(song) == 0) {
      return(div(
        class = "song-details-placeholder",
        "Song details not available."
      ))
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
      if (!is.null(song$spotify_url) && !is.na(song$spotify_url)) {
        a(
          href = song$spotify_url,
          target = "_blank",
          class = "spotify-link-button",
          img(src = "assets/spotify.svg", class = "spotify-icon"),
          span("Listen on Spotify!")
        )
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
    # Ensure both are character type for comparison
    song1 <- recommendations[as.character(recommendations$id) == as.character(song_id), , drop = FALSE]

    if (nrow(song1) == 0) return(NULL)

    # Generate the chart using your existing function
    chart <- spider_chart_compare_with_average(song1$title, selected_songs())

    # Return the chart
    chart
  })
  
  # Render recommended songs visualization on the MDNA page
  output$recommendedSongsVisualization <- renderUI({
    recommendations <- recommended_songs()
    
    if (is.null(recommendations) || nrow(recommendations) == 0) {
      return(NULL)
    }

    max_distance <- 150  # Adjust based on container size
    center_x <- 0
    center_y <- 0

    # Ensure similarity scores are available and numeric
    similarity_scores <- as.numeric(as.character(recommendations$similarity))
    if (length(similarity_scores) == 0) {
      return(NULL)
    }
    
    min_score <- min(similarity_scores, na.rm = TRUE)
    max_score <- max(similarity_scores, na.rm = TRUE)
    score_range <- max_score - min_score
    
    # Handle case where all scores are the same
    if (score_range == 0) {
      normalized_scores <- rep(0.5, length(similarity_scores))
    } else {
      normalized_scores <- (similarity_scores - min_score) / score_range
    }

    num_songs <- nrow(recommendations)
    angle_increment <- 360 / num_songs

    # Generate UI elements for each song
    song_elements <- lapply(1:num_songs, function(i) {
      song <- recommendations[i, , drop = FALSE]
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
      is_selected <- !is.null(selected_id) && 
                    !is.null(song$id) && 
                    as.character(song$id) == as.character(selected_id)
      
      icon_src <- if (is_selected) "assets/selected-song.svg" else "assets/suggested-songs.svg"

      # Create a div for the song icon with onclick event
      tags$div(
        class = "suggested-song",
        style = position_style,
        `data-song-id` = song$id,  # For JavaScript access
        # Tooltip with song details
        title = paste(
          "Title:", song$title, "\n",
          "Artists:", song$creators, "\n",
          "Similarity Score:", sprintf("%.2f", as.numeric(as.character(song$similarity)))
        ),
        img(
          src = icon_src,
          class = "suggested-song-icon",
          onclick = sprintf(
            "event.stopPropagation(); Shiny.setInputValue('song_clicked', '%s', {priority: 'event'});",
            song$id
          )
        )
      )
    })

    # Return the list of song elements
    do.call(tagList, song_elements)
  })
  
  # Reactive expression to get the selected song's features
  selected_song_features <- reactive({
    song_id <- selected_song_id()
    if (is.null(song_id)) {
      print("selected_song_features: song_id is NULL")
      return(NULL)
    }
    
    recommendations <- recommended_songs()
    print(paste("selected_song_features: recommendations available:", !is.null(recommendations)))
    if (is.null(recommendations) || nrow(recommendations) == 0) return(NULL)
    
    # Ensure both are character type for comparison
    song <- recommendations[as.character(recommendations$id) == as.character(song_id), , drop = FALSE]
    print(paste("selected_song_features: found song in recommendations:", nrow(song) > 0))
    if (nrow(song) == 0) return(NULL)
    
    print(paste("selected_song_features: song title:", song$title))
    song_details <- get_song_details_by_title(song$title)
    print(paste("selected_song_features: got song details:", !is.null(song_details)))
    if (is.null(song_details) || length(song_details) == 0) {
      # If we can't get song details, use the data from recommendations
      print("selected_song_features: using data from recommendations")
      
      # Ensure we have a proper feature vector
      feature_vector <- song$feature_vector
      if (!is.null(feature_vector) && !is.numeric(feature_vector)) {
        feature_vector <- as.numeric(unlist(strsplit(gsub("\\[|\\]", "", feature_vector), ",")))
      }
      
      return(list(
        feature_vector = feature_vector,
        tempo = song$tempo,
        average_duration = song$average_duration,
        pitch_class_histogram = numeric(12),  # Default empty histograms
        interval_histogram = numeric(12),
        melodic_contour = numeric(12),
        chord_progressions = numeric(12),
        note_duration_histogram = numeric(12),
        time_signatures = numeric(0)
      ))
    }
    
    print(paste("selected_song_features: feature vector available:", !is.null(song_details[[1]]$feature_vector)))
    return(song_details[[1]])
  })
  
  # Function to extract average note duration and tempo from feature vector
  extract_tempo_and_duration <- function(feature_vector) {
    # Convert feature vector to numeric vector if not already
    if (!is.numeric(feature_vector)) {
      feature_vector <- as.numeric(unlist(strsplit(gsub("\\[|\\]", "", feature_vector), ",")))
    }
    
    # Average Note Duration at index 73
    average_note_duration_index <- 73
    # Tempo at index 74
    tempo_index <- 74
    
    # Get normalized values (between 0 and 1)
    average_note_duration_normalized <- feature_vector[average_note_duration_index]
    tempo_normalized <- feature_vector[tempo_index]
    
    # Scale to actual values (up to 1000)
    average_note_duration <- average_note_duration_normalized * 1000  # in milliseconds
    tempo <- tempo_normalized * 1000  # in BPM
    
    return(list(
      average_note_duration = average_note_duration,
      tempo = tempo
    ))
  }
  
  # Reactive expression to get the average features
  average_features_data <- reactive({
    if (length(selected_songs()) == 0) {
      print("average_features_data: no songs selected")
      return(NULL)
    }
    
    print("average_features_data: getting average features")
    average_features <- average_from_titles(selected_songs())
    if (is.null(average_features) || length(average_features) == 0) {
      print("average_features_data: failed to get average features")
      return(NULL)
    }
    
    print("average_features_data: got average features")
    print("Feature vector:")
    print(average_features[[1]]$feature_vector)
    return(average_features[[1]])
  })
  
  # Reactive expression to get tempo and duration for selected song
  selected_song_tempo_duration <- reactive({
    features <- selected_song_features()
    print("selected_song_tempo_duration: got features")
    if (is.null(features)) {
      print("selected_song_tempo_duration: features is NULL")
      return(NULL)
    }
    
    # First try to get tempo and duration directly
    if (!is.null(features$tempo) && !is.null(features$average_duration)) {
      print("selected_song_tempo_duration: using direct tempo and duration")
      return(list(
        tempo = features$tempo,
        average_note_duration = features$average_duration
      ))
    }
    
    # If not available, try to extract from feature vector
    feature_vector <- features$feature_vector
    if (is.null(feature_vector)) {
      print("selected_song_tempo_duration: feature vector is NULL")
      return(NULL)
    }
    
    print("selected_song_tempo_duration: extracting from feature vector")
    result <- extract_tempo_and_duration(feature_vector)
    print(paste("selected_song_tempo_duration: extracted values -",
                "tempo:", result$tempo,
                "duration:", result$average_note_duration))
    return(result)
  })
  
  # Reactive expression to get tempo and duration for average features
  average_tempo_duration <- reactive({
    features <- average_features_data()
    if (is.null(features)) {
      print("average_tempo_duration: features is NULL")
      return(NULL)
    }
    
    # First try to get tempo and duration directly
    if (!is.null(features$tempo) && !is.null(features$average_duration)) {
      print("average_tempo_duration: using direct tempo and duration")
      return(list(
        tempo = features$tempo,
        average_note_duration = features$average_duration
      ))
    }
    
    # If not available, try to extract from feature vector
    feature_vector <- features$feature_vector
    if (is.null(feature_vector)) {
      print("average_tempo_duration: feature vector is NULL")
      return(NULL)
    }
    
    print("average_tempo_duration: extracting from feature vector")
    result <- extract_tempo_and_duration(feature_vector)
    print(paste("average_tempo_duration: extracted values -",
                "tempo:", result$tempo,
                "duration:", result$average_note_duration))
    return(result)
  })
  
  # Add analyze button handler for the rhythm tab
  observeEvent(input$analyze_button, {
    print("Analyze button clicked")
    # Get current average features
    avg_features <- average_features_data()
    if (is.null(avg_features)) {
      print("analyze_button: average features is NULL")
      showNotification("Could not get average features", type = "error")
      return()
    }
    
    print("analyze_button: got average features")
    print("Current feature vector:")
    print(avg_features$feature_vector)
    
    # Get the feature vector
    feature_vector <- avg_features$feature_vector
    if (!is.numeric(feature_vector)) {
      print("analyze_button: converting feature vector to numeric")
      feature_vector <- as.numeric(unlist(strsplit(gsub("\\[|\\]", "", feature_vector), ",")))
    }
    
    # Update both tempo and duration with current slider values
    print(paste("analyze_button: current tempo adjustment:", input$tempo_adjustment))
    print(paste("analyze_button: current duration adjustment:", input$duration_adjustment))
    
    feature_vector[74] <- input$tempo_adjustment / 1000  # Tempo
    feature_vector[73] <- input$duration_adjustment / 1000  # Duration
    
    print("analyze_button: updated feature vector:")
    print(feature_vector)
    
    # Convert the feature vector to JSON string
    vector_json <- jsonlite::toJSON(feature_vector)
    print("analyze_button: JSON vector:")
    print(vector_json)
    
    # Prepare the API request for similar songs
    url <- "https://dvplamwokfwyvuaskgyk.supabase.co/rest/v1/rpc/find_similar_songs_by_vector"
    
    # Use the service role key for this operation
    supabase_key <- Sys.getenv("SUPABASE_SERVICE_KEY")
    if (supabase_key == "") {
      showNotification("Supabase SERVICE API key is not set", type = "error")
      return()
    }
    
    headers <- c(
      "Content-Type" = "application/json",
      "apikey" = supabase_key,
      "Authorization" = paste("Bearer", supabase_key)
    )
    body <- list(
      input_vector = vector_json,
      top_n = 5
    )
    
    # Show processing state
    shinyjs::addClass(id = "analyze_button", class = "processing")
    shinyjs::disable("analyze_button")
    
    # Make the API request
    tryCatch({
      print("analyze_button: making API request")
      response <- httr::POST(
        url = url,
        httr::add_headers(.headers = headers),
        body = jsonlite::toJSON(body, auto_unbox = TRUE),
        encode = "json"
      )
      
      print(paste("analyze_button: API response status:", httr::status_code(response)))
      
      if (httr::status_code(response) == 200) {
        # Parse the response
        results <- httr::content(response, "parsed")
        print(paste("analyze_button: got", length(results), "results"))
        
        # Get the titles of similar songs
        similar_titles <- sapply(results, function(x) x$title)
        print("analyze_button: similar song titles:")
        print(similar_titles)
        
        # Use find_similar_songs to get complete song data
        recommended_songs_data <- find_similar_songs(similar_titles, top_n = length(similar_titles))
        
        if (!is.null(recommended_songs_data) && nrow(recommended_songs_data) > 0) {
          print("analyze_button: got complete song data")
          # Update the recommendations with the complete data
          recommended_songs(recommended_songs_data)
          
          # Select the first song by default
          selected_song_id(recommended_songs_data$id[1])
          
          # Switch to the overview tab
          nerd_mode_tab("overview")
          
          # Show notification about new songs
          showNotification(
            paste("Found", nrow(recommended_songs_data), "new songs based on your rhythm adjustments! Check them out in the overview."),
            type = "message",
            duration = 5
          )
        } else {
          print("analyze_button: failed to get complete song data")
          showNotification("Error getting complete song data", type = "error")
        }
      } else {
        print(paste("analyze_button: API error -", httr::content(response, "text")))
        showNotification("Error fetching similar songs", type = "error")
      }
    }, error = function(e) {
      print(paste("analyze_button error:", e$message))
      showNotification(paste("Error:", e$message), type = "error")
    }, finally = {
      # Remove processing state
      shinyjs::removeClass(id = "analyze_button", class = "processing")
      shinyjs::enable("analyze_button")
    })
  })
  
  # Reactive expression to generate the note frequency chart data
  note_freq_chart_data <- reactive({
    # Ensure a song is selected
    song_id <- selected_song_id()
    if (is.null(song_id)) return(NULL)
    
    # Get the selected song title
    recommendations <- recommended_songs()
    song <- recommendations[as.character(recommendations$id) == as.character(song_id), , drop = FALSE]
    if (nrow(song) == 0) return(NULL)
    
    selected_song_title <- song$title
    print(paste("note_freq_chart_data: processing song:", selected_song_title))
    
    # Get the song details using existing functions
    song_details <- get_song_details_by_title(selected_song_title)
    if (is.null(song_details) || length(song_details) == 0) {
      print("note_freq_chart_data: using data from recommendations")
      # Create a song details list with default values
      song_details <- list(list(
        feature_vector = song$feature_vector,
        pitch_class_histogram = numeric(12),
        interval_histogram = numeric(12),
        melodic_contour = numeric(12),
        chord_progressions = numeric(12),
        note_duration_histogram = numeric(12),
        time_signatures = numeric(0)
      ))
    }
    
    # Get the average features from the selected songs
    average_features <- average_from_titles(selected_songs())
    if (is.null(average_features) || length(average_features) == 0) {
      print("note_freq_chart_data: using default average features")
      # Create default average features
      average_features <- list(list(
        feature_vector = numeric(128),
        pitch_class_histogram = numeric(12),
        interval_histogram = numeric(12),
        melodic_contour = numeric(12),
        chord_progressions = numeric(12),
        note_duration_histogram = numeric(12),
        time_signatures = numeric(0)
      ))
    }
    
    print("note_freq_chart_data: generating chart")
    # Generate the note frequency comparison chart
    chart <- note_freq_chart_comparison(average_features, song_details)
    
    return(chart)
  })

  # Render the harmonics chart
  output$harmonicsChart <- renderPlot({
    chart <- note_freq_chart_data()
    if (!is.null(chart)) {
      print(chart)  # Display the chart
    } else {
      # Optional: Display a message when no song is selected
      plot.new()
      text(0.5, 0.5, "Select a song to view the harmonics chart.", cex = 1.2)
    }
  })
  
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
          div(
            class = "search-result-content",
            tags$span(class = "song-title-text", song_title),
            tags$span(class = "add-text", "Click to add")
          )
        )
      }),
      tags$style(HTML("
        .search-result-content {
          display: flex;
          justify-content: space-between;
          align-items: center;
          width: 100%;
          padding: 8px 12px;
        }
        .add-text {
          color: #F56C37;
          font-size: 14px;
          font-weight: 500;
          opacity: 0;
          transition: opacity 0.2s ease;
          margin-left: 12px;
        }
        .search-result-item:hover .add-text {
          opacity: 1;
        }
        .song-title-text {
          flex: 1;
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
        }
      "))
    )
  })
  
  # Expose analysis state to the UI
  output$hasAnalysis <- reactive({
    !is.null(recommended_songs())
  })
  outputOptions(output, "hasAnalysis", suspendWhenHidden = FALSE)
}
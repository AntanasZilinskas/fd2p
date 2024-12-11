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
  nerd_mode <- reactiveVal(FALSE)

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
             div(
               class = "harmonics-container",
               div(
                 class = "harmonics-section",
                 h4("Note Distribution"),
                 div(
                   class = "description-box",
                   p("Discover songs based on which musical notes appear most often. This is like finding songs that use similar piano keys!"),
                   div(
                     class = "chart-legend",
                     tags$span(class = "legend-item", tags$span(class = "legend-color orange"), "Orange bars: Your selected song"),
                     tags$span(class = "legend-item", tags$span(class = "legend-color grey"), "Grey bars: Average of your selections"),
                     tags$span(class = "legend-item", tags$span(class = "legend-color blue"), "Blue bars: Your adjustments")
                   ),
                   p(strong("How to use the sliders:"), "Move them up or down to emphasize different notes:"),
                   tags$ul(
                     tags$li(strong("For rock/pop songs:"), "Boost C, G, and F - these are common in popular music"),
                     tags$li(strong("For jazzy tunes:"), "Increase the black keys (C#, D#, F#, G#, A#)"),
                     tags$li(strong("For emotional ballads:"), "Emphasize E and A - often used in emotional passages"),
                     tags$li(strong("For complex harmonies:"), "Try raising several notes together to find songs with rich chord structures")
                   ),
                   p(class = "tip", icon("lightbulb"), " Pro tip: Start by matching the orange bars, then adjust to find variations you might like!")
                 ),
                 div(
                   class = "pitch-chart",
                   plotOutput("harmonicsChart", height = "400px", width = "100%")
                 ),
                 div(
                   class = "pitch-sliders",
                   fluidRow(
                     column(4, sliderInput("pitch_0", "C", min = 0, max = 1, value = 0.5, step = 0.01)),
                     column(4, sliderInput("pitch_1", "C#", min = 0, max = 1, value = 0.5, step = 0.01)),
                     column(4, sliderInput("pitch_2", "D", min = 0, max = 1, value = 0.5, step = 0.01))
                   ),
                   fluidRow(
                     column(4, sliderInput("pitch_3", "D#", min = 0, max = 1, value = 0.5, step = 0.01)),
                     column(4, sliderInput("pitch_4", "E", min = 0, max = 1, value = 0.5, step = 0.01)),
                     column(4, sliderInput("pitch_5", "F", min = 0, max = 1, value = 0.5, step = 0.01))
                   ),
                   fluidRow(
                     column(4, sliderInput("pitch_6", "F#", min = 0, max = 1, value = 0.5, step = 0.01)),
                     column(4, sliderInput("pitch_7", "G", min = 0, max = 1, value = 0.5, step = 0.01)),
                     column(4, sliderInput("pitch_8", "G#", min = 0, max = 1, value = 0.5, step = 0.01))
                   ),
                   fluidRow(
                     column(4, sliderInput("pitch_9", "A", min = 0, max = 1, value = 0.5, step = 0.01)),
                     column(4, sliderInput("pitch_10", "A#", min = 0, max = 1, value = 0.5, step = 0.01)),
                     column(4, sliderInput("pitch_11", "B", min = 0, max = 1, value = 0.5, step = 0.01))
                   )
                 ),
                 div(
                   class = "rhythm-action",
                   actionButton("findSimilarPitch", 
                               "Find Songs With This Pattern", 
                               class = "analyze-button",
                               icon = icon("search"))
                 )
               )
             )
           },
           "melody" = {
             # Content for the Melody tab
             div(
               class = "melody-container",
               div(
                 class = "melody-section",
                 h4("Melodic Movement"),
                 div(
                   class = "description-box",
                   p("Shape how the melody flows by controlling how far notes jump from one to the next. Think of it as adjusting how 'jumpy' or 'smooth' a melody is!"),
                   div(
                     class = "chart-legend",
                     tags$span(class = "legend-item", tags$span(class = "legend-color orange"), "Orange bars: Your selected song"),
                     tags$span(class = "legend-item", tags$span(class = "legend-color grey"), "Grey bars: Average of your selections"),
                     tags$span(class = "legend-item", tags$span(class = "legend-color blue"), "Blue bars: Your adjustments")
                   ),
                   p(strong("Understanding the numbers:"), "Each slider represents the distance between consecutive notes:"),
                   tags$ul(
                     tags$li(strong("0-2 (Unison to Major Second):"), "Smooth, stepwise melodies like 'Let It Be'"),
                     tags$li(strong("3-5 (Thirds and Fourth):"), "Natural, singable jumps like 'Somewhere Over the Rainbow'"),
                     tags$li(strong("6-7 (Tritone and Fifth):"), "Bold jumps like the start of 'The Simpsons Theme'"),
                     tags$li(strong("8-12 (Sixths to Octave):"), "Dramatic leaps like 'Somewhere' from West Side Story")
                   ),
                   div(
                     class = "try-these",
                     p(strong("Try these combinations:")),
                     tags$ul(
                       tags$li(strong("Pop melody:"), "Higher values for 0-5, lower for larger jumps"),
                       tags$li(strong("Jazz style:"), "Increase larger intervals for more adventurous melodies"),
                       tags$li(strong("Folk song:"), "Focus on 2-5 for traditional-sounding tunes")
                     )
                   ),
                   p(class = "tip", icon("lightbulb"), " Pro tip: Start with the pattern you see in orange, then gradually adjust to explore new melodic territories!")
                 ),
                 div(
                   class = "interval-chart",
                   plotOutput("intervalHistogram", height = "400px", width = "100%")
                 ),
                 div(
                   class = "interval-sliders",
                   fluidRow(
                     column(4, sliderInput("interval_0", "Unison (0)", min = 0, max = 1, value = 0.5, step = 0.01)),
                     column(4, sliderInput("interval_1", "Minor Second (1)", min = 0, max = 1, value = 0.5, step = 0.01)),
                     column(4, sliderInput("interval_2", "Major Second (2)", min = 0, max = 1, value = 0.5, step = 0.01))
                   ),
                   fluidRow(
                     column(4, sliderInput("interval_3", "Minor Third (3)", min = 0, max = 1, value = 0.5, step = 0.01)),
                     column(4, sliderInput("interval_4", "Major Third (4)", min = 0, max = 1, value = 0.5, step = 0.01)),
                     column(4, sliderInput("interval_5", "Perfect Fourth (5)", min = 0, max = 1, value = 0.5, step = 0.01))
                   ),
                   fluidRow(
                     column(4, sliderInput("interval_6", "Tritone (6)", min = 0, max = 1, value = 0.5, step = 0.01)),
                     column(4, sliderInput("interval_7", "Perfect Fifth (7)", min = 0, max = 1, value = 0.5, step = 0.01)),
                     column(4, sliderInput("interval_8", "Minor Sixth (8)", min = 0, max = 1, value = 0.5, step = 0.01))
                   ),
                   fluidRow(
                     column(4, sliderInput("interval_9", "Major Sixth (9)", min = 0, max = 1, value = 0.5, step = 0.01)),
                     column(4, sliderInput("interval_10", "Minor Seventh (10)", min = 0, max = 1, value = 0.5, step = 0.01)),
                     column(4, sliderInput("interval_11", "Major Seventh (11)", min = 0, max = 1, value = 0.5, step = 0.01))
                   )
                 ),
                 div(
                   class = "rhythm-action",
                   actionButton("findSimilarIntervals", 
                               "Find Songs With This Movement", 
                               class = "analyze-button",
                               icon = icon("search"))
                 )
               )
             )
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
                   class = "rhythm-section",
                   h4("Rhythm Analysis"),
                   div(
                     class = "description-box",
                     p("Shape the groove and feel of the music by adjusting tempo (speed) and note duration (how long notes are held)."),
                     div(
                       class = "chart-legend",
                       tags$span(class = "legend-item", tags$span(class = "legend-color orange"), "Orange values: Your selected song"),
                       tags$span(class = "legend-item", tags$span(class = "legend-color grey"), "Grey values: Average of your selections")
                     ),
                     p(strong("Understanding the controls:")),
                     tags$ul(
                       tags$li(strong("Tempo (BPM):"), "Beats Per Minute - how fast the music moves. Like a heartbeat, higher numbers mean faster music."),
                       tags$li(strong("Note Duration:"), "How long each note is held. Shorter durations create crisp, staccato feels, longer ones create smooth, flowing music.")
                     ),
                     div(
                       class = "try-these",
                       p(strong("Try these tempo ranges:")),
                       tags$ul(
                         tags$li(strong("60-75 BPM:"), "Ballads and slow jams (e.g., 'Yesterday' by The Beatles)"),
                         tags$li(strong("90-120 BPM:"), "Pop and rock songs (e.g., 'Billie Jean' by Michael Jackson)"),
                         tags$li(strong("120-140 BPM:"), "Upbeat dance music (e.g., 'Dancing Queen' by ABBA)"),
                         tags$li(strong("140+ BPM:"), "High-energy dance and electronic music")
                       )
                     ),
                     p(class = "tip", icon("lightbulb"), " Pro tip: Start with the tempo of a song you love, then explore slightly faster or slower to find new favorites!")
                   )
                 ),
                 
                 # Tempo section
                 div(
                   class = "rhythm-section",
                   h4("Tempo"),
                   div(
                     class = "rhythm-values",
                     div(
                       class = "rhythm-value",
                       span(class = "value-label", "Average Tempo:"),
                       span(class = "value-number grey", paste(round(average_data$tempo, 0), "BPM"))
                     ),
                     div(
                       class = "rhythm-value",
                       span(class = "value-label", "Selected Song:"),
                       span(class = "value-number orange", paste(round(selected_data$tempo, 0), "BPM"))
                     )
                   ),
                   div(
                     class = "custom-slider",
                     sliderInput(
                       inputId = "tempo_adjustment",
                       label = "Adjust Tempo:",
                       min = 40,  # Changed from 0 to more realistic minimum
                       max = 200, # Changed from 1000 to more realistic maximum
                       value = average_data$tempo,
                       step = 1,
                       post = " BPM"
                     )
                   )
                 ),
                 
                 # Note Duration section
                 div(
                   class = "rhythm-section",
                   h4("Note Duration"),
                   div(
                     class = "rhythm-values",
                     div(
                       class = "rhythm-value",
                       span(class = "value-label", "Average Duration:"),
                       span(class = "value-number grey", paste(round(average_data$average_note_duration, 0), "ms"))
                     ),
                     div(
                       class = "rhythm-value",
                       span(class = "value-label", "Selected Song:"),
                       span(class = "value-number orange", paste(round(selected_data$average_note_duration, 0), "ms"))
                     )
                   ),
                   div(
                     class = "custom-slider",
                     sliderInput(
                       inputId = "duration_adjustment",
                       label = "Adjust Note Duration:",
                       min = 50,   # Changed from 0 to more realistic minimum
                       max = 500,  # Changed from 1000 to more realistic maximum
                       value = average_data$average_note_duration,
                       step = 10,  # Changed to make adjustments easier
                       post = " ms"
                     )
                   )
                 ),
                 
                 # Action button section
                 div(
                   class = "rhythm-action",
                   actionButton(
                     inputId = "analyze_button",
                     label = "Find Songs With This Groove",
                     class = "analyze-button",
                     icon = icon("search")
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

    song <- recommendations[as.character(recommendations$id) == as.character(song_id), , drop = FALSE]

    if (nrow(song) == 0) {
        return(div(
            class = "song-details-placeholder",
            "Song details not available."
        ))
    }

    div(
        class = "song-details-custom",
        h3(class = "song-title-custom", song$title),
        p(class = "song-artist-custom", paste("Artist:", song$creators)),
        p(
            class = "song-similarity-custom", 
            paste("Similarity Score:", 
              if (nerd_mode()) {
                paste0(round(song$similarity * 100, 2), "% match")
              } else {
                paste0(round(song$similarity * 100, 0), "% match")
              }
            )
        ),
        if (!is.null(song$spotify_url) && !is.na(song$spotify_url)) {
            div(
                class = "spotify-section",
                a(
                    href = song$spotify_url,
                    target = "_blank",
                    class = "spotify-link-button",
                    img(src = "assets/spotify.svg", class = "spotify-icon"),
                    span("Listen on Spotify!")
                ),
                p(class = "chart-title", "Musical profile radar chart"),
                div(
                    class = "chart-legend-custom",
                    div(
                        class = "legend-item-custom",
                        span(class = "legend-dot grey"),
                        span("your preference"),
                        span(class = "legend-separator"),
                        span(class = "legend-dot orange"),
                        span("selected song")
                    )
                )
            )
        },
        div(
            class = "song-chart-container",
            plotOutput("songChart", 
                       height = "300px",     
                       width = "400%"
            )
        )
    )
  })
  
  # Render the chart for the selected song comparison
  output$songChart <- renderPlot({
    song_id <- selected_song_id()
    if (is.null(song_id)) return(NULL)
    
    recommendations <- recommended_songs()
    song1 <- recommendations[as.character(recommendations$id) == as.character(song_id), , drop = FALSE]
    
    if (nrow(song1) == 0) return(NULL)
    
    # Set a fixed size for the plot device
    par(mar = c(1, 1, 1, 1))  # Reduce margins
    
    # Create a new graphics device for this plot
    tryCatch({
      # Generate the chart
      spider_chart_compare_with_average(song1$title, selected_songs())
      
      # Clean up the plot device
      par(mar = c(5, 4, 4, 2) + 0.1)  # Reset to default margins
    }, error = function(e) {
      # Log any errors
      message("Error generating spider chart: ", e$message)
      return(NULL)
    })
  }, 
  height = function() 300,  # Reduced height
  width = function() 400,   # Reduced width
  res = 96 * 2,            # Double the resolution for sharper rendering
  execOnResize = FALSE)    # Prevent resizing on window changes
  
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
          "Similarity Score:", 
          if (nerd_mode()) {
            paste0(round(song$similarity * 100, 2), "% match")
          } else {
            paste0(round(song$similarity * 100, 0), "% match")
          }
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

  # Calculate average pitch class distribution
  average_pitch <- reactive({
    # Get the average features from selected songs
    avg_features <- average_features_data()
    if (is.null(avg_features)) return(NULL)
    
    # Extract pitch class histogram and ensure it's numeric
    hist <- avg_features$pitch_class_histogram
    if (!is.numeric(hist)) {
      # Convert from JSON if needed
      hist <- as.numeric(unlist(strsplit(gsub("\\[|\\]", "", hist), ",")))
    }
    # Normalize
    if (sum(hist) > 0) hist <- hist / sum(hist)
    hist
  })

  # Get current song's pitch class distribution
  current_pitch <- reactive({
    # Get features for the selected song
    features <- selected_song_features()
    if (is.null(features)) return(NULL)
    
    # Extract pitch class histogram and ensure it's numeric
    hist <- features$pitch_class_histogram
    if (!is.numeric(hist)) {
      # Convert from JSON if needed
      hist <- as.numeric(unlist(strsplit(gsub("\\[|\\]", "", hist), ",")))
    }
    # Normalize
    if (sum(hist) > 0) hist <- hist / sum(hist)
    hist
  })

  # Create the harmonics chart
  output$harmonicsChart <- renderPlot({
    avg_dist <- average_pitch()
    curr_dist <- current_pitch()
    
    if (is.null(avg_dist) || is.null(curr_dist)) {
      # If no data available, show empty plot with message
      plot.new()
      text(0.5, 0.5, "Select a song to view note distribution", cex = 1.2)
      return()
    }
    
    # Get user preferences from sliders and ensure they're numeric
    user_dist <- as.numeric(c(
      input$pitch_0, input$pitch_1, input$pitch_2,
      input$pitch_3, input$pitch_4, input$pitch_5,
      input$pitch_6, input$pitch_7, input$pitch_8,
      input$pitch_9, input$pitch_10, input$pitch_11
    ))
    
    # Normalize user distribution if sum is greater than 0
    if (sum(user_dist) > 0) {
      user_dist <- user_dist / sum(user_dist)
    }
    
    # Note names for x-axis
    note_names <- c("C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B")
    
    # Combine the data into a matrix
    plot_data <- rbind(avg_dist, curr_dist, user_dist)
    
    # Create the plot
    barplot(
      height = plot_data,
      beside = TRUE,
      col = c("grey", "#F56C37", "lightblue"),
      names.arg = note_names,
      legend.text = c("Average", "Current Song", "Your Preference"),
      main = "Note Distribution",
      xlab = "Notes",
      ylab = "Frequency"
    )
  })

  # Initialize pitch sliders with average values when a song is selected
  observe({
    avg_dist <- average_pitch()
    if (!is.null(avg_dist)) {
      # Update each slider with the corresponding average value
      for (i in 0:11) {
        updateSliderInput(session,
          inputId = paste0("pitch_", i),
          value = avg_dist[i + 1]  # Add 1 because R is 1-indexed
        )
      }
    }
  })

  # Handle find similar songs based on pitch distribution
  observeEvent(input$findSimilarPitch, {
    # Get user preferences and ensure they're numeric
    user_pitch <- as.numeric(c(
      input$pitch_0, input$pitch_1, input$pitch_2,
      input$pitch_3, input$pitch_4, input$pitch_5,
      input$pitch_6, input$pitch_7, input$pitch_8,
      input$pitch_9, input$pitch_10, input$pitch_11
    ))
    
    # Normalize if sum is greater than 0
    if (sum(user_pitch) > 0) {
      user_pitch <- user_pitch / sum(user_pitch)
    }
    
    # Get average features
    avg_features <- average_features_data()
    if (is.null(avg_features)) {
      showNotification("No feature data available", type = "error")
      return()
    }
    
    # Create a copy of the feature vector and ensure it's numeric
    feature_vector <- avg_features$feature_vector
    if (!is.numeric(feature_vector)) {
      feature_vector <- as.numeric(unlist(strsplit(gsub("\\[|\\]", "", feature_vector), ",")))
    }
    
    # Update pitch class histogram portion (positions 0-11 in the feature vector)
    feature_vector[1:12] <- user_pitch
    
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
      input_vector = jsonlite::toJSON(feature_vector, auto_unbox = TRUE),
      top_n = 5
    )
    
    # Make the API request
    tryCatch({
      response <- httr::POST(
        url = url,
        httr::add_headers(.headers = headers),
        body = jsonlite::toJSON(body, auto_unbox = TRUE),
        encode = "json"
      )
      
      if (httr::status_code(response) == 200) {
        # Parse the response
        results <- httr::content(response, "parsed")
        
        if (length(results) > 0) {
          # Get the complete song data
          similar_songs_data <- find_similar_songs(sapply(results, function(x) x$title), top_n = length(results))
          
          if (!is.null(similar_songs_data) && nrow(similar_songs_data) > 0) {
            recommended_songs(similar_songs_data)
            # Switch to overview tab to show results
            nerd_mode_tab("overview")
            showNotification("Found songs with similar note patterns!", type = "message")
          } else {
            showNotification("Error getting complete song data", type = "error")
          }
        } else {
          showNotification("No similar songs found", type = "warning")
        }
      } else {
        showNotification("Error fetching similar songs", type = "error")
      }
    }, error = function(e) {
      showNotification(paste("Error finding similar songs:", e$message), type = "error")
    })
  })

  # Calculate average interval distribution
  average_intervals <- reactive({
    # Get the average features from selected songs
    avg_features <- average_features_data()
    if (is.null(avg_features)) return(NULL)
    
    # Extract interval histogram and ensure it's numeric
    hist <- avg_features$interval_histogram
    if (!is.numeric(hist)) {
      # Convert from JSON if needed
      hist <- as.numeric(unlist(strsplit(gsub("\\[|\\]", "", hist), ",")))
    }
    # Normalize
    if (sum(hist) > 0) hist <- hist / sum(hist)
    hist
  })

  # Get current song's interval distribution
  current_intervals <- reactive({
    # Get features for the selected song
    features <- selected_song_features()
    if (is.null(features)) return(NULL)
    
    # Extract interval histogram and ensure it's numeric
    hist <- features$interval_histogram
    if (!is.numeric(hist)) {
      # Convert from JSON if needed
      hist <- as.numeric(unlist(strsplit(gsub("\\[|\\]", "", hist), ",")))
    }
    # Normalize
    if (sum(hist) > 0) hist <- hist / sum(hist)
    hist
  })

  # Create the interval histogram plot
  output$intervalHistogram <- renderPlot({
    avg_dist <- average_intervals()
    curr_dist <- current_intervals()
    
    if (is.null(avg_dist) || is.null(curr_dist)) {
      # If no data available, show empty plot with message
      plot.new()
      text(0.5, 0.5, "Select a song to view interval distribution", cex = 1.2)
      return()
    }
    
    # Get user preferences from sliders and ensure they're numeric
    user_dist <- as.numeric(c(
      input$interval_0, input$interval_1, input$interval_2,
      input$interval_3, input$interval_4, input$interval_5,
      input$interval_6, input$interval_7, input$interval_8,
      input$interval_9, input$interval_10, input$interval_11
    ))
    
    # Normalize user distribution if sum is greater than 0
    if (sum(user_dist) > 0) {
      user_dist <- user_dist / sum(user_dist)
    }
    
    # Combine the data into a matrix
    plot_data <- rbind(avg_dist, curr_dist, user_dist)
    
    # Create the plot
    barplot(
      height = plot_data,
      beside = TRUE,
      col = c("grey", "#F56C37", "lightblue"),
      names.arg = 0:11,
      legend.text = c("Average", "Current Song", "Your Preference"),
      main = "Interval Distribution",
      xlab = "Interval (semitones)",
      ylab = "Frequency"
    )
  })

  # Initialize interval sliders with average values when a song is selected
  observe({
    avg_dist <- average_intervals()
    if (!is.null(avg_dist)) {
      # Update each slider with the corresponding average value
      for (i in 0:11) {
        updateSliderInput(session,
          inputId = paste0("interval_", i),
          value = avg_dist[i + 1]  # Add 1 because R is 1-indexed
        )
      }
    }
  })

  # Handle find similar songs based on intervals
  observeEvent(input$findSimilarIntervals, {
    # Get user preferences and ensure they're numeric
    user_intervals <- as.numeric(c(
      input$interval_0, input$interval_1, input$interval_2,
      input$interval_3, input$interval_4, input$interval_5,
      input$interval_6, input$interval_7, input$interval_8,
      input$interval_9, input$interval_10, input$interval_11
    ))
    
    # Normalize if sum is greater than 0
    if (sum(user_intervals) > 0) {
      user_intervals <- user_intervals / sum(user_intervals)
    }
    
    # Get average features
    avg_features <- average_features_data()
    if (is.null(avg_features)) {
      showNotification("No feature data available", type = "error")
      return()
    }
    
    # Create a copy of the feature vector and ensure it's numeric
    feature_vector <- avg_features$feature_vector
    if (!is.numeric(feature_vector)) {
      feature_vector <- as.numeric(unlist(strsplit(gsub("\\[|\\]", "", feature_vector), ",")))
    }
    
    # Update interval histogram portion (positions 12-23 in the feature vector)
    feature_vector[12:23] <- user_intervals
    
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
      input_vector = jsonlite::toJSON(feature_vector, auto_unbox = TRUE),
      top_n = 5
    )
    
    # Make the API request
    tryCatch({
      response <- httr::POST(
        url = url,
        httr::add_headers(.headers = headers),
        body = jsonlite::toJSON(body, auto_unbox = TRUE),
        encode = "json"
      )
      
      if (httr::status_code(response) == 200) {
        # Parse the response
        results <- httr::content(response, "parsed")
        
        if (length(results) > 0) {
          # Get the complete song data
          similar_songs_data <- find_similar_songs(sapply(results, function(x) x$title), top_n = length(results))
          
          if (!is.null(similar_songs_data) && nrow(similar_songs_data) > 0) {
            recommended_songs(similar_songs_data)
            # Switch to overview tab to show results
            nerd_mode_tab("overview")
            showNotification("Found songs with similar interval patterns!", type = "message")
          } else {
            showNotification("Error getting complete song data", type = "error")
          }
        } else {
          showNotification("No similar songs found", type = "warning")
        }
      } else {
        showNotification("Error fetching similar songs", type = "error")
      }
    }, error = function(e) {
      showNotification(paste("Error finding similar songs:", e$message), type = "error")
    })
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

  # Add observer for nerd mode toggle if not already present
  observeEvent(input$nerdMode, {
    nerd_mode(input$nerdMode)
  })
}
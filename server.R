# server.R
source("global.R")

server <- function(input, output, session) {
  
  # Navigation handlers
  observeEvent(input$analyzeBtn, {
    updateTabsetPanel(session, "mainNav", selected = "Your MDNA")
  })
  
  observeEvent(input$spotifyBtn, {
    updateTabsetPanel(session, "mainNav", selected = "Your MDNA")
  })
  
  # Best matches list with clickable songs
  output$matchesList <- renderUI({
    tags$div(
      class = "matches-container",
      lapply(1:nrow(dummy_songs), function(i) {
        actionLink(
          paste0("song_", i),
          paste(dummy_songs$name[i], "-", dummy_songs$artist[i], 
                sprintf("(Match: %d%%)", dummy_songs$matches[i])),
          style = "display: block; margin: 10px 0; padding: 10px; 
                  background-color: #f8f9fa; border-radius: 5px;"
        )
      })
    )
  })
  
  # Energy plot
  output$energyPlot <- renderPlotly({
    plot_ly(dummy_energy_data, x = ~time, y = ~energy, type = "scatter", mode = "lines+markers") %>%
      layout(
        title = "Music Energy Over Time",
        xaxis = list(title = "Time"),
        yaxis = list(title = "Energy Level")
      )
  })
  
  # Chord progression display
  output$chordProgression <- renderText({
    "Current Progression: Am → F → C → G"
  })
  
  # Modal dialog for song details
  lapply(1:nrow(dummy_songs), function(i) {
    observeEvent(input[[paste0("song_", i)]], {
      showModal(modalDialog(
        title = dummy_songs$name[i],
        div(
          h4(paste("Artist:", dummy_songs$artist[i])),
          h4(paste("Energy Score:", dummy_songs$energy[i])),
          h4("Chord Progression:"),
          p(dummy_songs$chord_progression[i]),
          br(),
          plotlyOutput(paste0("songEnergy_", i))
        ),
        footer = modalButton("Close")
      ))
      
      # Individual song energy plot in modal
      output[[paste0("songEnergy_", i)]] <- renderPlotly({
        plot_ly(y = rnorm(50, mean = dummy_songs$energy[i], sd = 0.1), 
                type = "box") %>%
          layout(title = "Song Energy Distribution")
      })
    })
  })
}
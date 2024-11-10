# ui.R
source("global.R")

ui <- navbarPage(
  "HARMONLY",
  id = "mainNav",
  position = "static-top",
  
  # Convert navbarPage to a side navigation layout
  header = tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
  ),
  
  # Welcome Page
  tabPanel("Welcome",
    div(class = "content-wrapper",
      div(class = "container-fluid",
        div(class = "welcome-box text-center",
          h1(class = "main-title", "Find Your Music DNA"),
          p(class = "subtitle", "Discover music that matches your unique style"),
          br(),
          div(class = "input-container",
            textAreaInput("songInput", "Enter song names (one per line):", 
                         rows = 5, width = "500px"),
            br(),
            div(class = "button-container",
              actionButton("analyzeBtn", "Analyze Songs", 
                          class = "option-button"),
              br(),
              br(),
              actionButton("spotifyBtn", "Connect Spotify", 
                          class = "option-button")
            )
          )
        )
      )
    )
  ),
  
  # MDNA Page
  tabPanel("Your MDNA",
    fluidRow(
      # Score Display
      column(4,
        div(class = "score-box text-center",
          h3("Your Music Score"),
          h2("85%"),
          p("Based on energy and rhythm analysis")
        )
      ),
      # Best Matches
      column(8,
        h3("Best Matches", class = "text-center"),
        uiOutput("matchesList")
      )
    ),
    
    # Energy Plot
    fluidRow(
      column(12,
        div(class = "plot-container",
          plotlyOutput("energyPlot", height = "300px")
        )
      )
    ),
    
    # Chord Progression
    fluidRow(
      column(12,
        div(class = "chord-box text-center",
          h3("Chord Progression"),
          verbatimTextOutput("chordProgression")
        )
      )
    )
  ),
  
  # Modal for song details
  uiOutput("songModal")
)
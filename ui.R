source("global.R")

ui <- navbarPage(
  title = "HARMONLY",
  id = "mainNav",
  position = "static-top",

  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
  ),
  
  # Welcome Page Tab
  tabPanel("Welcome",
    div(class = "content-wrapper",
      div(class = "container-fluid",
        div(class = "welcome-box text-center",
          h1(class = "main-title", "Find Your Music DNA"),
          p(class = "subtitle", "Discover music that matches your unique style"),
          br(),
          div(class = "input-container",
            textAreaInput("songInput", "Enter song names (one per line):",
              rows = 5, width = "500px"
            ),
            br(),
            div(class = "button-container",
              actionButton("analyzeBtn", "Analyze Songs",
                class = "option-button"
              ),
              br(),
              br(),
              actionButton("spotifyBtn", "Connect Spotify",
                class = "option-button"
              )
            )
          )
        )
      )
    )
  ),
  
  # MDNA Page Tab
  tabPanel("Your MDNA",
    div(class = "content-wrapper",
      # Score Bar
      fluidRow(
        column(12,
          div(class = "score-bar text-center",
            span(class = "score-label", "Score: "),
            span(class = "score-value", "85%"),
            span(class = "score-description", "This score indicates how common the music you listen is through analysis of popularity. Your music taste sits in the 85th percentile for uniqueness")
          )
        )
      ),
      # Main Content
      fluidRow(
        # Energy Plot
        column(8,
          div(class = "plot-container",
            plotlyOutput("energyPlot", height = "400px")
          )
        ),
        # Best Matches
        column(4,
          div(class = "matches-container",
            h3("Best Matches", class = "text-center"),
            uiOutput("matchesList")
          )
        )
      ),
      # Chord Progression
      fluidRow(
        column(12,
          div(class = "chord-box text-center",
            h3("Your Chord Progression ID"),
            verbatimTextOutput("chordProgression")
          )
        )
      )
    )
  )
)
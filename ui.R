# ui.R
source("global.R")

ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      .welcome-box { text-align: center; padding: 20px; margin: 20px; }
      .option-button { margin: 10px; padding: 15px 30px; width: 250px; }
      .score-box { 
        text-align: center; 
        padding: 20px;
        background-color: #f8f9fa;
        border-radius: 10px;
        margin-bottom: 20px;
      }
      .chord-box {
        padding: 15px;
        background-color: #f8f9fa;
        border-radius: 5px;
        margin-top: 20px;
      }
    "))
  ),
  
  navbarPage(
    "Music DNA",
    id = "mainNav",
    
    # Welcome Page
    tabPanel("Welcome",
      div(class = "welcome-box",
        h2("Find Your Music DNA"),
        br(),
        textAreaInput("songInput", "Enter song names (one per line):", rows = 5),
        actionButton("analyzeBtn", "Analyze Songs", class = "option-button"),
        br(),
        actionButton("spotifyBtn", "Connect Spotify", class = "option-button")
      )
    ),
    
    # MDNA Page
    tabPanel("Your MDNA",
      fluidRow(
        # Score Display
        column(4,
          div(class = "score-box",
            h3("Your Music Score"),
            h2("85%"),
            p("Based on energy and rhythm analysis")
          )
        ),
        # Best Matches
        column(8,
          h3("Best Matches"),
          uiOutput("matchesList")
        )
      ),
      
      # Energy Plot
      fluidRow(
        column(12,
          plotlyOutput("energyPlot", height = "300px")
        )
      ),
      
      # Chord Progression
      fluidRow(
        column(12,
          div(class = "chord-box",
            h3("Chord Progression"),
            verbatimTextOutput("chordProgression")
          )
        )
      )
    )
  ),
  
  # Modal for song details
  uiOutput("songModal")
)
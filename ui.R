library(shiny)
library(methods)

# Custom CSS for color scheme
customCSS <- HTML("
  .skin-blue .main-header .logo {
    background-color: #2C3E50;
  }
  .skin-blue .main-header .logo:hover {
    background-color: #2C3E50;
  }
  .skin-blue .main-header .navbar {
    background-color: #2C3E50;
  }
  .skin-blue .main-sidebar {
    background-color: #2C3E50;
  }
  .skin-blue .main-sidebar .sidebar .sidebar-menu .active a {
    background-color: #455668;
  }
  .song-list {
    margin-top: 20px;
    min-height: 100px;
    border: 1px solid #ddd;
    border-radius: 4px;
    padding: 10px;
  }
  .song-item {
    background: #f8f9fa;
    padding: 8px 12px;
    margin: 5px 0;
    border-radius: 4px;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  .remove-song {
    color: #dc3545;
    cursor: pointer;
  }
  .selectize-dropdown-content {
    max-height: 200px;
    overflow-y: auto;
  }
")

ui <- navbarPage(
  title = "HARMONLY",
  id = "mainNav",
  theme = "custom.css",
  
  # Remove custom JavaScript handlers since they're no longer needed
  tags$head(
    tags$style(customCSS)
  ),
  
  # Welcome Page
  tabPanel(
    title = "Welcome",
    div(class = "content-wrapper",
      div(class = "welcome-box",
        h1(class = "main-title", "Welcome to Harmonly!"),
        p(class = "subtitle", "Tell us about the songs you like, and we'll help you discover more music you'll love."),
        
        div(class = "input-container",
          # Search input field
          textInput("searchInput", "Enter song name:", placeholder = "Type a song name..."),
          
          # Search button
          actionButton("searchBtn", "Search", class = "search-button"),
          
          # Search results output
          uiOutput("searchResults"),
          
          # Selected songs list
          div(class = "matches-container",
            h3("Selected Songs"),
            uiOutput("selectedSongs")
          ),
          
          # Analysis button
          div(class = "button-container",
            actionButton("analyzeBtn", "Analyze My Music Taste", 
                        class = "option-button")
          )
        )
      )
    )
  ),
  
  # MDNA Page
  tabPanel(
    title = "Your MDNA",
    div(class = "content-wrapper",
      uiOutput("recommendedSongs")
    )
  )
)
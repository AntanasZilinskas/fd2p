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
  /* Add menu icon styling */
  .menu-icon {
    width: 24px;
    height: 24px;
    vertical-align: left;
    margin-right: 8px;
  }

  /* Adjust the menu tab to align items properly */
  .menu-tab {
    display: flex;
    align-items: left;
  }

  /* Ensure the tab links use flex alignment */
  .navbar-nav > li > a {
    display: flex;
    align-items: left;
    justify-content: left;
  }
")

ui <- navbarPage(
  id = "mainNav",
  inverse = TRUE,

  # Include the Google Fonts link and custom CSS
  header = tags$head(
    # Link to the Poppins font
    tags$link(
      href = "https://fonts.googleapis.com/css2?family=Poppins:wght@400&display=swap",
      rel = "stylesheet"
    ),
    # Link to your custom CSS
    tags$link(
      href = "custom.css",
      rel = "stylesheet"
    ),
    # Add JavaScript to handle showing/hiding the spinner
    tags$script(HTML("
      Shiny.addCustomMessageHandler('show_spinner', function(show) {
        var spinner = document.getElementById('search-spinner');
        if (show) {
          spinner.style.display = 'block';
        } else {
          spinner.style.display = 'none';
        }
      });
    "))
  ),

  # Logo and Title Container
  title = div(
    class = "logo-title-container",
    img(src = "assets/logo.svg", class = "logo", alt = "Logo"),
    span("HARMONLY", class = "title-text")
  ),

  # Welcome Page
  tabPanel(
    title = tags$div(
      class = "menu-tab",
      tags$img(src = "assets/search.svg", class = "menu-icon"),
      span("Search songs")
    ),
    div(
      class = "content-wrapper",
      div(
        class = "welcome-box",
        h1(class = "main-title", "Find out about your Music DNA!"),
        p(
          class = "subtitle",
          "Tell us about the songs you like, and we'll help you discover more music you'll love."
        ),
        # Adjusted search container
        div(
          class = "search-container",
          div(
            class = "search-input-wrapper",
            div(
              class = "input-with-spinner",
              tags$input(
                id = "searchInput",
                type = "text",
                placeholder = "Type a song name...",
                class = "search-input"
              ),
              # Placeholder for the loading animation
              tags$div(id = "search-spinner", class = "search-spinner", style = "display: none;")
            )
          ),
          # Analyze button
          actionButton("analyzeBtn", "Analyze", class = "analyze-button")
        ),
        # Search results output
        uiOutput("searchResults"),
        # Selected songs list
        div(
          class = "matches-container",
          h3("Selected Songs"),
          uiOutput("selectedSongs")
        )
      )
    )
  ),

  # MDNA Page
  tabPanel(
    title = tags$div(
      class = "menu-tab",
      tags$img(src = "assets/pulse.svg", class = "menu-icon"),
      span("Analyze MDNA")
    ),
    div(
      class = "content-wrapper",
      uiOutput("recommendedSongs")
    )
  )
)
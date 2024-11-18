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
  
  # Include JavaScript code to handle custom messages
  tags$head(
    tags$script(HTML("
      Shiny.addCustomMessageHandler('updateSelectizeOptions', function(message) {
        var inputId = message.inputId;
        var options = message.options;
        var selectize = $('#' + inputId).selectize()[0].selectize;

        // Clear existing options
        selectize.clearOptions();

        // Add new options
        selectize.addOption(options);

        // Refresh options list
        selectize.refreshOptions(false);

        // Open the dropdown if there are options
        if (options.length > 0) {
          selectize.open();
        } else {
          selectize.close();
        }
      });

      Shiny.addCustomMessageHandler('clearSelectizeInput', function(message) {
        var inputId = message.inputId;
        var selectize = $('#' + inputId).selectize()[0].selectize;

        // Clear the selected value
        selectize.clear();

        // Close the dropdown
        selectize.close();
      });
    "))
  ),
  
  # Welcome Page
  tabPanel(
    title = "Welcome",
    div(class = "content-wrapper",
      div(class = "welcome-box",
        h1(class = "main-title", "Welcome to Harmonly!"),
        p(class = "subtitle", "Tell us about the songs you like, and we'll help you discover more music you'll love."),
        
        div(class = "input-container",
          # Song search input
          selectizeInput(
            "songInput", 
            "Search and add songs you like:",
            choices = NULL,
            multiple = FALSE,
            options = list(
              placeholder = 'Start typing a song name...',
              maxItems = 1,
              valueField = 'title',
              labelField = 'title',
              searchField = 'title',
              create = FALSE,
              render = I("
                {
                  option: function(item, escape) {
                    return '<div>' + escape(item.title) + '</div>';
                  }
                }
              "),
              onType = I("
                function(query) {
                  if (query.length >= 2) {
                    Shiny.setInputValue('searchTerm', query, {priority: 'event'});
                  } else {
                    Shiny.setInputValue('searchTerm', null);
                  }
                }
              ")
            )
          ),
          
          # Selected songs list
          div(class = "matches-container",
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
      # Existing MDNA content here
      # Leaving this empty for now, focusing on the search functionality
    )
  )
)
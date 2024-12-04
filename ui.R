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

  /* Center the title and subtitle on the Analyze MDNA page */
  .mdna-page .main-title,
  .mdna-page .subtitle {
    text-align: center;
  }

  /* MDNA Container */
  .mdna-container {
    position: relative;
    width: 654px;
    height: 440px;
    margin: 0 auto;
    border-radius: 10px;
    background: #FFF;
    box-shadow: 0px 4px 12px 0px rgba(13, 10, 44, 0.06);
    overflow: hidden;
  }

  /* Center Icon and Label */
  .center-icon {
    position: absolute;
    left: 50%;
    top: 50%;
    transform: translate(-50%, -50%);
    text-align: center;
  }

  .center-icon .mdna-label {
    display: block;
    margin-bottom: 10px;
    font-size: 16px;
    color: #333;
  }

  .center-icon .your-mdna-icon {
    width: 57px;
    height: 57px;
  }

  /* Suggested Song Icons */
  .suggested-song {
    position: absolute;
    transform: translate(-50%, -50%);
  }

  .suggested-song-icon {
    width: 25px;
    height: 25px;
    cursor: pointer;
  }

  /* Tooltip Styling */
  .suggested-song[title]:hover::after {
    content: attr(title);
    position: absolute;
    top: -60px;
    left: 50%;
    transform: translateX(-50%);
    white-space: pre-line;
    background-color: rgba(0, 0, 0, 0.8);
    color: #FFF;
    padding: 8px 12px;
    border-radius: 5px;
    z-index: 999;
    width: max-content;
    max-width: 200px;
    text-align: left;
  }

  .suggested-song[title]:hover::before {
    content: '';
    position: absolute;
    top: -10px;
    left: 50%;
    transform: translateX(-50%);
    border-width: 5px;
    border-style: solid;
    border-color: transparent transparent rgba(0, 0, 0, 0.8) transparent;
    z-index: 999;
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
    # Link to custom CSS
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
    ")),
    # Add JavaScript to dismiss search results when clicking outside
    tags$script(HTML("
      $(document).on('click', function(event) {
        var $target = $(event.target);
        if (!$target.closest('.search-container').length && !$target.closest('.search-results-dropdown').length) {
          Shiny.setInputValue('hide_search_results', Math.random());
        }
      });
    ")),
    # Add JavaScript for handling clicks on search result items
    tags$script(HTML("
      $(document).on('click', function(event) {
        var $target = $(event.target);
        if (!$target.closest('.search-container').length && !$target.closest('.search-results-dropdown').length) {
          Shiny.setInputValue('hide_search_results', Math.random());
        }
      });

      Shiny.addCustomMessageHandler('setupSearchResultClick', function(message) {
        $(document).off('click', '.search-result-item').on('click', '.search-result-item', function() {
          var songTitle = $(this).attr('data-value');
          Shiny.setInputValue('searchResultClicked', songTitle, {priority: 'event'});
        });
      });
    ")),
    # JavaScript to handle clicks on remove buttons
    tags$script(HTML("
      $(document).on('click', '.remove-song', function() {
        var songTitle = $(this).attr('data-song-title');
        Shiny.setInputValue('remove_song', songTitle, {priority: 'event'});
      });
    ")),
    # JavaScript to handle Analyze button processing state and redirection
    tags$script(HTML("
      Shiny.addCustomMessageHandler('analyzeButtonProcessing', function(message) {
        var btn = document.getElementById('analyzeBtn');
        if(message.status === 'start') {
          btn.classList.add('processing');
          btn.disabled = true;
          btn.innerHTML = 'Analyze <div class=\"spinner\"></div>';
        } else if(message.status === 'end') {
          btn.classList.remove('processing');
          btn.disabled = false;
          btn.innerHTML = 'Analyze';
          // Redirect to 'Analyze MDNA' page
          $('a[data-value=\"Analyze MDNA\"]').tab('show');
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
    value = "Search songs",
    div(
      class = "content-wrapper",
      div(
        class = "welcome-box",
        h1(class = "main-title", "Find out about your Music DNA!"),
        p(
          class = "subtitle",
          "Tell us about the songs you like, and we'll help you discover more music you'll love."
        ),
        # Unified container for search and selected songs
        div(
          class = "input-container",
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
                  class = "search-input",
                  autocomplete = "off"
                ),
                tags$div(id = "search-spinner", class = "search-spinner", style = "display: none;")
              ),
              uiOutput("searchResults")
            )
          ),
          div(
            class = "matches-container",
            uiOutput("selectedSongs")
          )
        ),
        # Analyze button centered below selected songs
        div(
          class = "analyze-button-container",
          actionButton("analyzeBtn", "Analyze", class = "analyze-button")
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
    value = "Analyze MDNA",
    div(
      class = "content-wrapper",
      div(
        class = "welcome-box mdna-page",
        h1(class = "main-title", "Your Music DNA!"),
        p(
          class = "subtitle",
          "Here are the songs that are most similar to your current taste."
        ),
        # Placeholder for the MDNA visualization or message
        uiOutput("mdnaContent")
      )
    )
  )
)
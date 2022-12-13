# Load the shiny library
library(shiny)
library(tidyverse)
library(lubridate)
# Load the sales data from a csv file
KDAc <- read.csv("./data/sour/KDAc.csv")

# Define the shiny UI
ui <- fluidPage(

  # Add a title
  titlePanel("Car Sales Dashboard"),

  # Add a sidebar
  sidebarLayout(
    sidebarPanel(
      
      # Add a dropdown menu for selecting a car model
      selectInput(
        inputId = "model",
        label = "Select a car model:",
        choices = unique(KDAc$model),
        selected = unique(KDAc$model)[1]
      )
    ),

    # Add a main panel for displaying the sales data
    mainPanel(
      # Add a title for the sales data
      h2(textOutput("title")),

      # Add a table for displaying the sales data
      tableOutput("sales_table")
    )
  )
)

# Define the shiny server
server <- function(input, output) {

  # Calculate the total number of sales for the selected model
  sales_by_model <- reactive({
    subset(KDAc, model == input$model)
  })

  # Update the title with the selected car model
  output$title <- renderText({
    paste("Sales for model", input$model)
  })

  # Update the table with the sales data for the selected model
  output$sales_table <- renderTable({
    sales_by_model()
  })

}

# Run the shiny app
shinyApp(ui = ui, server = server)

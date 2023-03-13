library(shiny)
library(shinydashboard)

# subitems, could be dynamic from user input or database
data_subitems <- c("one", "two", "three")

ui <- dashboardPage(
  dashboardHeader(),
  dashboardSidebar(
    uiOutput("mysidebar")
  ),
  dashboardBody(
    uiOutput("mycontent")
  )
  
)

server <- function(input, output, session) {
  
  # This is to get the desired menuItem selected initially. 
  # selected=T seems not to work with a dynamic sidebarMenu.
  observeEvent(session, {
    updateTabItems(session, "tabs", selected = "initial")
  })
  
  # Use reactive values when working with Shiny.
  subitems <- reactiveVal(value = data_subitems)
  
  # dynamic sidebar menu #
  output$mysidebar <- renderUI({
    sidebarMenu(id = "tabs",
                menuItem("Start", tabName = "initial", icon = icon("star"), selected = T),
                menuItem("Subs", id = "subs", tabName = "subs",  icon = icon("dashboard"), 
                         startExpanded = T,
                         lapply(subitems(), function(x) {
                           menuSubItem(x, tabName = paste0("sub_", x)) } )),
                menuItem("Setup", tabName = "setup")
    )
  })
  
  # dynamic content #
  output$mycontent <- renderUI({
    
    itemsSubs <- lapply(subitems(), function(x){
      tabItem(tabName = paste0("sub_", x), uiOutput(paste0("sub_", x)))
    })
    
    items <- c(
      list(
        tabItem(tabName = "initial",
                "Welcome on the initial page!"
        )
      ),
      
      itemsSubs,
      
      list(
        tabItem(tabName = "setup",
                
                textInput("add_subitem", "Add subitem"),
                actionButton("add", "add!"),
                
                selectInput("rm_subitem", "Remove subitem", choices = subitems()),
                actionButton("rm", "remove!")
        )
      )
    )
    
    do.call(tabItems, items)
  })
  
  # dynamic content in the dynamic subitems #
  observe({ 
    lapply(subitems(), function(x){
      output[[paste0("sub_", x)]] <- renderUI ({
        list(fluidRow(
          box("hello ", x)
        )
        )
      })
    })
  })
  
  # add and remove tabs
  observeEvent(input$add, {
    req(input$add_subitem)
    
    s <- c(subitems(), input$add_subitem)
    subitems(s)
    
    updateTabItems(session, "tabs", selected = "setup")
  })
  
  observeEvent(input$rm, {
    req(input$rm_subitem)
    
    s <- subitems()[-which(subitems() == input$rm_subitem)]
    subitems(s)
    
    updateTabItems(session, "tabs", selected = "setup")
  })
  
}

shinyApp(ui, server)
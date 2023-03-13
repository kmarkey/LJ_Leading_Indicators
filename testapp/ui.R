#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinydashboard)

# 
# navbarPage("LJ Project",
#            
#            tabPanel("Page 1",
#                     sidebarLayout(
#                       sidebarPanel(
#                         radioButtons("plotType", "Plot type",
#                                      c("Scatter"="p", "Line"="l")
#                         )
#                       ),
#                       mainPanel(
#                         plotOutput("plot")
#                       )
#                     )
#            ),
#            tabPanel("Page 2",
#                     verbatimTextOutput("summary")
#            ),
#            navbarMenu("More",
#                       tabPanel("Table",
#                                DT::dataTableOutput("table")
#                       ),
#                       tabPanel("About",
#                                fluidRow(
#                                  column(3,
#                                         img(class="img-polaroid",
#                                             src=paste0("http://upload.wikimedia.org/",
#                                                        "wikipedia/commons/9/92/",
#                                                        "1919_Ford_Model_T_Highboy_Coupe.jpg")),
#                                         tags$small(
#                                           "Source: Photographed at the Bay State Antique ",
#                                           "Automobile Club's July 10, 2005 show at the ",
#                                           "Endicott Estate in Dedham, MA by ",
#                                           a(href="http://commons.wikimedia.org/wiki/User:Sfoskett",
#                                             "User:Sfoskett")
#                                         )
#                                  )
#                                )
#                       )
#            )
# )
# 
# # Define UI for application that draws a histogram
# shinyUI(fluidPage(
# 
#     # Application title
#     titlePanel("Old Faithful Geyser Data"),
# 
#     # Sidebar with a slider input for number of bins
#     sidebarLayout(
#         sidebarPanel(
#             sliderInput("bins",
#                         "Number of bins:",
#                         min = 1,
#                         max = 50,
#                         value = 30)
#         ),
# 
#         # Show a plot of the generated distribution
#         mainPanel(
#             plotOutput("distPlot")
#         )
#     )
# ))

## ui.R ##

header <- dashboardHeader(title = "LJ Leading Indicators",
                          dropdownMenu(type = "messages",
                               messageItem(
                                 from = "Version",
                                 message = "Product is up to date.",
                                 icon = icon("check"),
                                 time = "2022-10-01",
                               ),
                               messageItem(
                                 from = "Support",
                                 message = "Submit a maintenance query.",
                                 icon = icon("exclamation-circle"))
                               )
                          )


sidebar <- dashboardSidebar(
  sidebarMenu(
    
    menuItem("Business", tabName = "business", icon = icon("building"),
             startExpanded = T,
             menuSubItem("Last 6 Months", 
                         tabName = "last-6-months",
                         icon = icon("clock")),
             menuSubItem("Biggest Movers", 
                         tabName = "biggest-movers",
                         icon = icon("car")),
             menuSubItem("Ranking",
                         tabName = "ranking",
                         icon = icon("ranking-star"))),
    
    menuItem("Personnel", tabName = "personnel",  icon = icon("user-friends"),
             menuSubItem("Top Salesman", 
                         tabName = "top-salesman",
                         icon = icon("user-tie")),
             menuSubItem("Top Finance Manager", 
                         tabName = "top-fi-manager",
                         icon = icon("piggy-bank"))),
    menuItem("Prediction", tabName = "prediction", icon = icon("cubes-stacked"),
             badgeLabel = "dev", badgeColor = "orange")
  )
)

body <- dashboardBody(
  tabItems(
    tabItem(tabName = "business",
            h2("Dashboard tab content"), 
            title = "Hello"
    ),

    tabItem(tabName = "personnel",
            h2("Personnel tab content")
    )
  )
)

# maintenance <- 

# Put them together into a dashboardPage
shinyUI(dashboardPage(
  header,
  sidebar,
  body
))

